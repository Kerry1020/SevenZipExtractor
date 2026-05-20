import SwiftUI

struct ExtractionSettingsSectionView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        GroupBox("Extraction") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Destination")
                        .font(.headline)
                    Picker("Destination", selection: destinationBinding) {
                        ForEach(DestinationSelection.allCases) { selection in
                            Text(selection.title).tag(selection)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.radioGroup)

                    if viewModel.destinationSelection == .fixedDirectory {
                        HStack {
                            Text(viewModel.fixedDirectoryDisplayPath)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                            Spacer()
                            Button("Choose…") {
                                viewModel.chooseFixedDestinationDirectory()
                            }
                        }
                    }
                }

                Picker("When files already exist", selection: conflictPolicyBinding) {
                    Text("Ask").tag(ConflictPolicy.ask)
                    Text("Skip all").tag(ConflictPolicy.skipAll)
                    Text("Replace all").tag(ConflictPolicy.replaceAll)
                    Text("Auto-rename").tag(ConflictPolicy.autoRename)
                }

                Picker("Passwords", selection: passwordStorageBinding) {
                    Text("Do not save").tag(PasswordStoragePreference.doNotSave)
                    Text("Remember for this session").tag(PasswordStoragePreference.rememberForSession)
                    Text("Save to Keychain").tag(PasswordStoragePreference.saveToKeychain)
                }

                Picker("After extraction", selection: completionActionBinding) {
                    Text("Do nothing").tag(CompletionAction.doNothing)
                    Text("Reveal in Finder").tag(CompletionAction.revealInFinder)
                    Text("Open extracted folder").tag(CompletionAction.openExtractedDirectory)
                }

                Toggle(
                    "Show multi-volume guidance",
                    isOn: Binding(
                        get: { viewModel.preferences.showMultiVolumeGuidance },
                        set: { viewModel.setShowMultiVolumeGuidance($0) }
                    )
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var destinationBinding: Binding<DestinationSelection> {
        Binding(
            get: { viewModel.destinationSelection },
            set: { selection in
                switch selection {
                case .sameDirectory:
                    viewModel.setDestination(.sameDirectory)
                case .askEveryTime:
                    viewModel.setDestination(.askEveryTime)
                case .fixedDirectory:
                    if case .fixedDirectory = viewModel.preferences.destination {
                        return
                    }
                    viewModel.setDestination(.fixedDirectory(FileManager.default.homeDirectoryForCurrentUser))
                }
            }
        )
    }

    private var conflictPolicyBinding: Binding<ConflictPolicy> {
        Binding(
            get: { viewModel.preferences.conflictPolicy },
            set: { viewModel.setConflictPolicy($0) }
        )
    }

    private var passwordStorageBinding: Binding<PasswordStoragePreference> {
        Binding(
            get: { viewModel.preferences.passwordStorage },
            set: { viewModel.setPasswordStorage($0) }
        )
    }

    private var completionActionBinding: Binding<CompletionAction> {
        Binding(
            get: { viewModel.preferences.completionAction },
            set: { viewModel.setCompletionAction($0) }
        )
    }
}
