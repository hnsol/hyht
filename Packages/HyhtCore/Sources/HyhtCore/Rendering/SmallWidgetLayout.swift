import SwiftUI

/// `systemSmall` layout: `style.elementOrder` stacked vertically, filling
/// the available width. The event name (if shown) is a single truncating
/// line; the primary value is the largest element per its style font size.
struct SmallWidgetLayout: View {
    let eventName: String
    let eventEmoji: String
    let snapshot: CountdownSnapshot
    let style: ResolvedWidgetStyle
    let palette: RenderPalette

    var body: some View {
        WidgetElementsStack(
            eventName: eventName,
            eventEmoji: eventEmoji,
            snapshot: snapshot,
            style: style,
            palette: palette
        )
        .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
    }
}
