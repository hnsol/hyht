import Foundation

/// Loads and looks up `HyhtCore`'s built-in `WidgetTemplate`s.
///
/// The authoritative copies are version-stamped JSON resources bundled with
/// `HyhtCore`. Any missing resource, decode failure, or validation failure
/// falls back to the `minimal` template; if `minimal` itself is unusable,
/// ``WidgetTemplate/fallback`` (a hard-coded, in-code definition) is used as
/// the final line of defense. Loading built-in templates must never crash.
public enum TemplateStore {
    /// Loads every built-in template that decodes and validates
    /// successfully, in ``HyhtCoreResources/builtinTemplateResourceNames``
    /// order. A resource that is missing, malformed, or invalid is silently
    /// skipped rather than causing a crash.
    public static func loadBuiltinTemplates() -> [WidgetTemplate] {
        HyhtCoreResources.builtinTemplateResourceNames.compactMap(loadTemplate(resourceName:))
    }

    /// Looks up a built-in template by `id`. Falls back to the `minimal`
    /// template when `id` is unknown or when the matching resource fails to
    /// load/validate.
    public static func template(id: String) -> WidgetTemplate {
        loadBuiltinTemplates().first { $0.id == id } ?? minimalTemplate()
    }

    /// The `minimal` built-in template, loaded from its bundled JSON.
    /// Falls back to ``WidgetTemplate/fallback`` if the `minimal` resource
    /// itself is missing or fails validation.
    public static func minimalTemplate() -> WidgetTemplate {
        loadTemplate(resourceName: "template-minimal") ?? WidgetTemplate.fallback
    }

    // MARK: - Private

    private static func loadTemplate(resourceName: String) -> WidgetTemplate? {
        guard let data = HyhtCoreResources.jsonData(named: resourceName) else { return nil }
        return decodeTemplate(from: data)
    }

    /// Decodes and validates a template from raw JSON. Exposed so that
    /// corrupt-input behaviour is testable independently of the bundled
    /// resources.
    static func decodeTemplate(from data: Data) -> WidgetTemplate? {
        guard
            let decoded = try? AppStateCoding.decoder.decode(WidgetTemplate.self, from: data),
            decoded.isValid
        else { return nil }
        return decoded
    }
}
