import HyhtCore
import SwiftUI

/// Editing UI for the completion ("done") screen: message, emoji, colors
/// (home-screen only), font sizes, alignment, and a fixed-completed preview.
struct CompletionSettingsView: View {
    @ObservedObject var viewModel: EditViewModel
    @State private var previewFamily: WidgetFamilyKey = .systemSmall

    private static let fontSizeRange: ClosedRange<Double> = 8...96

    var body: some View {
        Form {
            Section {
                WidgetPreviewBox(family: previewFamily) {
                    CountdownWidgetView(
                        snapshot: previewSnapshot,
                        eventName: viewModel.effectiveEventName,
                        eventEmoji: viewModel.appState.event.emoji,
                        style: previewStyle,
                        family: previewFamily,
                        renderingContext: .preview
                    )
                }
                .frame(maxWidth: .infinity)

                Picker("Size", selection: $previewFamily) {
                    ForEach(WidgetFamilyKey.allCases.filter { $0 != .accessoryRectangular }, id: \.self) { family in
                        Text(family.localizedLabel).tag(family)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Completion") {
                TextField("Completion Message", text: $viewModel.appState.completion.message)
                EmojiField(titleKey: "Completion Emoji", text: $viewModel.appState.completion.emoji)
            }

            Section {
                ColorPicker(
                    "Background",
                    selection: colorBinding(\.backgroundColorHex, templateDefault: viewModel.selectedTemplate.completion.backgroundColorHex ?? viewModel.selectedTemplate.style.backgroundColorHex)
                )
                ColorPicker(
                    "Primary Text",
                    selection: colorBinding(\.primaryTextColorHex, templateDefault: viewModel.selectedTemplate.completion.primaryTextColorHex ?? viewModel.selectedTemplate.style.primaryTextColorHex)
                )
                ColorPicker(
                    "Secondary Text",
                    selection: colorBinding(\.secondaryTextColorHex, templateDefault: viewModel.selectedTemplate.completion.secondaryTextColorHex ?? viewModel.selectedTemplate.style.secondaryTextColorHex)
                )
            } header: {
                Text("Colors")
            } footer: {
                Text("Colors apply to the Home Screen only.")
            }

            Section("Font Sizes") {
                fontSizeRow(
                    titleKey: "Event Name",
                    keyPath: \.eventNameFontSize,
                    templateDefault: viewModel.selectedTemplate.completion.eventNameFontSize ?? viewModel.selectedTemplate.style.eventNameFontSize
                )
                fontSizeRow(
                    titleKey: "Message",
                    keyPath: \.messageFontSize,
                    templateDefault: viewModel.selectedTemplate.completion.messageFontSize ?? viewModel.selectedTemplate.style.primaryValueFontSize
                )
                fontSizeRow(
                    titleKey: "Emoji",
                    keyPath: \.emojiFontSize,
                    templateDefault: viewModel.selectedTemplate.completion.emojiFontSize ?? viewModel.selectedTemplate.style.emojiFontSize
                )
            }

            Section {
                AlignmentOverridePicker(
                    titleKey: "Alignment",
                    selection: $viewModel.appState.completion.alignment
                )
            } header: {
                Text("Alignment")
            } footer: {
                Text("Lock Screen circular widgets always stay centered, regardless of this setting.")
            }
        }
        .navigationTitle("Completion Screen")
    }

    private var previewSnapshot: CountdownSnapshot {
        CountdownCalculator.snapshot(deadline: Date().addingTimeInterval(-60), now: Date())
    }

    private var previewStyle: ResolvedWidgetStyle {
        StyleResolver.resolve(
            template: viewModel.selectedTemplate,
            overrides: viewModel.appState.overrides,
            completion: viewModel.appState.completion,
            family: previewFamily,
            isCompleted: true
        )
    }

    private func colorBinding(
        _ keyPath: WritableKeyPath<CompletionStyle, String?>,
        templateDefault: String
    ) -> Binding<Color> {
        Binding(
            get: {
                Color(hyhtHex: viewModel.appState.completion[keyPath: keyPath] ?? templateDefault)
            },
            set: { newColor in
                viewModel.appState.completion[keyPath: keyPath] = newColor.hyhtHexString
            }
        )
    }

    @ViewBuilder
    private func fontSizeRow(
        titleKey: LocalizedStringKey,
        keyPath: WritableKeyPath<CompletionStyle, Double?>,
        templateDefault: Double
    ) -> some View {
        let isOverridden = viewModel.appState.completion[keyPath: keyPath] != nil
        let binding = Binding<Double>(
            get: {
                let value = viewModel.appState.completion[keyPath: keyPath] ?? templateDefault
                return min(max(value, Self.fontSizeRange.lowerBound), Self.fontSizeRange.upperBound)
            },
            set: { viewModel.appState.completion[keyPath: keyPath] = $0 }
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
