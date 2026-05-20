import Foundation

enum SevenZipToolLocator {
    static func bundledToolURL(bundle: Bundle = .main) throws -> URL {
        if let toolURL = bundle.url(forResource: "7zz", withExtension: nil) {
            return toolURL
        }

        throw NSError(
            domain: "SevenZipToolLocator",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Bundled 7zz tool not found."]
        )
    }
}
