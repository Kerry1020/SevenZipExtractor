import Foundation

struct SevenZipCommandBuilder {
    let toolURL: URL

    func probeCommand(archiveURL: URL, password: String?) -> ProcessCommand {
        var arguments = ["l", "-slt", archiveURL.path]

        if let password, !password.isEmpty {
            arguments.append("-p\(password)")
        }

        return ProcessCommand(
            executableURL: toolURL,
            arguments: arguments
        )
    }

    func extractCommand(
        archiveURL: URL,
        destinationURL: URL,
        password: String?,
        conflictPolicy: ConflictPolicy
    ) -> ProcessCommand {
        var arguments = [
            "x",
            archiveURL.path,
            "-o\(destinationURL.path)"
        ]

        if let overwriteFlag = overwriteFlag(for: conflictPolicy) {
            arguments.append(overwriteFlag)
        }

        if let password, !password.isEmpty {
            arguments.append("-p\(password)")
        }

        return ProcessCommand(
            executableURL: toolURL,
            arguments: arguments
        )
    }

    private func overwriteFlag(for conflictPolicy: ConflictPolicy) -> String? {
        switch conflictPolicy {
        case .ask, .autoRename:
            return "-aou"
        case .skipAll:
            return "-aos"
        case .replaceAll:
            return "-aoa"
        }
    }
}
