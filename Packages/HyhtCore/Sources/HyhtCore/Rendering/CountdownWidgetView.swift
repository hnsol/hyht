import SwiftUI
import WidgetKit

/// The single SwiftUI entry point used to render a countdown for a given
/// widget family, shared verbatim by the in-app preview and the real
/// `HyhtWidget` extension (added in a later phase).
///
/// This view never calls `containerBackground(for:)` itself -- that is the
/// widget extension's responsibility once it exists, since it is only
/// valid inside an actual `Widget`'s view hierarchy. In `.widget` context
/// this view never self-paints a background for *any* family, home-screen
/// or accessory: the widget extension's `containerBackground` already
/// covers the full, correctly-rounded footprint, and painting again here
/// (inset by `style.padding`) produced a visibly misaligned rectangle over
/// the system background. In `.preview` context (the in-app editor, which
/// cannot use `containerBackground`) this view self-paints from `style` so
/// home-screen families remain visible while editing; accessory families
/// still paint only a monochrome approximation there.
public struct CountdownWidgetView: View {
    private let snapshot: CountdownSnapshot
    private let eventName: String
    private let eventEmoji: String
    private let style: ResolvedWidgetStyle
    private let family: WidgetFamilyKey
    private let renderingContext: RenderingContext

    public init(
        snapshot: CountdownSnapshot,
        eventName: String,
        eventEmoji: String,
        style: ResolvedWidgetStyle,
        family: WidgetFamilyKey,
        renderingContext: RenderingContext
    ) {
        self.snapshot = snapshot
        self.eventName = eventName
        self.eventEmoji = eventEmoji
        self.style = style
        self.family = family
        self.renderingContext = renderingContext
    }

    public var body: some View {
        ZStack {
            if renderingContext == .preview, let backgroundColor = palette.backgroundColor {
                backgroundColor
            }
            familyContent
                .padding(style.padding)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .modifier(AccessoryAccentable(family: family))
        // Widget content is drawn at a fixed footprint (both the real
        // widget and the in-app preview reuse this exact view). WidgetKit
        // itself does not scale widget text with Dynamic Type, so pinning
        // this to `.large` keeps the app preview's layout identical to what
        // actually renders on the Home/Lock Screen regardless of the
        // system's text size setting.
        .dynamicTypeSize(.large)
    }

    // MARK: - Content

    @ViewBuilder
    private var familyContent: some View {
        if snapshot.mode == .done {
            CompletionLayoutView(eventName: eventName, style: style, palette: palette, family: family)
        } else {
            switch family {
            case .systemSmall:
                SmallWidgetLayout(eventName: eventName, eventEmoji: eventEmoji, snapshot: snapshot, style: style, palette: palette)
            case .systemMedium:
                MediumWidgetLayout(eventName: eventName, eventEmoji: eventEmoji, snapshot: snapshot, style: style, palette: palette)
            case .accessoryCircular:
                AccessoryCircularLayout(snapshot: snapshot, style: style, palette: palette)
            case .accessoryRectangular:
                AccessoryRectangularLayout(eventName: eventName, eventEmoji: eventEmoji, snapshot: snapshot, style: style, palette: palette)
            }
        }
    }

    private var palette: RenderPalette {
        switch family {
        case .systemSmall, .systemMedium:
            return .forHomeFamily(style: style)
        case .accessoryCircular, .accessoryRectangular:
            return .forAccessoryFamily(renderingContext: renderingContext)
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        CountdownAccessibility.label(
            snapshot: snapshot,
            eventName: eventName,
            completionMessage: style.completionMessage
        )
    }
}

/// Applies `widgetAccentable()` to accessory families only, in both
/// rendering contexts. It is a no-op outside of an actual widget rendering
/// pass, so applying it during `.preview` is harmless.
private struct AccessoryAccentable: ViewModifier {
    let family: WidgetFamilyKey

    func body(content: Content) -> some View {
        switch family {
        case .accessoryCircular, .accessoryRectangular:
            content.widgetAccentable()
        case .systemSmall, .systemMedium:
            content
        }
    }
}

// MARK: - Previews

#if DEBUG
private enum CountdownWidgetViewPreviewData {
    static let deadline = Date(timeIntervalSinceNow: 3 * 24 * 60 * 60 + 5 * 60 * 60)
    static let now = Date()
    static let eventName = "Grandma's 100th Birthday Party"
    static let eventEmoji = "🎉"
    static let template = TemplateStore.minimalTemplate()

    static func snapshot(mode: CountdownDisplayMode) -> CountdownSnapshot {
        switch mode {
        case .done:
            return CountdownCalculator.snapshot(deadline: now.addingTimeInterval(-60), now: now)
        case .week:
            return CountdownCalculator.snapshot(deadline: now.addingTimeInterval(20 * 24 * 60 * 60), now: now)
        case .day:
            return CountdownCalculator.snapshot(deadline: now.addingTimeInterval(3 * 24 * 60 * 60), now: now)
        case .hour:
            return CountdownCalculator.snapshot(deadline: now.addingTimeInterval(30 * 60 * 60), now: now)
        case .clock:
            return CountdownCalculator.snapshot(deadline: now.addingTimeInterval(90 * 60), now: now)
        case .min:
            return CountdownCalculator.snapshot(deadline: now.addingTimeInterval(45), now: now)
        }
    }

    static func style(family: WidgetFamilyKey, isCompleted: Bool) -> ResolvedWidgetStyle {
        StyleResolver.resolve(
            template: template,
            overrides: .none,
            completion: nil,
            family: family,
            isCompleted: isCompleted
        )
    }
}

#Preview("Small - Day") {
    CountdownWidgetView(
        snapshot: CountdownWidgetViewPreviewData.snapshot(mode: .day),
        eventName: CountdownWidgetViewPreviewData.eventName,
        eventEmoji: CountdownWidgetViewPreviewData.eventEmoji,
        style: CountdownWidgetViewPreviewData.style(family: .systemSmall, isCompleted: false),
        family: .systemSmall,
        renderingContext: .preview
    )
    .frame(width: 158, height: 158)
}

#Preview("Small - Done") {
    CountdownWidgetView(
        snapshot: CountdownWidgetViewPreviewData.snapshot(mode: .done),
        eventName: CountdownWidgetViewPreviewData.eventName,
        eventEmoji: CountdownWidgetViewPreviewData.eventEmoji,
        style: CountdownWidgetViewPreviewData.style(family: .systemSmall, isCompleted: true),
        family: .systemSmall,
        renderingContext: .preview
    )
    .frame(width: 158, height: 158)
}

