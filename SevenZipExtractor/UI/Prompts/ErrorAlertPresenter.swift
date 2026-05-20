import AppKit
import Foundation

protocol AlertRunning {
    @discardableResult
    func runModal(_ alert: NSAlert) -> NSApplication.ModalResponse
}

struct NSAlertRunner: AlertRunning {
    @discardableResult
    func runModal(_ alert: NSAlert) -> NSApplication.ModalResponse {
        alert.runModal()
    }
}

final class ErrorAlertPresenter {
    private let alertRunner: AlertRunning

    init(alertRunner: AlertRunning = NSAlertRunner()) {
        self.alertRunner = alertRunner
    }

    func present(failure: ExtractionFailure, details: String?) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message(for: failure)
        alert.informativeText = informativeText(for: failure, details: details)
        alert.addButton(withTitle: "OK")
        alertRunner.runModal(alert)
    }

    private func message(for failure: ExtractionFailure) -> String {
        switch failure {
        case .passwordRequired:
            return "Password Required"
        case .wrongPassword:
            return "Wrong Password"
        case .archiveDamaged:
            return "Archive Damaged"
        case .unsupportedFormat:
            return "Unsupported Format"
        case .missingVolume:
            return "Missing Volume"
        case .noWritePermission:
            return "No Write Permission"
        case .nameConflict:
            return "Name Conflict"
        case .notMainVolume:
            return "Open the First Volume"
        case .cancelled:
            return "Extraction Cancelled"
        case .unknown:
            return "Extraction Failed"
        }
    }

    private func informativeText(for failure: ExtractionFailure, details: String?) -> String {
        if let details, !details.isEmpty {
            return details
        }

        switch failure {
        case .passwordRequired:
            return "This archive needs a password before it can be extracted."
        case .wrongPassword:
            return "The password was not accepted by the archive."
        case .archiveDamaged:
            return "The archive could not be read successfully."
        case .unsupportedFormat:
            return "This file format is not enabled or cannot be extracted."
        case .missingVolume:
            return "Some parts of this multi-volume archive are missing."
        case .noWritePermission:
            return "SevenZipExtractor does not have permission to write to the destination."
        case .nameConflict:
            return "A file or folder with the same name already exists at the destination."
        case .notMainVolume:
            return "Open the first archive volume instead of a later part."
        case .cancelled:
            return "The extraction was cancelled before any files were written."
        case .unknown(let details):
            return details
        }
    }
}
