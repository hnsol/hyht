import HyhtCore
import SwiftUI

/// A picker choice representing either "use the template's own alignment"
/// (`nil` in the underlying override) or an explicit alignment override.
enum AlignmentChoice: Hashable {
    case templateDefault
    case value(WidgetFamilyDefinition.Alignment)

    init(_ alignment: WidgetFamilyDefinition.Alignment?) {
        self = alignment.map(AlignmentChoice.value) ?? .templateDefault
    }

    var alignment: WidgetFamilyDefinition.Alignment? {
        if case .value(let alignment) = self { return alignment }
        return nil
    }

    var label: LocalizedStringKey {
        switch self {
        case .templateDefault: return "Template Default"
        case .value(.leading): return "Leading"
        case .value(.center): return "Center"
        case .value(.trailing): return "Trailing"
        }
    }

    static let allChoices: [AlignmentChoice] = [
        .templateDefault, .value(.leading), .value(.center), .value(.trailing)
    ]
}

/// A `Picker` over `AlignmentChoice`, bound directly to an optional
/// `WidgetFamilyDefinition.Alignment` override.
struct AlignmentOverridePicker: View {
    let titleKey: LocalizedStringKey
    @Binding var selection: WidgetFamilyDefinition.Alignment?

    var body: some View {
        Picker(titleKey, selection: Binding(
            get: { AlignmentChoice(selection) },
            set: { selection = $0.alignment }
        )) {
            ForEach(AlignmentChoice.allChoices, id: \.self) { choice in
                Text(choice.label).tag(choice)
            }
        }
    }
}
