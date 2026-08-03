import SwiftUI

/// Renders `style.elementOrder` as a vertical stack, honoring each
/// element's show/hide flag. Used by `SmallWidgetLayout` only:
/// `MediumWidgetLayout` uses a fixed two-block horizontal split instead and
/// does not consult `style.elementOrder`.
struct WidgetElementsStack: View {
    let eventName: String
    let eventEmoji: String
    let snapshot: CountdownSnapshot
    let style: ResolvedWidgetStyle
    let palette: RenderPalette

    var body: some View {
        VStack(alignment: style.alignment.horizontalAlignment, spacing: style.spacing) {
            ForEach(Array(style.elementOrder.enumerated()), id: \.offset) { _, kind in
                element(for: kind)
            }
        }
    }

    @ViewBuilder
    private func element(for kind: ElementKind) -> some View {
        switch kind {
        case .eventName:
            if style.showsEventName, !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(eventName)
                    .font(.system(size: style.eventNameFontSize, weight: style.fontWeight.swiftUIWeight, design: style.fontDesign.swiftUIDesign))
                    .foregroundColor(palette.primaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .truncationMode(.tail)
            }
        case .emoji:
            if style.showsEmoji {
                Text(eventEmoji)
                    .font(.system(size: style.emojiFontSize))
            }
        case .primaryValue:
            Text(snapshot.primaryText)
                .font(.system(size: style.primaryValueFontSize, weight: style.fontWeight.swiftUIWeight, design: style.fontDesign.swiftUIDesign))
                .foregroundColor(palette.primaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .truncationMode(.tail)
        case .unit:
            // `WidgetElementsStack` is used only by `SmallWidgetLayout`
            // (`systemSmall`), a home-screen family, so the long unit form
            // is always correct here.
            if style.showsUnit, let unit = CountdownUnitFormatter.unitLabel(for: snapshot.mode, style: .long) {
                Text(unit)
                    .font(.system(size: style.eventNameFontSize, weight: .regular, design: style.fontDesign.swiftUIDesign))
                    .foregroundColor(palette.secondaryColor)
                    .lineLimit(1)
            }
        }
    }
}
