import WidgetKit
import SwiftUI
import HyhtCore

// MARK: - Entry

/// One rendered instant of the countdown.
///
/// The entry carries everything the view needs to draw itself without
/// touching the file system again: the pre-computed `CountdownSnapshot` for
/// `date` plus the selected template and completion content read once per
/// timeline.
/// Style resolution itself happens in the view, because the concrete widget
/// family is only known there.
struct HyhtEntry: TimelineEntry {
    let date: Date
    let snapshot: CountdownSnapshot
    let eventName: String
    let eventEmoji: String
    let template: WidgetTemplate
    let completion: CompletionStyle
}

// MARK: - Provider

struct HyhtProvider: TimelineProvider {
    func placeholder(in context: Context) -> HyhtEntry {
        let now = Date()
        return makeEntry(at: now, state: defaultState(now: now), policy: .fallback)
    }

    func getSnapshot(in context: Context, completion: @escaping (HyhtEntry) -> Void) {
        let now = Date()
        completion(makeEntry(at: now, state: loadState(now: now), policy: CountdownModePolicy.loadBundled()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HyhtEntry>) -> Void) {
        let now = Date()
        let state = loadState(now: now)
        let modePolicy = CountdownModePolicy.loadBundled()

        let plan = TimelinePlanner.plan(
            deadline: state.event.deadline,
            now: now,
            policy: modePolicy
        )
        let entries = plan.entryDates.map { makeEntry(at: $0, state: state, policy: modePolicy) }

        completion(Timeline(entries: entries, policy: reloadPolicy(for: plan)))
    }

    // MARK: - State

    /// Widgets are read-only: `WidgetStateReader` never writes, and any
    /// missing/corrupt/newer-schema state falls back to a safe default
    /// display without touching the file.
    private func loadState(now: Date) -> AppState {
        WidgetStateReader.read() ?? defaultState(now: now)
    }

    private func defaultState(now: Date) -> AppState {
        AppState.makeDefault(now: now, timeZone: .current)
    }

    // MARK: - Entry construction

    private func makeEntry(at date: Date, state: AppState, policy: CountdownModePolicy) -> HyhtEntry {
        HyhtEntry(
            date: date,
            snapshot: CountdownCalculator.snapshot(
                deadline: state.event.deadline,
                now: date,
                policy: policy
            ),
            eventName: state.event.name,
            eventEmoji: state.event.emoji,
            template: TemplateStore.template(id: state.selectedTemplateID),
            completion: state.completion
        )
    }

    /// Maps `HyhtCore`'s planning policy onto WidgetKit's identically named
    /// `TimelineReloadPolicy` (the return type is module-qualified because
    /// both names are in scope here).
    private func reloadPolicy(for plan: TimelinePlan) -> WidgetKit.TimelineReloadPolicy {
        switch plan.policy {
        case .atEnd: return .atEnd
        case .never: return .never
        }
    }
}

// MARK: - View

struct HyhtWidgetEntryView: View {
    @Environment(\.widgetFamily) private var widgetFamily

    var entry: HyhtEntry

    var body: some View {
        CountdownWidgetView(
            snapshot: entry.snapshot,
            eventName: entry.eventName,
            eventEmoji: entry.eventEmoji,
            style: style,
            family: familyKey,
            renderingContext: .widget
        )
        .widgetURL(HyhtCore.editDeepLinkURL)
        .containerBackground(for: .widget) {
            containerBackground
        }
    }

    private var familyKey: WidgetFamilyKey {
        WidgetFamilyKey(widgetFamily: widgetFamily)
    }

    private var isCompleted: Bool {
        entry.snapshot.mode == .done
    }

    private var style: ResolvedWidgetStyle {
        StyleResolver.resolveTemplateDriven(
            template: entry.template,
            completion: entry.completion,
            family: familyKey,
            isCompleted: isCompleted
        )
    }

    /// Home-screen families paint the resolved style color; accessory
    /// families stay transparent so the OS owns lock-screen chrome and
    /// tinting.
    @ViewBuilder
    private var containerBackground: some View {
        switch familyKey {
        case .systemSmall, .systemMedium:
            WidgetColor.color(fromHex: style.backgroundColorHex, fallback: Color(white: 1))
        case .accessoryCircular, .accessoryRectangular:
            Color.clear
        }
    }
}

// MARK: - Family bridging

extension WidgetFamilyKey {
    /// Maps WidgetKit's family to the template's family key. Families the
    /// widget does not declare in `supportedFamilies` cannot occur; they map
    /// to `systemSmall` so this stays total.
    init(widgetFamily: WidgetFamily) {
        switch widgetFamily {
        case .systemSmall: self = .systemSmall
        case .systemMedium: self = .systemMedium
        case .accessoryCircular: self = .accessoryCircular
        case .accessoryRectangular: self = .accessoryRectangular
        default: self = .systemSmall
        }
    }
}

// MARK: - Widget

struct HyhtWidget: Widget {
    let kind: String = HyhtCore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HyhtProvider()) { entry in
            HyhtWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Hyht")
        .description("Counts down to your event.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}
