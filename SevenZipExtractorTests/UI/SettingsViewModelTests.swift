import XCTest
@testable import SevenZipExtractor

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testToggleFormatRemovesAndReaddsBoundArchiveFormat() {
        let preferences = ExtractionPreferences(
            enabledFormats: [.zip, .sevenZip],
            destination: .sameDirectory,
            conflictPolicy: .ask,
            passwordStorage: .doNotSave,
            completionAction: .doNothing,
            showMultiVolumeGuidance: true
        )
        let store = PreferencesStore(
            defaults: UserDefaults(suiteName: #fileID + #function)!,
            passwordStore: InMemoryPasswordStore()
        )
        let viewModel = SettingsViewModel(preferencesStore: store, initialPreferences: preferences)

        viewModel.setFormat(.zip, enabled: false)
        XCTAssertFalse(viewModel.preferences.enabledFormats.contains(.zip))

        viewModel.setFormat(.zip, enabled: true)
        XCTAssertTrue(viewModel.preferences.enabledFormats.contains(.zip))
    }
}
