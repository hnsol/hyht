import HyhtCore
import SwiftUI

extension WidgetFamilyKey {
    /// Localized, human-readable label for this family, used throughout the
    /// edit screen's size pickers.
    var localizedLabel: LocalizedStringKey {
        switch self {
        case .systemSmall:
            return "Home Small"
        case .systemMedium:
            return "Home Medium"
        case .accessoryCircular:
            return "Lock Circular"
        case .accessoryRectangular:
            return "Lock Rectangular"
        }
    }
}
