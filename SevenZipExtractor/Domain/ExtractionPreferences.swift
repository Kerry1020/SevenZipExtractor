import Foundation

enum DestinationPreference: Codable, Hashable {
    case sameDirectory
    case askEveryTime
    case fixedDirectory(URL)
}

enum ConflictPolicy: String, Codable, Hashable {
    case ask
    case skipAll
    case replaceAll
    case autoRename
}

enum PasswordStoragePreference: String, Codable, Hashable {
    case doNotSave
    case rememberForSession
    case saveToKeychain
}

enum CompletionAction: String, Codable, Hashable {
    case doNothing
    case revealInFinder
    case openExtractedDirectory
}

struct ExtractionPreferences: Codable, Hashable {
    let enabledFormats: Set<ArchiveFormat>
    let destination: DestinationPreference
    let conflictPolicy: ConflictPolicy
    let passwordStorage: PasswordStoragePreference
    let completionAction: CompletionAction
    let showMultiVolumeGuidance: Bool

    static let defaultValue = ExtractionPreferences(
        enabledFormats: [.sevenZip, .zip, .rar, .tar, .gz, .bz2, .xz, .tgz, .tarGz],
        destination: .sameDirectory,
        // .ask maps to -aou in SevenZipCommandBuilder (auto-rename on
        // collision). We keep .ask as the *intent* the user selected
        // (let the extractor decide per-file), and the builder resolves
        // it to a non-blocking 7zz flag since the 7zz process has no TTY.
        conflictPolicy: .ask,
        passwordStorage: .doNotSave,
        completionAction: .doNothing,
        showMultiVolumeGuidance: true
    )
}
