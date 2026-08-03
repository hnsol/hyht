import HyhtCore
import SwiftUI

/// The always-visible preview at the top of the edit screen: renders the
/// same `CountdownWidgetView` used by the real widget, with controls to
/// switch the previewed family and toggle the completed state.
struct PreviewSectionView: View {
    let eventName: String
    let eventEmoji: String
    let deadline: Date
    let template: WidgetTemplate
    let completion: CompletionStyle

    @Binding var family: WidgetFamilyKey
    @Binding var isCompleted: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                WidgetPreviewBox(family: family) {
                    CountdownWidgetView(
                        snapshot: snapshot,
                        eventName: eventName,
                        eventEmoji: eventEmoji,
                        style: style,
                        family: family,
                        renderingContext: .preview
                    )
                }
            }
            .frame(maxWidth: .infinity, minHeight: 158, maxHeight: 158)

            Picker("Size", selection: $family) {
                ForEach(WidgetFamilyKey.allCases.filter { $0 != .accessoryRectangular }, id: \.self) { family in
                    Text(family.localizedLabel).tag(family)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Toggle("Completed", isOn: $isCompleted)
        }
        .padding(.vertical, 4)
    }

    private var snapshot: CountdownSnapshot {
        PreviewSnapshotFactory.snapshot(
            deadline: deadline,
            now: Date(),
            isCompleted: isCompleted
        )
    }

    private var style: ResolvedWidgetStyle {
        StyleResolver.resolveTemplateDriven(
            template: template,
            completion: completion,
            family: family,
            isCompleted: isCompleted
        )
    }
}
