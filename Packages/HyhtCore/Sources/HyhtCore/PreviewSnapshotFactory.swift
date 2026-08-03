import Foundation

/// Builds an editable preview state independently from the saved deadline's
/// completion state. An active preview with an expired deadline uses a stable
/// representative countdown so the completed toggle remains authoritative.
public enum PreviewSnapshotFactory {
    public static let representativeInterval: TimeInterval = 30 * 24 * 60 * 60

    public static func snapshot(
        deadline: Date,
        now: Date,
        isCompleted: Bool,
        policy: CountdownModePolicy = .fallback
    ) -> CountdownSnapshot {
        let previewDeadline: Date
        if isCompleted {
            previewDeadline = now.addingTimeInterval(-1)
        } else if deadline > now {
            previewDeadline = deadline
        } else {
            previewDeadline = now.addingTimeInterval(representativeInterval)
        }

        return CountdownCalculator.snapshot(
            deadline: previewDeadline,
            now: now,
            policy: policy
        )
    }
}
