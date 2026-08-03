import SwiftUI

/// `systemMedium` layout: two fixed lines, not `WidgetElementsStack` (unlike
/// `systemSmall`). The first line is the emoji plus event name, shown at the
/// same font size; the second line is the primary value plus unit, with the
/// unit smaller and baseline-aligned to the value.
///
/// `style.elementOrder` is **not** used here: the two-line arrangement is
/// fixed regardless of the configured element order (see the plan's "対象外"
/// section -- customizing element order for medium is explicitly out of
/// scope). `style.alignment` instead controls where each line sits within
/// the widget's full width.
struct MediumWidgetLayout: View {
    let eventName: String
    let eventEmoji: String
    let snapshot: CountdownSnapshot
    let style: ResolvedWidgetStyle
    let palette: RenderPalette

    private var hasEventName: Bool {
        !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: style.alignment.horizontalAlignment, spacing: style.spacing) {
            if style.showsEmoji || (style.showsEventName && hasEventName) {
                headerLine
            }
            valueLine
        }
        .padding(.horizontal, style.spacing)
        .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
    }

    private var headerLine: some View {
        HStack(spacing: style.spacing / 2) {
            if style.showsEmoji {
                Text(eventEmoji)
                    .font(.system(size: style.emojiFontSize))
            }
            if style.showsEventName, hasEventName {
                Text(eventName)
                    .font(.system(size: style.eventNameFontSize, weight: style.fontWeight.swiftUIWeight, design: style.fontDesign.swiftUIDesign))
                    .foregroundColor(palette.primaryColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
    }

    private var valueLine: some View {
        HStack(alignment: .lastTextBaseline, spacing: style.spacing / 2) {
            Text(snapshot.primaryText)
                .font(.system(size: style.primaryValueFontSize, weight: style.fontWeight.swiftUIWeight, design: style.fontDesign.swiftUIDesign))
                .foregroundColor(palette.primaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .truncationMode(.tail)
            if style.showsUnit, let unit = CountdownUnitFormatter.unitLabel(for: snapshot.mode, style: .long) {
                Text(unit)
                    .font(.system(size: style.eventNameFontSize, weight: .regular, design: style.fontDesign.swiftUIDesign))
                    .foregroundColor(palette.secondaryColor)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
    }
}
