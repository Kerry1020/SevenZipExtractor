import Foundation

enum ArchiveFormat: String, Codable, CaseIterable, Hashable {
    case sevenZip = "7z"
    case zip
    case rar
    case tar
    case gz
    case bz2
    case xz
    case tgz
    case tarGz = "tar.gz"

    var displayExtension: String {
        rawValue
    }
}
