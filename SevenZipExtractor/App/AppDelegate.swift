import AppKit
import Foundation

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

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let coordinator: ArchiveOpening

    override init() {
        self.coordinator = AppBootstrap.makeArchiveCoordinator()
        super.init()
    }

    init(coordinator: ArchiveOpening) {
        self.coordinator = coordinator
        super.init()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            coordinator.open(url: url)
        }
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
