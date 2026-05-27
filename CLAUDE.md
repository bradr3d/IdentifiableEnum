# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build the package
swift build

# Run all tests
swift test

# Run a single test (by filter)
swift test --filter <TestName>

# Run the client executable
swift run IdentifiableEnumV2Client
```

## Architecture

This is a Swift Package Manager macro package with three targets:

- **`IdentifiableEnumV2Macros`** (`Sources/IdentifiableEnumV2Macros/`) — The compiler plugin target containing macro implementations. Uses `SwiftSyntax`, `SwiftSyntaxMacros`, and `SwiftSyntaxBuilder`. This is where macro expansion logic lives. Registered via `@main` on `IdentifiableEnumV2Plugin: CompilerPlugin`.

- **`IdentifiableEnumV2`** (`Sources/IdentifiableEnumV2/`) — The public library target that declares the macro APIs (using `@freestanding`, `@attached`, etc.) and links them to their implementations via `#externalMacro(module:type:)`. This is what downstream consumers import.

- **`IdentifiableEnumV2Client`** (`Sources/IdentifiableEnumV2Client/`) — An executable used to manually test/demonstrate macro usage. Not a test target; use `swift run IdentifiableEnumV2Client` to exercise it.

**Dependency:** `swift-syntax` (swiftlang/swift-syntax, `602.0.0-latest`), which provides `SwiftSyntaxMacros`, `SwiftSyntaxBuilder`, and `SwiftCompilerPlugin`.

**Pattern for adding a new macro:**
1. Declare the macro signature in `Sources/IdentifiableEnumV2/IdentifiableEnumV2.swift` using `#externalMacro`.
2. Implement the macro struct conforming to the appropriate protocol (e.g., `MemberMacro`, `ExtensionMacro`) in `Sources/IdentifiableEnumV2Macros/IdentifiableEnumV2Macro.swift`.
3. Register the new type in `IdentifiableEnumV2Plugin.providingMacros`.

**Platform targets:** macOS 10.15+, iOS 13+, tvOS 13+, watchOS 6+, macCatalyst 13+. Swift tools version 6.2.
