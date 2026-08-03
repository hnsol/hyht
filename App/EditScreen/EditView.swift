import HyhtCore
import SwiftUI

/// The app's single screen: a fixed live preview plus a compact editing form.
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
                    editScreen
                }
            }
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

    private var editScreen: some View {
        VStack(spacing: 0) {
            fixedPreview
            Divider()

            Form {
                if previewCompleted {
                    Section("Completion") {
                        TextField("Display Text", text: $viewModel.appState.completion.message)
                        EmojiField(titleKey: "Emoji", text: $viewModel.appState.completion.emoji)
                        deadlinePicker
                    }
                } else {
                    Section("Event") {
                        TextField("Event Name", text: $viewModel.appState.event.name)
                        EmojiField(titleKey: "Emoji", text: $viewModel.appState.event.emoji)
                        deadlinePicker
                    }
                }

                Section {
                    TemplatePickerView(
                        templates: viewModel.templates,
                        selectedID: $viewModel.appState.selectedTemplateID,
                        eventName: viewModel.effectiveEventName,
                        eventEmoji: viewModel.appState.event.emoji,
                        deadline: viewModel.appState.event.deadline,
                        completion: viewModel.appState.completion,
                        isCompleted: previewCompleted
                    )
                } header: {
                    Text("Template")
                } footer: {
                    saveStatusView
                }
            }
        }
    }

    private var fixedPreview: some View {
        VStack(spacing: 8) {
            Text(verbatim: "Hyht［hyçt］ 希望。喜びを伴う期待、歓喜。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .leading)

            PreviewSectionView(
                eventName: viewModel.effectiveEventName,
                eventEmoji: viewModel.appState.event.emoji,
                deadline: viewModel.appState.event.deadline,
                template: viewModel.selectedTemplate,
                completion: viewModel.appState.completion,
                family: $previewFamily,
                isCompleted: $previewCompleted
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private var deadlinePicker: some View {
        DatePicker(
            "Deadline",
            selection: $viewModel.appState.event.deadline,
            displayedComponents: [.date, .hourAndMinute]
        )
        .environment(\.timeZone, eventTimeZone)
    }

    private var eventTimeZone: TimeZone {
        TimeZone(identifier: viewModel.appState.event.timeZoneID) ?? .current
    }

    @ViewBuilder
    private var saveStatusView: some View {
        switch viewModel.saveStatus {
        case .idle, .saving, .saved:
            EmptyView()
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
