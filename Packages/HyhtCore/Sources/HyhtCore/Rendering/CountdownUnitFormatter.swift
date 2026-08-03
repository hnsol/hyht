import Foundation

/// Selects the unit label shown next to a countdown's primary value.
public enum CountdownUnitFormatter {
    /// The style of unit label to produce: `short` abbreviations for
    /// space-constrained lock-screen accessories, `long` words for the
    /// roomier home-screen widget families.
    public enum UnitLabelStyle {
        case short
        case long
    }

    /// The unit label for `mode` in the given `style`, or `nil` when the
    /// mode has no separate unit label.
    ///
    /// `clock` has no separate unit: its `"H:mm"` primary text (or the
    /// circular layout's two-line `{h}h` / `{m}m` form) already bakes the
    /// unit into the value itself. `done` has no numeric value at all.
    /// Whether the label is actually shown is a further decision left to
    /// the caller (`ResolvedWidgetStyle.showsUnit`).
    ///
    /// No singular/plural switching is performed: `long` always uses the
    /// plural word (e.g. "1.00 weeks").
    public static func unitLabel(for mode: CountdownDisplayMode, style: UnitLabelStyle) -> String? {
        switch style {
        case .short:
            return shortUnitLabel(for: mode)
        case .long:
            return longUnitLabel(for: mode)
        }
    }

    private static func shortUnitLabel(for mode: CountdownDisplayMode) -> String? {
        switch mode {
        case .week: return "wk"
        case .day: return "d"
        case .hour: return "h"
        case .clock: return nil
        case .min: return "m"
        case .done: return nil
        }
    }

    private static func longUnitLabel(for mode: CountdownDisplayMode) -> String? {
        switch mode {
        case .week: return "weeks"
        case .day: return "days"
        case .hour: return "hours"
        case .clock: return nil
        case .min: return "min"
        case .done: return nil
        }
    }
}
