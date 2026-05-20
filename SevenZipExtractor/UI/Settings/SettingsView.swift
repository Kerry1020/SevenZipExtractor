import AppKit
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var preferences: ExtractionPreferences

    private let preferencesStore: PreferencesStore

    init(preferencesStore: PreferencesStore, initialPreferences: ExtractionPreferences? = nil) {
        self.preferencesStore = preferencesStore
        self.preferences = initialPreferences ?? preferencesStore.load()
    }

    func isFormatEnabled(_ format: ArchiveFormat) -> Bool {
        preferences.enabledFormats.contains(format)
    }

    func setFormat(_ format: ArchiveFormat, enabled: Bool) {
        var enabledFormats = preferences.enabledFormats
        if enabled {
            enabledFormats.insert(format)
        } else {
            enabledFormats.remove(format)
        }

        updatePreferences(enabledFormats: enabledFormats)
    }

    func setDestination(_ destination: DestinationPreference) {
        updatePreferences(destination: destination)
    }

    func setConflictPolicy(_ conflictPolicy: ConflictPolicy) {
        updatePreferences(conflictPolicy: conflictPolicy)
    }

    func setPasswordStorage(_ passwordStorage: PasswordStoragePreference) {
        updatePreferences(passwordStorage: passwordStorage)
    }

    func setCompletionAction(_ completionAction: CompletionAction) {
        updatePreferences(completionAction: completionAction)
    }

    func setShowMultiVolumeGuidance(_ showMultiVolumeGuidance: Bool) {
        updatePreferences(showMultiVolumeGuidance: showMultiVolumeGuidance)
    }

    func chooseFixedDestinationDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        if case .fixedDirectory(let url) = preferences.destination {
            panel.directoryURL = url
        }

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        setDestination(.fixedDirectory(url))
    }

    var destinationSelection: DestinationSelection {
        switch preferences.destination {
        case .sameDirectory:
            return .sameDirectory
        case .askEveryTime:
            return .askEveryTime
        case .fixedDirectory:
            return .fixedDirectory
        }
    }

    var fixedDirectoryDisplayPath: String {
        guard case .fixedDirectory(let url) = preferences.destination else {
            return "No folder selected"
        }

        return url.path
    }

    private func updatePreferences(
        enabledFormats: Set<ArchiveFormat>? = nil,
        destination: DestinationPreference? = nil,
        conflictPolicy: ConflictPolicy? = nil,
        passwordStorage: PasswordStoragePreference? = nil,
        completionAction: CompletionAction? = nil,
        showMultiVolumeGuidance: Bool? = nil
    ) {
        let updatedPreferences = ExtractionPreferences(
            enabledFormats: enabledFormats ?? preferences.enabledFormats,
            destination: destination ?? preferences.destination,
            conflictPolicy: conflictPolicy ?? preferences.conflictPolicy,
            passwordStorage: passwordStorage ?? preferences.passwordStorage,
            completionAction: completionAction ?? preferences.completionAction,
            showMultiVolumeGuidance: showMultiVolumeGuidance ?? preferences.showMultiVolumeGuidance
        )

        preferences = updatedPreferences
        preferencesStore.save(updatedPreferences)
    }
}

enum DestinationSelection: String, CaseIterable, Identifiable {
    case sameDirectory
    case askEveryTime
    case fixedDirectory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sameDirectory:
            return "Same as archive"
        case .askEveryTime:
            return "Ask every time"
        case .fixedDirectory:
            return "Specific folder"
        }
    }
}

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ExtractionSettingsSectionView(viewModel: viewModel)
                BindingsSectionView(viewModel: viewModel)
            }
            .padding(20)
        }
        .frame(minWidth: 560, idealWidth: 560, minHeight: 420, idealHeight: 420)
    }
}
