import SwiftUI

/// `accessoryRectangular` layout: at most two lines. The first line is the
/// emoji/event name (each shown only per its style flag); the second is the
/// primary value plus unit.
///
/// Design decision: like `AccessoryCircularLayout`, this uses small fixed
/// font sizes rather than `style`'s home-screen-tuned sizes.
struct AccessoryRectangularLayout: View {
    let eventName: String
    let eventEmoji: String
    let snapshot: CountdownSnapshot
    let style: ResolvedWidgetStyle
    let palette: RenderPalette

    private static let labelFontSize: CGFloat = 12
    private static let valueFontSize: CGFloat = 20
    private static let unitFontSize: CGFloat = 12

    private var hasEventName: Bool {
        !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: style.alignment.horizontalAlignment, spacing: 2) {
            if style.showsEmoji || (style.showsEventName && hasEventName) {
                HStack(spacing: 4) {
                    if style.showsEmoji {
                        Text(eventEmoji)
                            .font(.system(size: Self.labelFontSize))
                    }
                    if style.showsEventName, hasEventName {
                        Text(eventName)
                            .font(.system(size: Self.labelFontSize, design: style.fontDesign.swiftUIDesign))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
            }

            HStack(spacing: 4) {
                Text(snapshot.primaryText)
                    .font(.system(size: Self.valueFontSize, weight: .semibold, design: style.fontDesign.swiftUIDesign))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if style.showsUnit, let unit = CountdownUnitFormatter.unitLabel(for: snapshot.mode, style: .short) {
                    Text(unit)
                        .font(.system(size: Self.unitFontSize, design: style.fontDesign.swiftUIDesign))
                }
            }
            .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
        }
        .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
        .foregroundColor(palette.primaryColor)
    }
}
