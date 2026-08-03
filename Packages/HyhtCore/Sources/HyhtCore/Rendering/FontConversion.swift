import SwiftUI

extension TemplateFontWeight {
    /// This weight as a SwiftUI `Font.Weight`.
    public var swiftUIWeight: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
}

extension TemplateFontDesign {
    /// This design as a SwiftUI `Font.Design`.
    public var swiftUIDesign: Font.Design {
        switch self {
        case .default: return .default
        case .rounded: return .rounded
        case .serif: return .serif
        case .monospaced: return .monospaced
        }
    }
}

extension WidgetFamilyDefinition.Alignment {
    /// This alignment as a SwiftUI `HorizontalAlignment`, for use inside a
    /// `VStack`.
    public var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    /// This alignment as a SwiftUI `Alignment`, for use with `.frame(...)`.
    public var frameAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}
