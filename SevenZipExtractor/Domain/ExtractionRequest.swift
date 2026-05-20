import Foundation

struct ExtractionRequest: Codable, Hashable {
    let archiveURL: URL
    let launchedByFileOpen: Bool
}
