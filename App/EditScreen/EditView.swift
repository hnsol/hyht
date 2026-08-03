import HyhtCore
import SwiftUI

/// The app's single screen: a live preview plus the basic editing form.
/// Detail/completion settings are pushed via `NavigationLink`.
struct EditView: View {
    @StateObject private var viewModel = EditViewModel()
    @State private var previewFamily: WidgetFamilyKey = .systemSmall
    @State private var previewCompleted = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .loading:
                    ProgressView()
                case .unknownNewerVersion:
                    unknownVersionView
                case .containerUnavailable(let message):
                    containerUnavailableView(message)
                case .ready:
                    editForm
                }
            }
            .navigationTitle("Hyht")
        }
        .task {
            await viewModel.start()
        }
        .onChange(of: viewModel.appState) { _, _ in
            viewModel.stateChanged()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                Task { await viewModel.flush() }
            }
        }
    }

    // MARK: - Ready state

    private var editForm: some View {
        Form {
            Section {
                PreviewSectionView(
                    eventName: viewModel.effectiveEventName,
                    eventEmoji: viewModel.appState.event.emoji,
                    deadline: viewModel.appState.event.deadline,
                    template: viewModel.selectedTemplate,
                    overrides: viewModel.appState.overrides,
                    completion: viewModel.appState.completion,
                    family: $previewFamily,
                    isCompleted: $previewCompleted
                )
            }

            Section("Event") {
                TextField("Event Name", text: $viewModel.appState.event.name)
                EmojiField(titleKey: "Emoji", text: $viewModel.appState.event.emoji)
                DatePicker(
                    "Deadline",
                    selection: $viewModel.appState.event.deadline,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .environment(\.timeZone, eventTimeZone)
            }

            Section("Template") {
                TemplatePickerView(
                    templates: viewModel.templates,
                    selectedID: $viewModel.appState.selectedTemplateID,
                    eventName: viewModel.effectiveEventName,
                    eventEmoji: viewModel.appState.event.emoji,
                    deadline: viewModel.appState.event.deadline
                )
            }

            Section {
                ColorPicker(
                    "Background",
                    selection: colorBinding(\.backgroundColorHex, templateDefault: viewModel.selectedTemplate.style.backgroundColorHex)
                )
                ColorPicker(
                    "Primary Text",
                    selection: colorBinding(\.primaryTextColorHex, templateDefault: viewModel.selectedTemplate.style.primaryTextColorHex)
                )
                ColorPicker(
                    "Secondary Text",
                    selection: colorBinding(\.secondaryTextColorHex, templateDefault: viewModel.selectedTemplate.style.secondaryTextColorHex)
                )
            } header: {
                Text("Colors")
            } footer: {
                Text("Colors apply to the Home Screen only.")
            }

            Section {
                saveStatusView
            }

            Section {
                NavigationLink("Detail Settings") {
                    DetailSettingsView(viewModel: viewModel)
                }
                NavigationLink("Completion Screen") {
                    CompletionSettingsView(viewModel: viewModel)
                }
            }
        }
    }

    private var eventTimeZone: TimeZone {
        TimeZone(identifier: viewModel.appState.event.timeZoneID) ?? .current
    }

    private func colorBinding(
        _ keyPath: WritableKeyPath<StyleOverrides, String?>,
        templateDefault: String
    ) -> Binding<Color> {
        Binding(
            get: {
                Color(hyhtHex: viewModel.appState.overrides[keyPath: keyPath] ?? templateDefault)
            },
            set: { newColor in
                viewModel.appState.overrides[keyPath: keyPath] = newColor.hyhtHexString
            }
        )
    }

    @ViewBuilder
    private var saveStatusView: some View {
        switch viewModel.saveStatus {
        case .idle:
            EmptyView()
        case .saving:
            Label("Saving...", systemImage: "arrow.triangle.2.circlepath")
                .foregroundStyle(.secondary)
        case .saved:
            Label("Saved", systemImage: "checkmark.circle")
                .foregroundStyle(.secondary)
        case .failed(let message):
            Label("Save failed: \(message)", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }

    // MARK: - Non-ready states

    private var unknownVersionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("This data was created with a newer version of the app.")
                .multilineTextAlignment(.center)
                .font(.headline)
            Text("Editing is disabled to avoid losing your data. Update the app to continue editing.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func containerUnavailableView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Couldn't load your data.")
                .font(.headline)
            Text(message)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    EditView()
}
