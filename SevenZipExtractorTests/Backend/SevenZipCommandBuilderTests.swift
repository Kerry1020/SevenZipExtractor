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
        // -y (assume Yes on all queries) is always prepended; -aoa then
        // forces overwrite on top. See SevenZipCommandBuilder.swift:29.
        XCTAssertEqual(
            command.arguments,
            ["x", archiveURL.path, "-o\(destinationURL.path)", "-y", "-aoa", "-psecret"]
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

        // -y is always prepended; .ask maps to -aou (auto-rename, treat
        // collision as a rename rather than a blocking prompt, because
        // the 7zz process has no TTY in this app). See
        // SevenZipCommandBuilder.swift:48-49.
        XCTAssertEqual(
            command.arguments,
            ["x", archiveURL.path, "-o\(destinationURL.path)", "-y", "-aou"]
        )
    }
}
