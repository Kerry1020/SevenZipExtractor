import Foundation

struct ProcessOutput {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

protocol ProcessRunning {
    func run(_ command: ProcessCommand) async throws -> ProcessOutput
}

struct ProcessRunner: ProcessRunning {
    func run(_ command: ProcessCommand) async throws -> ProcessOutput {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = command.executableURL
        process.arguments = command.arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        return ProcessOutput(
            stdout: String(decoding: stdoutData, as: UTF8.self),
            stderr: String(decoding: stderrData, as: UTF8.self),
            exitCode: process.terminationStatus
        )
    }
}

struct StubProcessRunner: ProcessRunning {
    let stdout: String
    let stderr: String
    let exitCode: Int32

    func run(_ command: ProcessCommand) async throws -> ProcessOutput {
        ProcessOutput(stdout: stdout, stderr: stderr, exitCode: exitCode)
    }
}

final class SevenZipBackend: SevenZipBackendProtocol {
    private let builder: SevenZipCommandBuilder
    private let runner: ProcessRunning
    private let parser = SevenZipOutputParser()

    init(toolURL: URL, runner: ProcessRunning) {
        self.builder = SevenZipCommandBuilder(toolURL: toolURL)
        self.runner = runner
    }

    func probeArchive(at archiveURL: URL, password: String?) async throws -> ArchiveProbe {
        let output = try await runner.run(
            builder.probeCommand(archiveURL: archiveURL, password: password)
        )
        return parser.parseProbeOutput(output.stdout + output.stderr, archiveURL: archiveURL)
    }

    func extractArchive(
        at archiveURL: URL,
        to destinationURL: URL,
        password: String?,
        conflictPolicy: ConflictPolicy
    ) async throws -> ExtractionResult {
        let output = try await runner.run(
            builder.extractCommand(
                archiveURL: archiveURL,
                destinationURL: destinationURL,
                password: password,
                conflictPolicy: conflictPolicy
            )
        )

        if output.exitCode == 0 {
            return .success(ExtractionSuccess(destinationURL: destinationURL))
        }

        return .failure(parser.parseExtractFailure(output.stdout + output.stderr))
    }
}