#Preview("Medium - Week") {
    CountdownWidgetView(
        snapshot: CountdownWidgetViewPreviewData.snapshot(mode: .week),
        eventName: CountdownWidgetViewPreviewData.eventName,
        eventEmoji: CountdownWidgetViewPreviewData.eventEmoji,
        style: CountdownWidgetViewPreviewData.style(family: .systemMedium, isCompleted: false),
        family: .systemMedium,
        renderingContext: .preview
    )
    .frame(width: 338, height: 158)
}

#Preview("Medium - Done") {
    CountdownWidgetView(
        snapshot: CountdownWidgetViewPreviewData.snapshot(mode: .done),
        eventName: CountdownWidgetViewPreviewData.eventName,
        eventEmoji: CountdownWidgetViewPreviewData.eventEmoji,
        style: CountdownWidgetViewPreviewData.style(family: .systemMedium, isCompleted: true),
        family: .systemMedium,
        renderingContext: .preview
    )
    .frame(width: 338, height: 158)
}

#Preview("Circular - Clock") {
    CountdownWidgetView(
        snapshot: CountdownWidgetViewPreviewData.snapshot(mode: .clock),
        eventName: CountdownWidgetViewPreviewData.eventName,
        eventEmoji: CountdownWidgetViewPreviewData.eventEmoji,
        style: CountdownWidgetViewPreviewData.style(family: .accessoryCircular, isCompleted: false),
        family: .accessoryCircular,
        renderingContext: .preview
    )
    .frame(width: 76, height: 76)
    .clipShape(Circle())
}

#Preview("Circular - Done") {
    CountdownWidgetView(
        snapshot: CountdownWidgetViewPreviewData.snapshot(mode: .done),
        eventName: CountdownWidgetViewPreviewData.eventName,
        eventEmoji: CountdownWidgetViewPreviewData.eventEmoji,
        style: CountdownWidgetViewPreviewData.style(family: .accessoryCircular, isCompleted: true),
        family: .accessoryCircular,
        renderingContext: .preview
    )
    .frame(width: 76, height: 76)
    .clipShape(Circle())
}

#Preview("Rectangular - Min") {
    CountdownWidgetView(
        snapshot: CountdownWidgetViewPreviewData.snapshot(mode: .min),
        eventName: CountdownWidgetViewPreviewData.eventName,
        eventEmoji: CountdownWidgetViewPreviewData.eventEmoji,
        style: CountdownWidgetViewPreviewData.style(family: .accessoryRectangular, isCompleted: false),
        family: .accessoryRectangular,
        renderingContext: .preview
    )
    .frame(width: 172, height: 76)
}

#Preview("Rectangular - Done") {
    CountdownWidgetView(
        snapshot: CountdownWidgetViewPreviewData.snapshot(mode: .done),
        eventName: CountdownWidgetViewPreviewData.eventName,
        eventEmoji: CountdownWidgetViewPreviewData.eventEmoji,
        style: CountdownWidgetViewPreviewData.style(family: .accessoryRectangular, isCompleted: true),
        family: .accessoryRectangular,
        renderingContext: .preview
    )
    .frame(width: 172, height: 76)
}
#endif
