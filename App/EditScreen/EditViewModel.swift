import Combine
import HyhtCore
import SwiftUI
import WidgetKit

/// Drives the app's single edit screen: owns the loaded `AppState`, forwards
/// edits to a `SaveCoordinator`, and reflects load/save status back to the
/// view.
@MainActor
final class EditViewModel: ObservableObject {
    enum LoadState: Equatable {
        case loading
        case ready
        case unknownNewerVersion(foundVersion: Int)
        case containerUnavailable(message: String)
    }

    /// The edited state. Mutating this and calling `stateChanged()` is how
    /// every editing control in the app persists a change.
    @Published var appState: AppState = AppState.makeDefault(now: Date(), timeZone: .current)

    @Published private(set) var loadState: LoadState = .loading
    @Published private(set) var saveStatus: SaveCoordinator.SaveStatus = .idle

    /// The built-in templates available for selection, loaded once.
    let templates: [WidgetTemplate] = TemplateStore.loadBuiltinTemplates()

    private var repository: (any CountdownRepository)?
    private var saveCoordinator: SaveCoordinator?
    private var statusCancellable: AnyCancellable?

    /// Whether editing controls should be enabled.
    var isEditingEnabled: Bool { loadState == .ready }

    /// The event name to render in previews/widgets: simply the edited name,
    /// as-is. An empty/whitespace-only name is rendered as no name at all
    /// (the rendering layer skips the element/line), matching the actual
    /// widget's behavior with the same stored value.
    var effectiveEventName: String {
        appState.event.name
    }

    /// The currently selected template, falling back to Minimal when the
    /// stored ID doesn't match a loaded built-in template.
    var selectedTemplate: WidgetTemplate {
        TemplateStore.template(id: appState.selectedTemplateID)
    }

    /// Loads persisted state and wires up the save coordinator. Call once
    /// from the root view's `.task`.
    func start() async {
        do {
            let repo = try AppGroupCountdownRepository.makeForAppGroup()
            repository = repo
            let result = await repo.load()
            switch result {
            case .loaded(let state):
                applyLoaded(state, repo: repo)
            case .recoveredFromCorruption(let state):
                applyLoaded(state, repo: repo)
            case .emptyInitialized(let state):
                applyLoaded(state, repo: repo)
            case .unknownNewerVersion(let foundVersion):
                loadState = .unknownNewerVersion(foundVersion: foundVersion)
            }
        } catch {
            loadState = .containerUnavailable(message: error.localizedDescription)
        }
    }

    private func applyLoaded(_ state: AppState, repo: any CountdownRepository) {
        appState = state
        let coordinator = SaveCoordinator(
            repository: repo,
            reloadWidgets: {
                WidgetCenter.shared.reloadTimelines(ofKind: HyhtCore.widgetKind)
            },
            initialSavedState: state
        )
        saveCoordinator = coordinator
        statusCancellable = coordinator.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.saveStatus = status
            }
        loadState = .ready
    }

    /// Notifies the save coordinator that `appState` changed. The event
    /// name is saved exactly as typed, including empty/whitespace-only: the
    /// rendering layer treats a blank name as "no name" rather than this
    /// view model substituting a default.
    func stateChanged(affectsWidget: Bool = true) {
        guard isEditingEnabled else { return }
        saveCoordinator?.stateChanged(appState, affectsWidget: affectsWidget)
    }

    /// Flushes any pending debounced save immediately. Call on
    /// `scenePhase` changes away from `.active`.
    func flush() async {
        await saveCoordinator?.flush()
    }

    /// Resets all user style overrides (colors, font sizes, alignment) back
    /// to the selected template's own values.
    func resetOverrides() {
        appState.overrides = .none
        stateChanged()
    }
}
