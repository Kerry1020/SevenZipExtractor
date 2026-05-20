import XCTest
@testable import SevenZipExtractor

final class SevenZipBackendTests: XCTestCase {
    func testExtractReturnsWrongPasswordFailureWhenParserSeesPasswordError() async throws {
        let backend = SevenZipBackend(
            toolURL: URL(fileURLWithPath: "/tmp/7zz"),
            runner: StubProcessRunner(
                stdout: "",
                stderr: "ERROR: Wrong password? : sample.txt",
                exitCode: 2
            )
        )

        let result = try await backend.extractArchive(
            at: URL(fileURLWithPath: "/tmp/sample.zip"),
            to: URL(fileURLWithPath: "/tmp/out"),
            password: "bad",
            conflictPolicy: .replaceAll
        )

        XCTAssertEqual(result, .failure(.wrongPassword))
    }

    func testProbeReturnsParsedArchiveProbeFromProcessOutput() async throws {
        let backend = SevenZipBackend(
            toolURL: URL(fileURLWithPath: "/tmp/7zz"),
            runner: StubProcessRunner(
                stdout: "Type = 7z\nEncrypted = +\n",
                stderr: "",
                exitCode: 0
            )
        )

        let probe = try await backend.probeArchive(
            at: URL(fileURLWithPath: "/tmp/sample.7z"),
            password: nil
        )

        XCTAssertEqual(probe.format, .sevenZip)
        XCTAssertEqual(probe.needsPassword, true)
        XCTAssertTrue(probe.canExtract)
    }
}
