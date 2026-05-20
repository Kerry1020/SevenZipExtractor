import Foundation

enum ExtractionFailure: Codable, Hashable {
    case passwordRequired
    case wrongPassword
    case archiveDamaged
    case unsupportedFormat
    case missingVolume
    case noWritePermission
    case nameConflict
    case notMainVolume
    case cancelled
    case unknown(details: String)
}

struct ExtractionSuccess: Codable, Hashable {
    let destinationURL: URL
}

enum ExtractionResult: Codable, Hashable {
    case success(ExtractionSuccess)
    case failure(ExtractionFailure)
}
