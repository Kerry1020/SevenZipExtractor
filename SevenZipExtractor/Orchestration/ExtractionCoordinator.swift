import Foundation

protocol UserPrompting {
    func requestPassword(for archiveURL: URL) async throws -> String?
    func showError(_ failure: ExtractionFailure, details: String?)
}

protocol ExtractionHandling {
    func handleOpen(url: URL) async throws -> ExtractionResult
}

final class StubUserPrompts: UserPrompting {
    private(set) var passwordPromptCount = 0
    private let password: String?

    init(password: String?) {
        self.password = password
    }

    func requestPassword(for archiveURL: URL) async throws -> String? {
        passwordPromptCount += 1
        return password
    }

    func showError(_ failure: ExtractionFailure, details: String?) {}
}

protocol CompletionRunning {
    func run(for success: ExtractionSuccess, action: CompletionAction)
}

struct StubCompletionRunner: CompletionRunning {
    func run(for success: ExtractionSuccess, action: CompletionAction) {}
}

final class StubBackend: SevenZipBackendProtocol {
    private let probeResult: ArchiveProbe
    private var extractionResults: [ExtractionResult]

    init(probe: ArchiveProbe, extractionResults: [ExtractionResult]) {
        self.probeResult = probe
        self.extractionResults = extractionResults
    }

    func probeArchive(at archiveURL: URL, password: String?) async throws -> ArchiveProbe {
        probeResult
    }

    func extractArchive(
        at archiveURL: URL,
        to destinationURL: URL,
        password: String?,
        conflictPolicy: ConflictPolicy
    ) async throws -> ExtractionResult {
        extractionResults.removeFirst()
    }
}

protocol PreferencesLoading {
    func load() -> ExtractionPreferences
}

final class StubPreferencesStore: PreferencesLoading {
    private let stubPreferences: ExtractionPreferences

    init(preferences: ExtractionPreferences = .defaultValue) {
        self.stubPreferences = preferences
    }

    func load() -> ExtractionPreferences {
        stubPreferences
    }
}

extension PreferencesStore: PreferencesLoading {}

final class ExtractionCoordinator {
    private let backend: SevenZipBackendProtocol
    private let preferencesStore: PreferencesLoading
    private let destinationResolver: DestinationResolver
    private let prompts: UserPrompting
    private let completionRunner: CompletionRunning

    init(
        backend: SevenZipBackendProtocol,
        preferencesStore: PreferencesLoading,
        destinationResolver: DestinationResolver,
        prompts: UserPrompting,
        completionRunner: CompletionRunning
    ) {
        self.backend = backend
        self.preferencesStore = preferencesStore
        self.destinationResolver = destinationResolver
        self.prompts = prompts
        self.completionRunner = completionRunner
    }

    func handleOpen(url: URL) async throws -> ExtractionResult {
        let preferences = preferencesStore.load()
        let probe = try await backend.probeArchive(at: url, password: nil)

        guard probe.canExtract, let format = probe.format, preferences.enabledFormats.contains(format) else {
            return .failure(.unsupportedFormat)
        }

        if case .nonMainVolume = probe.multiVolumeInfo {
            return .failure(.notMainVolume)
        }

        let destination: URL
        do {
            destination = try destinationResolver.resolveDestination(for: url, preference: preferences.destination)
        } catch is CancellationError {
            return .failure(.cancelled)
        }
        var password: String?

        if probe.needsPassword == true {
            guard let enteredPassword = try await prompts.requestPassword(for: url) else {
                return .failure(.cancelled)
            }
            password = enteredPassword
        }

        // Extract with progress
        var result = try await extractWithProgress(
            archiveURL: url,
            destinationURL: destination,
            password: password,
            conflictPolicy: preferences.conflictPolicy
        )

        // Retry with password if needed
        if case .failure(.passwordRequired) = result, probe.needsPassword != true {
            guard let enteredPassword = try await prompts.requestPassword(for: url) else {
                return .failure(.cancelled)
            }

            result = try await extractWithProgress(
                archiveURL: url,
                destinationURL: destination,
                password: enteredPassword,
                conflictPolicy: preferences.conflictPolicy
            )
        }

        if case .success(let success) = result {
            completionRunner.run(for: success, action: preferences.completionAction)
        }

        return result
    }

    private func extractWithProgress(
        archiveURL: URL,
        destinationURL: URL,
        password: String?,
        conflictPolicy: ConflictPolicy
    ) async throws -> ExtractionResult {
        let progressWin = await ExtractionProgressWindow()
        let (onProgress, _) = await progressWin.show(archiveName: archiveURL.lastPathComponent)

        if let backend = backend as? SevenZipBackend {
            backend.onProgress = onProgress
        }

        var result: ExtractionResult
        do {
            result = try await backend.extractArchive(
                at: archiveURL,
                to: destinationURL,
                password: password,
                conflictPolicy: conflictPolicy
            )
        } catch {
            await progressWin.close()
            throw error
        }

        let isCancelled = await progressWin.viewModel?.cancelled ?? false
        await progressWin.close()

        if isCancelled {
            if let backend = backend as? SevenZipBackend {
                backend.cancel()
            }
            return .failure(.cancelled)
        }

        return result
    }
}

extension ExtractionCoordinator: ExtractionHandling {}
