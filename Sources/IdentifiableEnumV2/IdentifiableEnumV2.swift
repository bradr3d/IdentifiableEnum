// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: named(id))
@attached(extension, conformances: Identifiable)
public macro IdentifiableEnum() = #externalMacro(module: "IdentifiableEnumV2Macros", type: "IdentifiableEnumMacro")
