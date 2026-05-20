import XCTest
@testable import SevenZipExtractor

final class ExtractionCoordinatorTests: XCTestCase {
    func testPromptsForPasswordImmediatelyWhenProbeRequiresIt() async throws {
        let backend = StubBackend(
            probe: ArchiveProbe(
                format: .zip,
                needsPassword: true,
                canExtract: true,
                multiVolumeInfo: .none
            ),
            extractionResults: [
                .success(ExtractionSuccess(destinationURL: URL(fileURLWithPath: "/tmp/out")))
            ]
        )
        let prompts = StubUserPrompts(password: "secret")
        let coordinator = ExtractionCoordinator(
            backend: backend,
            preferencesStore: StubPreferencesStore(),
            destinationResolver: DestinationResolver(prompting: StubDestinationPrompt(selectedURL: nil)),
            prompts: prompts,
            completionRunner: StubCompletionRunner()
        )

        let result = try await coordinator.handleOpen(url: URL(fileURLWithPath: "/tmp/sample.zip"))

        XCTAssertEqual(result, .success(ExtractionSuccess(destinationURL: URL(fileURLWithPath: "/tmp/out"))))
        XCTAssertEqual(prompts.passwordPromptCount, 1)
    }

    func testStopsWhenOpenedArchiveIsNotMainVolume() async throws {
        let backend = StubBackend(
            probe: ArchiveProbe(
                format: .rar,
                needsPassword: nil,
                canExtract: true,
                multiVolumeInfo: .nonMainVolume(expectedMainURL: nil)
            ),
            extractionResults: [
                .success(ExtractionSuccess(destinationURL: URL(fileURLWithPath: "/tmp/out")))
            ]
        )
        let coordinator = ExtractionCoordinator(
            backend: backend,
            preferencesStore: StubPreferencesStore(),
            destinationResolver: DestinationResolver(prompting: StubDestinationPrompt(selectedURL: nil)),
            prompts: StubUserPrompts(password: nil),
            completionRunner: StubCompletionRunner()
        )

        let result = try await coordinator.handleOpen(url: URL(fileURLWithPath: "/tmp/sample.part2.rar"))

        XCTAssertEqual(result, .failure(.notMainVolume))
    }

    func testRetriesAfterDeferredPasswordRequirement() async throws {
        let backend = StubBackend(
            probe: ArchiveProbe(
                format: .zip,
                needsPassword: nil,
                canExtract: true,
                multiVolumeInfo: .none
            ),
            extractionResults: [
                .failure(.passwordRequired),
                .success(ExtractionSuccess(destinationURL: URL(fileURLWithPath: "/tmp/out")))
            ]
        )
        let prompts = StubUserPrompts(password: "secret")
        let coordinator = ExtractionCoordinator(
            backend: backend,
            preferencesStore: StubPreferencesStore(),
            destinationResolver: DestinationResolver(prompting: StubDestinationPrompt(selectedURL: nil)),
            prompts: prompts,
            completionRunner: StubCompletionRunner()
        )

        let result = try await coordinator.handleOpen(url: URL(fileURLWithPath: "/tmp/sample.zip"))

        XCTAssertEqual(result, .success(ExtractionSuccess(destinationURL: URL(fileURLWithPath: "/tmp/out"))))
        XCTAssertEqual(prompts.passwordPromptCount, 1)
    }

    func testReturnsCancelledWhenDestinationSelectionIsCancelled() async throws {
        let backend = StubBackend(
            probe: ArchiveProbe(
                format: .zip,
                needsPassword: nil,
                canExtract: true,
                multiVolumeInfo: .none
            ),
            extractionResults: [
                .success(ExtractionSuccess(destinationURL: URL(fileURLWithPath: "/tmp/out")))
            ]
        )
        let preferences = ExtractionPreferences(
            enabledFormats: ExtractionPreferences.defaultValue.enabledFormats,
            destination: .askEveryTime,
            conflictPolicy: .ask,
            passwordStorage: .doNotSave,
            completionAction: .doNothing,
            showMultiVolumeGuidance: true
        )
        let coordinator = ExtractionCoordinator(
            backend: backend,
            preferencesStore: StubPreferencesStore(preferences: preferences),
            destinationResolver: DestinationResolver(prompting: StubDestinationPrompt(selectedURL: nil)),
            prompts: StubUserPrompts(password: nil),
            completionRunner: StubCompletionRunner()
        )

        let result = try await coordinator.handleOpen(url: URL(fileURLWithPath: "/tmp/sample.zip"))

        XCTAssertEqual(result, .failure(.cancelled))
    }
}
