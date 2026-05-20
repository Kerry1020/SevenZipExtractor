import SwiftUI

struct BindingsSectionView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        GroupBox("Bound archive types") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), alignment: .leading)], alignment: .leading, spacing: 12) {
                ForEach(ArchiveFormat.allCases, id: \.self) { format in
                    Toggle(format.displayExtension, isOn: binding(for: format))
                }
            }
            .toggleStyle(.checkbox)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func binding(for format: ArchiveFormat) -> Binding<Bool> {
        Binding(
            get: {
                viewModel.isFormatEnabled(format)
            },
            set: { enabled in
                viewModel.setFormat(format, enabled: enabled)
            }
        )
    }
}
