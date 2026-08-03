import HyhtCore
import SwiftUI

/// Font size, alignment, and per-family alignment overrides, plus a way to
/// reset all of them back to the selected template's own values.
struct DetailSettingsView: View {
    @ObservedObject var viewModel: EditViewModel
    @State private var showsResetConfirmation = false

    private static let fontSizeRange: ClosedRange<Double> = 8...96

    var body: some View {
        Form {
            Section("Font Sizes") {
                fontSizeRow(
                    titleKey: "Primary Value",
                    keyPath: \.primaryValueFontSize,
                    templateDefault: viewModel.selectedTemplate.style.primaryValueFontSize
                )
                fontSizeRow(
                    titleKey: "Event Name",
                    keyPath: \.eventNameFontSize,
                    templateDefault: viewModel.selectedTemplate.style.eventNameFontSize
                )
                fontSizeRow(
                    titleKey: "Emoji",
                    keyPath: \.emojiFontSize,
                    templateDefault: viewModel.selectedTemplate.style.emojiFontSize
                )
            }

            Section("Alignment") {
                AlignmentOverridePicker(
                    titleKey: "Alignment",
                    selection: $viewModel.appState.overrides.alignment
                )
            }

            Section {
                ForEach(WidgetFamilyKey.allCases.filter { $0 != .accessoryCircular && $0 != .accessoryRectangular }, id: \.self) { family in
                    AlignmentOverridePicker(
                        titleKey: family.localizedLabel,
                        selection: Binding(
                            get: { viewModel.appState.overrides.familyAlignmentOverrides[family] },
                            set: { viewModel.appState.overrides.familyAlignmentOverrides[family] = $0 }
                        )
                    )
                }
            } header: {
                Text("Alignment by Size")
            } footer: {
                Text("Overrides the alignment above for a specific widget size. Leave as Template Default to follow it.")
            }

            Section {
                Button(role: .destructive) {
                    showsResetConfirmation = true
                } label: {
                    Text("Reset to Template Defaults")
                }
            }
        }
        .navigationTitle("Detail Settings")
        .confirmationDialog(
            "Reset all detail settings to the template's defaults?",
            isPresented: $showsResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                viewModel.resetOverrides()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func fontSizeRow(
        titleKey: LocalizedStringKey,
        keyPath: WritableKeyPath<StyleOverrides, Double?>,
        templateDefault: Double
    ) -> some View {
        let isOverridden = viewModel.appState.overrides[keyPath: keyPath] != nil
        let binding = Binding<Double>(
            get: {
                let value = viewModel.appState.overrides[keyPath: keyPath] ?? templateDefault
                return min(max(value, Self.fontSizeRange.lowerBound), Self.fontSizeRange.upperBound)
            },
            set: { viewModel.appState.overrides[keyPath: keyPath] = $0 }
        )
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(titleKey)
                Spacer()
                Text("\(Int(binding.wrappedValue))pt")
                    .foregroundStyle(.secondary)
                if !isOverridden {
                    Text("Template Default")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Slider(value: binding, in: Self.fontSizeRange, step: 1)
        }
    }
}
