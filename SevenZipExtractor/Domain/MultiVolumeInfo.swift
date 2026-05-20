import Foundation

enum MultiVolumeInfo: Codable, Hashable {
    case none
    case mainVolume
    case nonMainVolume(expectedMainURL: URL?)
}
