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
    let completion: CompletionStyle
    let isCompleted: Bool

    private let previewSize: CGFloat = 92

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
        let snapshot = PreviewSnapshotFactory.snapshot(
            deadline: deadline,
            now: Date(),
            isCompleted: isCompleted
        )
        let style = StyleResolver.resolveTemplateDriven(
            template: template,
            completion: completion,
            family: .systemSmall,
            isCompleted: isCompleted
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
                .frame(width: 158, height: 158)
                .scaleEffect(previewSize / 158)
                .frame(width: previewSize, height: previewSize)
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
