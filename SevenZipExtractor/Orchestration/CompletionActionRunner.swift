import AppKit
import Foundation

protocol WorkspaceOpening {
    func activateFileViewerSelecting(_ urls: [URL])
    @discardableResult
    func open(_ url: URL) -> Bool
}

extension NSWorkspace: WorkspaceOpening {}

final class CompletionActionRunner: CompletionRunning {
    private let workspace: WorkspaceOpening

    init(workspace: WorkspaceOpening = NSWorkspace.shared) {
        self.workspace = workspace
    }

    func run(for success: ExtractionSuccess, action: CompletionAction) {
        switch action {
        case .doNothing:
            break
        case .revealInFinder:
            workspace.activateFileViewerSelecting([success.destinationURL])
        case .openExtractedDirectory:
            workspace.open(success.destinationURL)
        }
    }
}

final class RecordingWorkspace: WorkspaceOpening {
    private(set) var revealedURLs: [[URL]] = []
    private(set) var openedURLs: [URL] = []

    func activateFileViewerSelecting(_ urls: [URL]) {
        revealedURLs.append(urls)
    }

    func open(_ url: URL) -> Bool {
        openedURLs.append(url)
        return true
    }
}
