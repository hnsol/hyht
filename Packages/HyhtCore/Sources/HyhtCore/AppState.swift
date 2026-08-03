import Foundation

/// The full persisted state of the app: the single countdown event, the
/// selected template, user style overrides, and completion-screen settings.
public struct AppState: Codable, Equatable, Sendable {
    /// Current schema version written by this build.
    public static let currentSchemaVersion = 1

    /// Schema version this instance was created/decoded with.
    public var schemaVersion: Int

    /// The countdown event.
    public var event: CountdownEvent

    /// Identifier of the currently selected `WidgetTemplate`.
    public var selectedTemplateID: String

    /// User style overrides layered on top of the selected template.
    public var overrides: StyleOverrides

    /// Completion-screen settings.
    public var completion: CompletionStyle

    public init(
        schemaVersion: Int,
        event: CountdownEvent,
        selectedTemplateID: String,
        overrides: StyleOverrides,
        completion: CompletionStyle
    ) {
        self.schemaVersion = schemaVersion
        self.event = event
        self.selectedTemplateID = selectedTemplateID
        self.overrides = overrides
        self.completion = completion
    }

    /// Builds a fresh default `AppState`.
    ///
    /// - Parameters:
    ///   - now: The current instant, used to compute a default deadline.
    ///   - timeZone: The device's current time zone, captured on the
    ///     `CountdownEvent` at creation time.
    public static func makeDefault(now: Date, timeZone: TimeZone) -> AppState {
        let defaultDeadline = now.addingTimeInterval(30 * 24 * 60 * 60)
        let event = CountdownEvent(
            name: "Countdown",
            emoji: "⏳",
            deadline: defaultDeadline,
            timeZoneID: timeZone.identifier
        )
        let completion = CompletionStyle(
            message: "Complete!",
            emoji: "🎉"
        )
        return AppState(
            schemaVersion: currentSchemaVersion,
            event: event,
            selectedTemplateID: "minimal",
            overrides: .none,
            completion: completion
        )
    }
}
