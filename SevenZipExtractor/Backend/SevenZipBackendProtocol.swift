import Foundation

struct ProcessCommand: Equatable {
    let executableURL: URL
    let arguments: [String]
}

protocol SevenZipBackendProtocol {
    func probeArchive(at archiveURL: URL, password: String?) async throws -> ArchiveProbe
    func extractArchive(
        at archiveURL: URL,
        to destinationURL: URL,
        password: String?,
        conflictPolicy: ConflictPolicy
    ) async throws -> ExtractionResult
}
