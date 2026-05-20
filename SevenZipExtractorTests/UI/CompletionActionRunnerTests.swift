import XCTest
@testable import SevenZipExtractor

final class CompletionActionRunnerTests: XCTestCase {
    func testDoNothingDoesNotOpenWorkspace() {
        let workspace = RecordingWorkspace()
        let runner = CompletionActionRunner(workspace: workspace)
        let success = ExtractionSuccess(destinationURL: URL(fileURLWithPath: "/tmp/out"))

        runner.run(for: success, action: .doNothing)

        XCTAssertTrue(workspace.openedURLs.isEmpty)
        XCTAssertTrue(workspace.revealedURLs.isEmpty)
    }
}
