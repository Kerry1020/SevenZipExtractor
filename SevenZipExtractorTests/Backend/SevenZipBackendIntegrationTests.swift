import Foundation
import XCTest
@testable import SevenZipExtractor

final class SevenZipBackendIntegrationTests: XCTestCase {
    func testProductionRunnerExtractsFixtureArchiveWithBundled7zz() async throws {
        let fixtureRoot = try makeFixtureRoot()
        let sourceDirectory = fixtureRoot.appendingPathComponent("source", isDirectory: true)
        let archiveURL = fixtureRoot.appendingPathComponent("sample.zip")
        let destinationDirectory = fixtureRoot.appendingPathComponent("output", isDirectory: true)
        let expectedFile = destinationDirectory.appendingPathComponent("hello.txt")

        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        try "hello from integration test\n".write(to: sourceDirectory.appendingPathComponent("hello.txt"), atomically: true, encoding: .utf8)

        let toolURL = try SevenZipToolLocator.bundledToolURL(bundle: Bundle.main)
        let archiver = Process()
        archiver.executableURL = toolURL
        archiver.arguments = ["a", archiveURL.path, "."]
        archiver.currentDirectoryURL = sourceDirectory
        try archiver.run()
        archiver.waitUntilExit()
        XCTAssertEqual(archiver.terminationStatus, 0)

        let backend = SevenZipBackend(toolURL: toolURL, runner: ProcessRunner())

        let probe = try await backend.probeArchive(at: archiveURL, password: nil)
        XCTAssertEqual(probe.format, .zip)

        let result = try await backend.extractArchive(
            at: archiveURL,
            to: destinationDirectory,
            password: nil,
            conflictPolicy: .replaceAll
        )

        XCTAssertEqual(result, .success(ExtractionSuccess(destinationURL: destinationDirectory)))
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedFile.path))
    }

    private func makeFixtureRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}
