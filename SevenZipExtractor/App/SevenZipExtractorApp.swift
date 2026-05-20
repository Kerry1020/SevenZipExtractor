import SwiftUI

@main
struct SevenZipExtractorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settingsViewModel = SettingsBootstrap.makeViewModel()

    var body: some Scene {
        Settings {
            SettingsView(viewModel: settingsViewModel)
        }
    }
}

private enum SettingsBootstrap {
    @MainActor
    static func makeViewModel() -> SettingsViewModel {
        SettingsViewModel(
            preferencesStore: PreferencesStore(passwordStore: InMemoryPasswordStore())
        )
    }
}
