import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct IdentifiableEnumMacro: MemberMacro, ExtensionMacro {

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(EnumDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: node,
                message: MacroExpansionErrorMessage("@IdentifiableEnum can only be applied to enums")
            ))
            return []
        }
        // If ExtensionMacro will error, don't add the member either — it would be an
        // orphaned property with no Identifiable conformance, which is more confusing.
        guard canGenerateExtension(for: declaration, context: context) else { return [] }
        let access = accessModifier(for: declaration)
        return ["\(raw: access)var id: Self { self }"]
    }

    // MARK: - ExtensionMacro

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(EnumDeclSyntax.self) else { return [] }

        if isInsideFunction(context: context) {
            context.diagnose(Diagnostic(
                node: node,
                message: MacroExpansionErrorMessage(
                    "@IdentifiableEnum cannot be applied to a local enum — " +
                    "extensions cannot be generated for types defined inside functions"
                )
            ))
            return []
        }

        if isPrivateNested(declaration: declaration, context: context) {
            context.diagnose(Diagnostic(
                node: node,
                message: MacroExpansionErrorMessage(
                    "@IdentifiableEnum cannot be applied to a private nested enum — " +
                    "a file-scope extension cannot reference a private member; " +
                    "use 'fileprivate' or higher, or add 'Identifiable' conformance manually"
                )
            ))
            return []
        }

        // Swift already passes the fully-qualified type to `type` (e.g. "Container.State"
        // for a nested enum), so no manual qualification is needed.
        return [try ExtensionDeclSyntax("extension \(type): Identifiable {}")]
    }

    // MARK: - Predicates

    private static func canGenerateExtension(
        for declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) -> Bool {
        !isInsideFunction(context: context) &&
        !isPrivateNested(declaration: declaration, context: context)
    }

    /// True when the macro is expanded inside a function, initializer, or closure —
    /// local types cannot be referenced from file-scope extensions.
    private static func isInsideFunction(context: some MacroExpansionContext) -> Bool {
        context.lexicalContext.contains {
            $0.is(FunctionDeclSyntax.self) ||
            $0.is(InitializerDeclSyntax.self) ||
            $0.is(ClosureExprSyntax.self)
        }
    }

    /// True when the enum is declared `private` inside another type.
    /// A file-scope extension cannot see a `private` member of an enclosing type.
    private static func isPrivateNested(
        declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) -> Bool {
        let insideType = context.lexicalContext.contains {
            $0.is(StructDeclSyntax.self) ||
            $0.is(ClassDeclSyntax.self)  ||
            $0.is(EnumDeclSyntax.self)   ||
            $0.is(ActorDeclSyntax.self)
        }
        guard insideType else { return false }
        return declaration.modifiers.contains { $0.name.text == "private" }
    }

    // MARK: - Helpers

    /// Returns the access-level keyword (with trailing space) to use for the synthesized
    /// `id` member, falling back to an empty string for implicit `internal`.
    ///
    /// `private` is promoted to `fileprivate` for top-level enums: the conformance extension
    /// is injected at file scope, so `id` must be at least `fileprivate` to satisfy it.
    private static func accessModifier(for declaration: some DeclGroupSyntax) -> String {
        let accessKeywords: Set<String> = [
            "public", "package", "open", "internal", "fileprivate", "private"
        ]
        for modifier in declaration.modifiers {
            let text = modifier.name.text
            if accessKeywords.contains(text) {
                if text == "internal" { return "" }
                if text == "private"  { return "fileprivate " }
                return text + " "
            }
        }
        return ""
    }
}

@main
struct IdentifiableEnumV2Plugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        IdentifiableEnumMacro.self,
    ]
}
