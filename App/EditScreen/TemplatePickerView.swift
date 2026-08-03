import HyhtCore
import SwiftUI

/// Horizontally-scrolling template cards, each showing a small live preview
/// (`CountdownWidgetView` at the `systemSmall` family) so the user can see
/// what a template looks like before selecting it.
struct TemplatePickerView: View {
    let templates: [WidgetTemplate]
    @Binding var selectedID: String
    let eventName: String
    let eventEmoji: String
    let deadline: Date

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(templates, id: \.id) { template in
                    card(for: template)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func card(for template: WidgetTemplate) -> some View {
        let isSelected = template.id == selectedID
        let snapshot = CountdownCalculator.snapshot(deadline: deadline, now: Date())
        let style = StyleResolver.resolve(
            template: template,
            overrides: .none,
            completion: nil,
            family: .systemSmall,
            isCompleted: snapshot.mode == .done
        )
        return Button {
            selectedID = template.id
        } label: {
            VStack(spacing: 6) {
                CountdownWidgetView(
                    snapshot: snapshot,
                    eventName: eventName,
                    eventEmoji: eventEmoji,
                    style: style,
                    family: .systemSmall,
                    renderingContext: .preview
                )
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text(template.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .lineLimit(1)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
