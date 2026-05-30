import AppKit
import Foundation
import UniformTypeIdentifiers

protocol ArchiveOpening {
    func open(url: URL)
}

final class RecordingCoordinator: ArchiveOpening {
    private(set) var openedURLs: [URL] = []

    func open(url: URL) {
        openedURLs.append(url)
    }
}

final class RuntimeArchiveCoordinator: ArchiveOpening {
    private let coordinator: ExtractionHandling
    private let prompts: UserPrompting

    init(coordinator: ExtractionHandling, prompts: UserPrompting) {
        self.coordinator = coordinator
        self.prompts = prompts
    }

    func open(url: URL) {
        Task {
            do {
                let result = try await coordinator.handleOpen(url: url)
                if case .failure(let failure) = result {
                    prompts.showError(failure, details: nil)
                }
            } catch {
                prompts.showError(.unknown(details: error.localizedDescription), details: error.localizedDescription)
            }
        }
    }
}

// MARK: - Drag & Drop Window

final class DropWindow: NSWindow {
    private let archiveCoordinator: ArchiveOpening

    init(archiveCoordinator: ArchiveOpening) {
        self.archiveCoordinator = archiveCoordinator
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 260),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        title = "SevenZipExtractor"
        center()
        isReleasedWhenClosed = false

        let dropView = DropTargetView(archiveCoordinator: archiveCoordinator)
        dropView.translatesAutoresizingMaskIntoConstraints = false
        contentView = dropView
        NSLayoutConstraint.activate([
            dropView.topAnchor.constraint(equalTo: contentView!.topAnchor),
            dropView.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor),
            dropView.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor),
            dropView.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor)
        ])

        registerForDraggedTypes([.fileURL])
    }
}

final class DropTargetView: NSView {
    private let coordinator: ArchiveOpening
    private var isTargeted = false

    init(archiveCoordinator: ArchiveOpening) {
        self.coordinator = archiveCoordinator
        super.init(frame: .zero)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bgColor: NSColor
        if isTargeted {
            bgColor = NSColor.controlAccentColor.withAlphaComponent(0.08)
        } else {
            bgColor = NSColor.windowBackgroundColor
        }

        bgColor.setFill()
        bounds.fill()

        let dashLength: [CGFloat] = [8, 4]
        let borderPath = NSBezierPath(rect: bounds.insetBy(dx: 8, dy: 8))
        borderPath.setLineDash(dashLength, count: 2, phase: 0)
        borderPath.lineWidth = 2
        borderPath.stroke()

        // Draw label
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]

        let text = "Drop archive here to extract"
        let textSize = text.size(withAttributes: attrs)
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attrs)
    }

    // MARK: - NSDraggingDestination

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard hasArchiveFiles(sender) else { return [] }
        isTargeted = true
        needsDisplay = true
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isTargeted = false
        needsDisplay = true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isTargeted = false
        needsDisplay = true

        guard let urls = archiveURLs(from: sender) else { return false }
        for url in urls {
            coordinator.open(url: url)
        }
        return true
    }

    // MARK: - Helpers

    private func hasArchiveFiles(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = archiveURLs(from: sender) else { return false }
        return !urls.isEmpty
    }

    private func archiveURLs(from sender: NSDraggingInfo) -> [URL]? {
        let pasteboard = sender.draggingPasteboard
        guard let items = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true
        ]) as? [URL] else { return nil }

        let supportedExts: Set<String> = ["7z", "zip", "rar", "tar", "gz", "bz2", "xz", "tgz"]
        return items.filter { url in
            let ext = url.pathExtension.lowercased()
            if supportedExts.contains(ext) { return true }
            // tar.gz special case
            if url.lastPathComponent.lowercased().hasSuffix(".tar.gz") { return true }
            return false
        }
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let coordinator: ArchiveOpening
    private var dropWindow: DropWindow?

    override init() {
        self.coordinator = AppBootstrap.makeArchiveCoordinator()
        super.init()
    }

    init(coordinator: ArchiveOpening) {
        self.coordinator = coordinator
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Show the drop target window on launch
        let win = DropWindow(archiveCoordinator: coordinator)
        win.makeKeyAndOrderFront(nil)
        self.dropWindow = win
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            coordinator.open(url: url)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            dropWindow?.makeKeyAndOrderFront(nil)
        }
        return true
    }
}

private enum AppBootstrap {
    static func makeArchiveCoordinator() -> ArchiveOpening {
        let prompts = NativePromptController()
        let preferencesStore = PreferencesStore(passwordStore: InMemoryPasswordStore())
        let destinationResolver = DestinationResolver(prompting: prompts)
        let completionRunner = CompletionActionRunner()

        do {
            let toolURL = try SevenZipToolLocator.bundledToolURL()
            let backend = SevenZipBackend(toolURL: toolURL, runner: ProcessRunner())
            let coordinator = ExtractionCoordinator(
                backend: backend,
                preferencesStore: preferencesStore,
                destinationResolver: destinationResolver,
                prompts: prompts,
                completionRunner: completionRunner
            )
            return RuntimeArchiveCoordinator(coordinator: coordinator, prompts: prompts)
        } catch {
            prompts.showError(.unknown(details: error.localizedDescription), details: error.localizedDescription)
            return RecordingCoordinator()
        }
    }
}
