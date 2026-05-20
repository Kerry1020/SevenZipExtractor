import XCTest
@testable import SevenZipExtractor

final class DestinationResolverTests: XCTestCase {
    func testSameDirectoryUsesArchiveParent() throws {
        let archiveURL = URL(fileURLWithPath: "/tmp/demo/sample.zip")
        let resolver = DestinationResolver(prompting: StubDestinationPrompt(selectedURL: nil))

        let destination = try resolver.resolveDestination(
            for: archiveURL,
            preference: .sameDirectory
        )

        XCTAssertEqual(destination.path, "/tmp/demo")
    }

    func testAskEveryTimeUsesPromptedDirectory() throws {
        let selectedURL = URL(fileURLWithPath: "/tmp/chosen")
        let resolver = DestinationResolver(prompting: StubDestinationPrompt(selectedURL: selectedURL))

        let destination = try resolver.resolveDestination(
            for: URL(fileURLWithPath: "/tmp/demo/sample.zip"),
            preference: .askEveryTime
        )

        XCTAssertEqual(destination, selectedURL)
    }

    func testAskEveryTimeThrowsCancellationWhenPromptReturnsNil() {
        let resolver = DestinationResolver(prompting: StubDestinationPrompt(selectedURL: nil))

        XCTAssertThrowsError(
            try resolver.resolveDestination(
                for: URL(fileURLWithPath: "/tmp/demo/sample.zip"),
                preference: .askEveryTime
            )
        ) { error in
            XCTAssertTrue(error is CancellationError)
        }
    }

    func testFixedDirectoryUsesConfiguredDirectory() throws {
        let fixedURL = URL(fileURLWithPath: "/tmp/fixed")
        let resolver = DestinationResolver(prompting: StubDestinationPrompt(selectedURL: nil))

        let destination = try resolver.resolveDestination(
            for: URL(fileURLWithPath: "/tmp/demo/sample.zip"),
            preference: .fixedDirectory(fixedURL)
        )

        XCTAssertEqual(destination, fixedURL)
    }
}
