import Foundation

protocol PasswordStore {
    func save(_ password: String, for archiveURL: URL)
    func load(for archiveURL: URL) -> String?
    func clearSessionPasswords()
}

final class InMemoryPasswordStore: PasswordStore {
    private var passwordsByArchiveURL: [URL: String] = [:]

    func save(_ password: String, for archiveURL: URL) {
        passwordsByArchiveURL[archiveURL] = password
    }

    func load(for archiveURL: URL) -> String? {
        passwordsByArchiveURL[archiveURL]
    }

    func clearSessionPasswords() {
        passwordsByArchiveURL.removeAll()
    }
}
