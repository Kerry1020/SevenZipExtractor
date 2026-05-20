import AppKit
import XCTest
@testable import SevenZipExtractor

final class AppDelegateTests: XCTestCase {
    func testOpenUrlsForwardsEachArchiveToCoordinator() {
        let coordinator = RecordingCoordinator()
        let appDelegate = AppDelegate(coordinator: coordinator)
        let archiveURL = URL(fileURLWithPath: "/tmp/sample.zip")

        appDelegate.application(NSApplication.shared, open: [archiveURL])

        XCTAssertEqual(coordinator.openedURLs, [archiveURL])
    }

    func testRuntimeArchiveCoordinatorShowsExtractionFailure() {
        let prompts = RecordingUserPrompts()
        let coordinator = ExtractionCoordinator(
            backend: StubBackend(
                probe: ArchiveProbe(
                    format: .zip,
                    needsPassword: nil,
                    canExtract: true,
                    multiVolumeInfo: .none
                ),
                extractionResults: [.failure(.archiveDamaged)]
            ),
            preferencesStore: StubPreferencesStore(),
            destinationResolver: DestinationResolver(prompting: StubDestinationPrompt(selectedURL: nil)),
            prompts: prompts,
            completionRunner: StubCompletionRunner()
        )
        let runtimeCoordinator = RuntimeArchiveCoordinator(coordinator: coordinator, prompts: prompts)
        let archiveURL = URL(fileURLWithPath: "/tmp/sample.zip")

        runtimeCoordinator.open(url: archiveURL)
        wait(for: [prompts.errorExpectation], timeout: 1)

        XCTAssertEqual(prompts.reportedFailures, [.archiveDamaged])
    }

    func testRuntimeArchiveCoordinatorShowsUnknownErrorWhenCoordinatorThrows() {
        let prompts = RecordingUserPrompts()
        let coordinator = ThrowingExtractionCoordinator()
        let runtimeCoordinator = RuntimeArchiveCoordinator(coordinator: coordinator, prompts: prompts)
        let archiveURL = URL(fileURLWithPath: "/tmp/sample.zip")

        runtimeCoordinator.open(url: archiveURL)
        wait(for: [prompts.errorExpectation], timeout: 1)

        XCTAssertEqual(prompts.reportedFailures, [.unknown(details: SampleError.boom.localizedDescription)])
    }
}

private final class RecordingUserPrompts: UserPrompting {
    let errorExpectation = XCTestExpectation(description: "showError called")
    private(set) var reportedFailures: [ExtractionFailure] = []

    func requestPassword(for archiveURL: URL) async throws -> String? {
        nil
    }

    func showError(_ failure: ExtractionFailure, details: String?) {
        reportedFailures.append(failure)
        errorExpectation.fulfill()
    }
}

private enum SampleError: LocalizedError {
    case boom

    var errorDescription: String? {
        "boom"
    }
}

private final class ThrowingExtractionCoordinator: ExtractionHandling {
    func handleOpen(url: URL) async throws -> ExtractionResult {
        throw SampleError.boom
    }
}
