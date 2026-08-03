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
    let overrides: StyleOverrides
    let completion: CompletionStyle

    @Binding var family: WidgetFamilyKey
    @Binding var isCompleted: Bool

    var body: some View {
        VStack(spacing: 12) {
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
            .frame(maxWidth: .infinity)

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
        if isCompleted {
            return CountdownCalculator.snapshot(deadline: Date().addingTimeInterval(-60), now: Date())
        }
        return CountdownCalculator.snapshot(deadline: deadline, now: Date())
    }

    // The deadline may already be in the past, in which case the snapshot is
    // .done regardless of the preview toggle; the style must resolve the
    // completion values or the completion layout would render empty.
    private var effectiveCompleted: Bool {
        isCompleted || snapshot.mode == .done
    }

    private var style: ResolvedWidgetStyle {
        StyleResolver.resolve(
            template: template,
            overrides: overrides,
            completion: completion,
            family: family,
            isCompleted: effectiveCompleted
        )
    }
}
