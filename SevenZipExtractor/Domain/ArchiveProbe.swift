import Foundation

struct ArchiveProbe: Codable, Hashable {
    let format: ArchiveFormat?
    let needsPassword: Bool?
    let canExtract: Bool
    let multiVolumeInfo: MultiVolumeInfo
}
