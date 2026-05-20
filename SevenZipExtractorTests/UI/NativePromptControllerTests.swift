import AppKit
import XCTest
@testable import SevenZipExtractor

final class NativePromptControllerTests: XCTestCase {
    func testShowErrorForwardsFailureToPresenter() {
        let alertRunner = RecordingAlertRunner()
        let presenter = ErrorAlertPresenter(alertRunner: alertRunner)
        let controller = NativePromptController(
            passwordPresenter: StubPasswordPromptPresenter(password: nil),
            destinationChooser: StubDestinationChooser(selectedURL: nil),
            errorPresenter: presenter
        )

        controller.showError(.archiveDamaged, details: nil)

        XCTAssertEqual(alertRunner.recordedAlerts.count, 1)
        XCTAssertEqual(alertRunner.recordedAlerts.first?.messageText, "Archive Damaged")
    }

    func testRequestPasswordUsesInjectedPasswordPresenter() async throws {
        let controller = NativePromptController(
            passwordPresenter: StubPasswordPromptPresenter(password: "secret"),
            destinationChooser: StubDestinationChooser(selectedURL: nil),
            errorPresenter: ErrorAlertPresenter(alertRunner: RecordingAlertRunner())
        )

        let password = try await controller.requestPassword(for: URL(fileURLWithPath: "/tmp/sample.7z"))

        XCTAssertEqual(password, "secret")
    }

    func testChooseDestinationDirectoryUsesInjectedChooser() throws {
        let selectedURL = URL(fileURLWithPath: "/tmp/out")
        let controller = NativePromptController(
            passwordPresenter: StubPasswordPromptPresenter(password: nil),
            destinationChooser: StubDestinationChooser(selectedURL: selectedURL),
            errorPresenter: ErrorAlertPresenter(alertRunner: RecordingAlertRunner())
        )

        let chosenURL = try controller.chooseDestinationDirectory()

        XCTAssertEqual(chosenURL, selectedURL)
    }
}

final class ErrorAlertPresenterTests: XCTestCase {
    func testPresentUsesProvidedDetailsWhenAvailable() {
        let runner = RecordingAlertRunner()
        let presenter = ErrorAlertPresenter(alertRunner: runner)

        presenter.present(failure: .unknown(details: "ignored"), details: "Disk full")

        XCTAssertEqual(runner.recordedAlerts.count, 1)
        XCTAssertEqual(runner.recordedAlerts.first?.messageText, "Extraction Failed")
        XCTAssertEqual(runner.recordedAlerts.first?.informativeText, "Disk full")
    }

    func testPresentUsesFailureSpecificFallbackMessage() {
        let runner = RecordingAlertRunner()
        let presenter = ErrorAlertPresenter(alertRunner: runner)

        presenter.present(failure: .notMainVolume, details: nil)

        XCTAssertEqual(runner.recordedAlerts.count, 1)
        XCTAssertEqual(runner.recordedAlerts.first?.messageText, "Open the First Volume")
        XCTAssertEqual(runner.recordedAlerts.first?.informativeText, "Open the first archive volume instead of a later part.")
    }
}

private final class RecordingAlertRunner: AlertRunning {
    private(set) var recordedAlerts: [NSAlert] = []

    @discardableResult
    func runModal(_ alert: NSAlert) -> NSApplication.ModalResponse {
        recordedAlerts.append(alert)
        return .alertFirstButtonReturn
    }
}

private struct StubPasswordPromptPresenter: PasswordPromptPresenting {
    let password: String?

    func requestPassword(for archiveURL: URL) async throws -> String? {
        password
    }
}

private struct StubDestinationChooser: DestinationChoosing {
    let selectedURL: URL?

    func chooseDestinationDirectory() throws -> URL? {
        selectedURL
    }
}
