import XCTest
@testable import SevenZipExtractor

final class SevenZipCommandBuilderTests: XCTestCase {
    func testProbeCommandWithoutPasswordUsesListFlagsOnly() {
        let toolURL = URL(fileURLWithPath: "/usr/local/bin/7zz")
        let archiveURL = URL(fileURLWithPath: "/tmp/archive.7z")

        let command = SevenZipCommandBuilder(toolURL: toolURL).probeCommand(
            archiveURL: archiveURL,
            password: nil
        )

        XCTAssertEqual(command.executableURL, toolURL)
        XCTAssertEqual(command.arguments, ["l", "-slt", archiveURL.path])
    }

    func testProbeCommandWithPasswordIncludesPasswordFlag() {
        let toolURL = URL(fileURLWithPath: "/usr/local/bin/7zz")
        let archiveURL = URL(fileURLWithPath: "/tmp/archive.7z")

        let command = SevenZipCommandBuilder(toolURL: toolURL).probeCommand(
            archiveURL: archiveURL,
            password: "secret"
        )

        XCTAssertEqual(command.arguments, ["l", "-slt", archiveURL.path, "-psecret"])
    }

    func testExtractCommandWithReplaceAllAndPasswordAddsOverwriteAndPasswordFlags() {
        let toolURL = URL(fileURLWithPath: "/usr/local/bin/7zz")
        let archiveURL = URL(fileURLWithPath: "/tmp/archive.7z")
        let destinationURL = URL(fileURLWithPath: "/tmp/output")

        let command = SevenZipCommandBuilder(toolURL: toolURL).extractCommand(
            archiveURL: archiveURL,
            destinationURL: destinationURL,
            password: "secret",
            conflictPolicy: .replaceAll
        )

        XCTAssertEqual(command.executableURL, toolURL)
        XCTAssertEqual(
            command.arguments,
            ["x", archiveURL.path, "-o\(destinationURL.path)", "-aoa", "-psecret"]
        )
    }

    func testExtractCommandWithAskOmitsOverwriteFlag() {
        let toolURL = URL(fileURLWithPath: "/usr/local/bin/7zz")
        let archiveURL = URL(fileURLWithPath: "/tmp/archive.7z")
        let destinationURL = URL(fileURLWithPath: "/tmp/output")

        let command = SevenZipCommandBuilder(toolURL: toolURL).extractCommand(
            archiveURL: archiveURL,
            destinationURL: destinationURL,
            password: nil,
            conflictPolicy: .ask
        )

        XCTAssertEqual(command.arguments, ["x", archiveURL.path, "-o\(destinationURL.path)"])
    }
}
