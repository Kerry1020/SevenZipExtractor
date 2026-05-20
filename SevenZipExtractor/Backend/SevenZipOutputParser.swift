import Foundation

struct SevenZipOutputParser {
    func parseProbeOutput(_ output: String, archiveURL: URL) -> ArchiveProbe {
        let lowercased = output.lowercased()
        let format = archiveFormat(from: lowercased)
        let needsPassword: Bool?

        if lowercased.contains("encrypted = +") {
            needsPassword = true
        } else {
            needsPassword = nil
        }

        return ArchiveProbe(
            format: format,
            needsPassword: needsPassword,
            canExtract: format != nil,
            multiVolumeInfo: parseMultiVolumeInfo(archiveURL: archiveURL)
        )
    }

    func parseExtractFailure(_ output: String) -> ExtractionFailure {
        let lowercased = output.lowercased()

        if lowercased.contains("wrong password") {
            return .wrongPassword
        }

        if lowercased.contains("can not open encrypted archive") || lowercased.contains("enter password") {
            return .passwordRequired
        }

        if lowercased.contains("unexpected end of archive") || lowercased.contains("is not archive") {
            return .archiveDamaged
        }

        if lowercased.contains("cannot open the file as archive") {
            return .unsupportedFormat
        }

        if lowercased.contains("no such file or directory") {
            return .missingVolume
        }

        if lowercased.contains("permission denied") {
            return .noWritePermission
        }

        return .unknown(details: output)
    }

    private func archiveFormat(from lowercasedOutput: String) -> ArchiveFormat? {
        ArchiveFormat.allCases.first { format in
            let rawValue = format.rawValue.lowercased()
            return lowercasedOutput.contains("type = \(rawValue)")
        }
    }

    private func parseMultiVolumeInfo(archiveURL: URL) -> MultiVolumeInfo {
        let name = archiveURL.lastPathComponent.lowercased()

        if name.hasSuffix(".part1.rar") || name.hasSuffix(".7z.001") || name.hasSuffix(".zip.001") {
            return .mainVolume
        }

        if name.range(of: #"\.part\d+\.rar$"#, options: .regularExpression) != nil ||
            name.range(of: #"\.(7z|zip)\.\d{3}$"#, options: .regularExpression) != nil {
            return .nonMainVolume(expectedMainURL: nil)
        }

        return .none
    }
}
