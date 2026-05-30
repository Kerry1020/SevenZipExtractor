import Foundation
import AppKit
import SwiftUI

// MARK: - Process

struct ProcessCommand: Equatable {
    let executableURL: URL
    let arguments: [String]
}

struct ProcessOutput {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

/// Progress update emitted during extraction
struct ExtractionProgress {
    let percent: Int          // 0–100, or -1 if unknown
    let currentFile: String?  // file being extracted
}

protocol ProcessRunning {
    func run(_ command: ProcessCommand) async throws -> ProcessOutput
    func runWithProgress(
        _ command: ProcessCommand,
        onProgress: @escaping (ExtractionProgress) -> Void
    ) async throws -> ProcessOutput
    func cancel()
}

/// Thread-safe data accumulator
private final class LockedData<T> {
    private var value: T
    private let lock = NSLock()

    init(_ initial: T) {
        self.value = initial
    }

    func append(_ data: Data) where T == Data {
        lock.lock()
        value.append(data)
        lock.unlock()
    }

    func get() -> T {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

/// Manages a single 7zz process with optional progress reporting and cancellation.
final class ProcessRunner: ProcessRunning {
    private var activeProcess: Process?
    private let lock = NSLock()

    func run(_ command: ProcessCommand) async throws -> ProcessOutput {
        try await runWithProgress(command, onProgress: { _ in })
    }

    func runWithProgress(
        _ command: ProcessCommand,
        onProgress: @escaping (ExtractionProgress) -> Void
    ) async throws -> ProcessOutput {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = command.executableURL
        process.arguments = command.arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        lock.lock()
        activeProcess = process
        lock.unlock()

        // Read stderr in background
        let stderrData = LockedData<Data>(Data())
        let stderrReader = DispatchQueue(label: "com.sevenzipextractor.stderr")
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            stderrReader.async {
                let chunk = handle.availableData
                if chunk.isEmpty {
                    handle.readabilityHandler = nil
                } else {
                    stderrData.append(chunk)
                }
            }
        }

        // Read stdout line-by-line for progress
        let stdoutData = LockedData<Data>(Data())
        let stdoutReader = DispatchQueue(label: "com.sevenzipextractor.stdout")
        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            stdoutReader.async {
                let chunk = handle.availableData
                if chunk.isEmpty {
                    handle.readabilityHandler = nil
                } else {
                    stdoutData.append(chunk)

                    let text = String(data: stdoutData.get(), encoding: .utf8) ?? ""
                    let lines = text.components(separatedBy: "\n")

                    for line in lines.suffix(5) {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if let pct = Self.parsePercent(from: trimmed) {
                            onProgress(ExtractionProgress(percent: pct, currentFile: nil))
                        } else if trimmed.hasPrefix("Extracting") {
                            let file = trimmed.dropFirst("Extracting".count).trimmingCharacters(in: .whitespaces)
                            onProgress(ExtractionProgress(percent: -1, currentFile: file))
                        }
                    }
                }
            }
        }

        try process.run()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            process.terminationHandler = { _ in
                continuation.resume(returning: ())
            }
            if !process.isRunning {
                continuation.resume(returning: ())
            }
        }

        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        lock.lock()
        activeProcess = nil
        lock.unlock()

        return ProcessOutput(
            stdout: String(data: stdoutData.get(), encoding: .utf8) ?? "",
            stderr: String(data: stderrData.get(), encoding: .utf8) ?? "",
            exitCode: process.terminationStatus
        )
    }

    func cancel() {
        lock.lock()
        activeProcess?.terminate()
        lock.unlock()
    }

    private static func parsePercent(from line: String) -> Int? {
        guard line.contains("%") else { return nil }
        let digits = line.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }
        guard !digits.isEmpty else { return nil }
        return Int(String(digits))
    }
}

struct StubProcessRunner: ProcessRunning {
    let stdout: String
    let stderr: String
    let exitCode: Int32

    func run(_ command: ProcessCommand) async throws -> ProcessOutput {
        ProcessOutput(stdout: stdout, stderr: stderr, exitCode: exitCode)
    }

    func runWithProgress(
        _ command: ProcessCommand,
        onProgress: @escaping (ExtractionProgress) -> Void
    ) async throws -> ProcessOutput {
        ProcessOutput(stdout: stdout, stderr: stderr, exitCode: exitCode)
    }

    func cancel() {}
}

// MARK: - Progress Window

@MainActor
final class ExtractionProgressWindow: NSObject {
    private var window: NSWindow?
    private(set) var viewModel: ProgressViewModel?

    func show(archiveName: String) -> (onProgress: (ExtractionProgress) -> Void, onCancel: () -> Void) {
        let vm = ProgressViewModel(archiveName: archiveName)
        self.viewModel = vm

        let hosting = NSHostingView(rootView: ExtractionProgressView(viewModel: vm))

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 120),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "Extracting \(archiveName)"
        win.contentView = hosting
        win.center()
        win.isReleasedWhenClosed = false
        win.level = .floating
        win.makeKeyAndOrderFront(nil)

        self.window = win

        let onProgress: (ExtractionProgress) -> Void = { progress in
            Task { @MainActor in
                vm.update(progress)
            }
        }

        let onCancel: () -> Void = {
            vm.cancelled = true
        }

        return (onProgress, onCancel)
    }

    func close() {
        window?.close()
        window = nil
        viewModel = nil
    }
}

@MainActor
final class ProgressViewModel: ObservableObject {
    let archiveName: String
    @Published var percent: Int = 0
    @Published var currentFile: String = ""
    @Published var cancelled: Bool = false

    init(archiveName: String) {
        self.archiveName = archiveName
    }

    func update(_ progress: ExtractionProgress) {
        if progress.percent >= 0 {
            percent = progress.percent
        }
        if let file = progress.currentFile, !file.isEmpty {
            currentFile = file
        }
    }
}

struct ExtractionProgressView: View {
    @ObservedObject var viewModel: ProgressViewModel

    var body: some View {
        VStack(spacing: 12) {
            Text("Extracting \(viewModel.archiveName)")
                .font(.headline)

            ProgressView(value: Double(viewModel.percent), total: 100)
                .progressViewStyle(.linear)

            if !viewModel.currentFile.isEmpty {
                Text(viewModel.currentFile)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Button("Cancel") {
                viewModel.cancelled = true
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(16)
    }
}

// MARK: - Backend Protocol

protocol SevenZipBackendProtocol {
    func probeArchive(at archiveURL: URL, password: String?) async throws -> ArchiveProbe
    func extractArchive(
        at archiveURL: URL,
        to destinationURL: URL,
        password: String?,
        conflictPolicy: ConflictPolicy
    ) async throws -> ExtractionResult
}
