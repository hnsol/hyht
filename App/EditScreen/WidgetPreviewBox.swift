import HyhtCore
import SwiftUI

/// Frames `content` at a size/corner-shape approximating the real widget
/// footprint for `family`, so in-app previews read like the actual widget.
struct WidgetPreviewBox<Content: View>: View {
    let family: WidgetFamilyKey
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(width: size.width, height: size.height)
            .clipShape(shape)
    }

    private var size: CGSize {
        switch family {
        case .systemSmall:
            return CGSize(width: 158, height: 158)
        case .systemMedium:
            return CGSize(width: 338, height: 158)
        case .accessoryCircular:
            return CGSize(width: 72, height: 72)
        case .accessoryRectangular:
            return CGSize(width: 160, height: 72)
        }
    }

    private var shape: AnyShape {
        switch family {
        case .accessoryCircular:
            return AnyShape(Circle())
        case .systemSmall, .systemMedium:
            return AnyShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        case .accessoryRectangular:
            return AnyShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
