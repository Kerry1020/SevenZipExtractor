import XCTest
@testable import SevenZipExtractor

final class SevenZipOutputParserTests: XCTestCase {
    func testProbeMarksPasswordProtectedArchive() {
        let output = "Path = sample.7z\nEncrypted = +\nType = 7z\n"

        let probe = SevenZipOutputParser().parseProbeOutput(
            output,
            archiveURL: URL(fileURLWithPath: "/tmp/sample.7z")
        )

        XCTAssertEqual(probe.format, .sevenZip)
        XCTAssertEqual(probe.needsPassword, true)
        XCTAssertTrue(probe.canExtract)
        XCTAssertEqual(probe.multiVolumeInfo, .none)
    }

    func testProbeLeavesPasswordRequirementUnknownWhenHeaderDoesNotDeclareEncryption() {
        let output = "Path = sample.zip\nType = zip\n"

        let probe = SevenZipOutputParser().parseProbeOutput(
            output,
            archiveURL: URL(fileURLWithPath: "/tmp/sample.zip")
        )

        XCTAssertEqual(probe.format, .zip)
        XCTAssertNil(probe.needsPassword)
        XCTAssertTrue(probe.canExtract)
    }

    func testExtractMapsWrongPasswordError() {
        let output = "ERROR: Wrong password? : sample.txt"

        let result = SevenZipOutputParser().parseExtractFailure(output)

        XCTAssertEqual(result, .wrongPassword)
    }

    func testExtractMapsDamagedArchiveError() {
        let output = "ERRORS:\nUnexpected end of archive"

        let result = SevenZipOutputParser().parseExtractFailure(output)

        XCTAssertEqual(result, .archiveDamaged)
    }

    func testProbeMarksSecondaryRarPartAsNonMainVolume() {
        let archiveURL = URL(fileURLWithPath: "/tmp/sample.part2.rar")
        let probe = SevenZipOutputParser().parseProbeOutput("Type = Rar\n", archiveURL: archiveURL)

        XCTAssertEqual(probe.multiVolumeInfo, .nonMainVolume(expectedMainURL: nil))
    }
}
