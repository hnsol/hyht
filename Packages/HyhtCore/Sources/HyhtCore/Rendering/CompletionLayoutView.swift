import SwiftUI

/// Completion ("done") layout, shared across all four families. Uses
/// `style.completionMessage`/`completionEmoji`/`messageFontSize`, with a
/// per-family arrangement simple enough not to break at any size.
struct CompletionLayoutView: View {
    let eventName: String
    let style: ResolvedWidgetStyle
    let palette: RenderPalette
    let family: WidgetFamilyKey

    private var hasEventName: Bool {
        !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        switch family {
        case .systemSmall:
            homeLayout(spacing: style.spacing)
                .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
        case .systemMedium:
            homeLayout(spacing: style.spacing)
                .padding(.horizontal, style.spacing)
                .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
        case .accessoryCircular:
            circularLayout
        case .accessoryRectangular:
            rectangularLayout
        }
    }

    // MARK: - Home families

    private func homeLayout(spacing: Double) -> some View {
        VStack(alignment: style.alignment.horizontalAlignment, spacing: spacing) {
            if style.showsEmoji, let emoji = style.completionEmoji {
                Text(emoji)
                    .font(.system(size: style.emojiFontSize))
            }
            Text(style.completionMessage ?? "")
                .font(.system(size: style.messageFontSize ?? style.primaryValueFontSize, weight: style.fontWeight.swiftUIWeight, design: style.fontDesign.swiftUIDesign))
                .foregroundColor(palette.primaryColor)
                .multilineTextAlignment(textAlignment)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
            if style.showsEventName, hasEventName {
                Text(eventName)
                    .font(.system(size: style.eventNameFontSize, design: style.fontDesign.swiftUIDesign))
                    .foregroundColor(palette.secondaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .truncationMode(.tail)
            }
        }
    }

    private var textAlignment: TextAlignment {
        switch style.alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    // MARK: - Accessory families

    private var circularLayout: some View {
        VStack(spacing: 0) {
            Text(style.completionEmoji ?? "\u{2713}")
                .font(.system(size: 16))
            Text(style.completionMessage ?? "")
                .font(.system(size: 10))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .foregroundColor(palette.primaryColor)
    }

    private var rectangularLayout: some View {
        VStack(alignment: style.alignment.horizontalAlignment, spacing: 2) {
            HStack(spacing: 4) {
                if let emoji = style.completionEmoji {
                    Text(emoji)
                        .font(.system(size: 12))
                }
                if style.showsEventName, hasEventName {
                    Text(eventName)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
            Text(style.completionMessage ?? "")
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
        }
        .frame(maxWidth: .infinity, alignment: style.alignment.frameAlignment)
        .foregroundColor(palette.primaryColor)
    }
}
