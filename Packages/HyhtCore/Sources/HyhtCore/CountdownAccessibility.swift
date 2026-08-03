import Foundation

/// Builds the VoiceOver-read label for a countdown, as a distinct
/// natural-language sentence rather than a reuse of the on-screen display
/// string.
///
/// Every sentence names the unit and, where relevant, spells out the
/// deadline/completion state in words instead of the terse symbols
/// (`"wk"`, `"h"`, ...) used on screen. Locale is an explicit parameter
/// (defaulting to the current one) so both the app/widget can rely on the
/// system locale and tests can exercise every supported language
/// deterministically.
public enum CountdownAccessibility {
    /// The VoiceOver label for `snapshot`.
    ///
    /// - Parameters:
    ///   - snapshot: The countdown state to describe.
    ///   - eventName: The event's display name.
    ///   - completionMessage: The template/user completion message, used only
    ///     when `snapshot.mode == .done`. `nil` or blank is treated as "no
    ///     message".
    ///   - locale: The locale to render the sentence in. Defaults to the
    ///     current locale.
    public static func label(
        snapshot: CountdownSnapshot,
        eventName: String,
        completionMessage: String?,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let bundle = localizedBundle(for: locale)
        let trimmedName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasName = !trimmedName.isEmpty

        switch snapshot.mode {
        case .done:
            let message = completionMessage?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if hasName {
                if message.isEmpty {
                    let format = bundle.localizedString(forKey: "%1$@ is complete.", value: nil, table: nil)
                    return String(format: format, locale: locale, eventName)
                }
                let format = bundle.localizedString(forKey: "%1$@ is complete. %2$@", value: nil, table: nil)
                return String(format: format, locale: locale, eventName, message)
            }
            if message.isEmpty {
                return bundle.localizedString(forKey: "Complete.", value: nil, table: nil)
            }
            let format = bundle.localizedString(forKey: "Complete. %1$@", value: nil, table: nil)
            return String(format: format, locale: locale, message)

        case .week:
            if hasName {
                let format = bundle.localizedString(forKey: "%1$@ weeks until %2$@", value: nil, table: nil)
                return String(format: format, locale: locale, snapshot.primaryText, eventName)
            }
            let format = bundle.localizedString(forKey: "%1$@ weeks remaining", value: nil, table: nil)
            return String(format: format, locale: locale, snapshot.primaryText)

        case .day:
            if hasName {
                let format = bundle.localizedString(forKey: "%1$@ days until %2$@", value: nil, table: nil)
                return String(format: format, locale: locale, snapshot.primaryText, eventName)
            }
            let format = bundle.localizedString(forKey: "%1$@ days remaining", value: nil, table: nil)
            return String(format: format, locale: locale, snapshot.primaryText)

        case .hour:
            if hasName {
                let format = bundle.localizedString(forKey: "%1$@ hours until %2$@", value: nil, table: nil)
                return String(format: format, locale: locale, snapshot.primaryText, eventName)
            }
            let format = bundle.localizedString(forKey: "%1$@ hours remaining", value: nil, table: nil)
            return String(format: format, locale: locale, snapshot.primaryText)

        case .clock:
            if hasName {
                let format = bundle.localizedString(forKey: "%1$@, %2$d hours %3$d minutes remaining", value: nil, table: nil)
                return String(format: format, locale: locale, eventName, snapshot.clockHour ?? 0, snapshot.clockMinute ?? 0)
            }
            let format = bundle.localizedString(forKey: "%1$d hours %2$d minutes remaining", value: nil, table: nil)
            return String(format: format, locale: locale, snapshot.clockHour ?? 0, snapshot.clockMinute ?? 0)

        case .min:
            if hasName {
                let format = bundle.localizedString(forKey: "%1$@, %2$@ minutes remaining", value: nil, table: nil)
                return String(format: format, locale: locale, eventName, snapshot.primaryText)
            }
            let format = bundle.localizedString(forKey: "%1$@ minutes remaining", value: nil, table: nil)
            return String(format: format, locale: locale, snapshot.primaryText)
        }
    }

    /// Resolves the bundle whose compiled string table matches `locale`'s
    /// language, falling back to `Bundle.module`'s own (development-language)
    /// table when no matching `.lproj` is bundled.
    private static func localizedBundle(for locale: Locale) -> Bundle {
        let languageCode = locale.language.languageCode?.identifier ?? "en"
        if let path = Bundle.module.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.module
    }
}
