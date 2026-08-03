import Foundation

/// Access point for `HyhtCore`'s bundled resources.
///
/// `Bundle.module` is generated with `internal` visibility, so anything outside
/// the module (including other targets that need to read the authoritative
/// JSON resources) goes through here.
public enum HyhtCoreResources {
    /// The bundle holding `HyhtCore`'s processed resources.
    public static var bundle: Bundle { .module }

    /// File name of the authoritative `CountdownModePolicy` definition.
    public static let modePolicyResourceName = "mode-policy"

    /// File name of the Node.js-generated `Number.prototype.toFixed` fixture.
    public static let toFixedFixtureResourceName = "tofixed-fixture"

    /// File names (without extension) of the built-in template resources,
    /// in display order.
    public static let builtinTemplateResourceNames = [
        "template-minimal",
        "template-bold",
        "template-soft"
    ]

    /// Reads a bundled JSON resource, returning `nil` when it is missing or
    /// unreadable.
    public static func jsonData(named name: String, subdirectory: String? = nil) -> Data? {
        guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: subdirectory) else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
}
