import AppKit
import Foundation

protocol PasswordPromptPresenting {
    func requestPassword(for archiveURL: URL) async throws -> String?
}

protocol DestinationChoosing {
    func chooseDestinationDirectory() throws -> URL?
}

struct NativePasswordPromptPresenter: PasswordPromptPresenting {
    @MainActor
    func requestPassword(for archiveURL: URL) async throws -> String? {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Enter Archive Password"
        alert.informativeText = archiveURL.lastPathComponent

        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.placeholderString = "Password"
        alert.accessoryView = field
        alert.addButton(withTitle: "Extract")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            return nil
        }

        let password = field.stringValue
        return password.isEmpty ? nil : password
    }
}

struct NativeDestinationChooser: DestinationChoosing {
    @MainActor
    func chooseDestinationDirectory() throws -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Choose where to extract the archive."

        let response = panel.runModal()
        guard response == .OK else {
            return nil
        }

        return panel.url
    }
}

final class NativePromptController: UserPrompting, DestinationPrompting {
    private let passwordPresenter: PasswordPromptPresenting
    private let destinationChooser: DestinationChoosing
    private let errorPresenter: ErrorAlertPresenter

    init(
        passwordPresenter: PasswordPromptPresenting = NativePasswordPromptPresenter(),
        destinationChooser: DestinationChoosing = NativeDestinationChooser(),
        errorPresenter: ErrorAlertPresenter = ErrorAlertPresenter()
    ) {
        self.passwordPresenter = passwordPresenter
        self.destinationChooser = destinationChooser
        self.errorPresenter = errorPresenter
    }

    func requestPassword(for archiveURL: URL) async throws -> String? {
        try await passwordPresenter.requestPassword(for: archiveURL)
    }

    func showError(_ failure: ExtractionFailure, details: String?) {
        errorPresenter.present(failure: failure, details: details)
    }

    func chooseDestinationDirectory() throws -> URL? {
        try destinationChooser.chooseDestinationDirectory()
    }
}
