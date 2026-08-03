import SwiftUI

/// A `TextField` restricted to a single grapheme cluster, used for the
/// event/completion emoji fields. Input beyond the first character is
/// truncated to that first character.
struct EmojiField: View {
    let titleKey: LocalizedStringKey
    @Binding var text: String

    var body: some View {
        TextField(titleKey, text: Binding(
            get: { text },
            set: { newValue in text = String(newValue.prefix(1)) }
        ))
        .multilineTextAlignment(.center)
    }
}
