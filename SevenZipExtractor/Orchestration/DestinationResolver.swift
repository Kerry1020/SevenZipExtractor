import Foundation

protocol DestinationPrompting {
    func chooseDestinationDirectory() throws -> URL?
}

struct StubDestinationPrompt: DestinationPrompting {
    let selectedURL: URL?

    func chooseDestinationDirectory() throws -> URL? {
        selectedURL
    }
}

struct DestinationResolver {
    let prompting: DestinationPrompting

    func resolveDestination(for archiveURL: URL, preference: DestinationPreference) throws -> URL {
        switch preference {
        case .sameDirectory:
            return archiveURL.deletingLastPathComponent()
        case .askEveryTime:
            guard let selected = try prompting.chooseDestinationDirectory() else {
                throw CancellationError()
            }
            return selected
        case .fixedDirectory(let url):
            return url
        }
    }
}
