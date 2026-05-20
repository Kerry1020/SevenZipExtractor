import Foundation

final class PreferencesStore {
    private let defaults: UserDefaults
    private let passwordStore: PasswordStore
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let persistenceKey = "extractionPreferences"

    init(defaults: UserDefaults = .standard, passwordStore: PasswordStore) {
        self.defaults = defaults
        self.passwordStore = passwordStore
    }

    func load() -> ExtractionPreferences {
        guard let data = defaults.data(forKey: persistenceKey) else {
            return .defaultValue
        }

        do {
            return try decoder.decode(ExtractionPreferences.self, from: data)
        } catch {
            return .defaultValue
        }
    }

    func save(_ preferences: ExtractionPreferences) {
        guard let data = try? encoder.encode(preferences) else {
            return
        }

        defaults.set(data, forKey: persistenceKey)

        if preferences.passwordStorage == .doNotSave {
            passwordStore.clearSessionPasswords()
        }
    }
}
