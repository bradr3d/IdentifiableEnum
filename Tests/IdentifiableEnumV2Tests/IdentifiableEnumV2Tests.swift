import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import IdentifiableEnumV2Macros

private let testMacros: [String: Macro.Type] = [
    "IdentifiableEnum": IdentifiableEnumMacro.self,
]

final class IdentifiableEnumV2Tests: XCTestCase {

    // MARK: - Access levels

    func testPublicEnum() {
        assertMacroExpansion(
            """
            @IdentifiableEnum
            public enum Direction {
                case north, south, east, west
            }
            """,
            expandedSource: """
            public enum Direction {
                case north, south, east, west

                public var id: Self {
                    self
                }
            }

            extension Direction: Identifiable {
            }
            """,
            macros: testMacros
        )
    }

    func testInternalEnum() {
        assertMacroExpansion(
            """
            @IdentifiableEnum
            enum Season {
                case spring, summer, autumn, winter
            }
            """,
            expandedSource: """

            enum Season {
                case spring, summer, autumn, winter

                var id: Self {
                    self
                }
            }

            extension Season: Identifiable {
            }
            """,
            macros: testMacros
        )
    }

    func testFileprivateEnum() {
        assertMacroExpansion(
            """
            @IdentifiableEnum
            fileprivate enum Status {
                case active, inactive
            }
            """,
            expandedSource: """

            fileprivate enum Status {
                case active, inactive

                fileprivate var id: Self {
                    self
                }
            }

            extension Status: Identifiable {
            }
            """,
            macros: testMacros
        )
    }

    /// A top-level `private` enum is effectively file-private, so the extension at file scope
    /// is valid — but `id` must be `fileprivate` (not `private`) so the extension conformance
    /// check can see it.
    func testPrivateTopLevelEnum() {
        assertMacroExpansion(
            """
            @IdentifiableEnum
            private enum Mode {
                case light, dark
            }
            """,
            expandedSource: """

            private enum Mode {
                case light, dark

                fileprivate var id: Self {
                    self
                }
            }

            extension Mode: Identifiable {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Nested types

    func testPublicNestedEnum() {
        assertMacroExpansion(
            """
            public struct Container {
                @IdentifiableEnum
                public enum State {
                    case on, off
                }
            }
            """,
            expandedSource: """
            public struct Container {
                public enum State {
                    case on, off

                    public var id: Self {
                        self
                    }
                }
            }

            extension Container.State: Identifiable {
            }
            """,
            macros: testMacros
        )
    }

    func testInternalNestedEnum() {
        assertMacroExpansion(
            """
            struct Wrapper {
                @IdentifiableEnum
                enum Kind {
                    case a, b
                }
            }
            """,
            expandedSource: """
            struct Wrapper {
                enum Kind {
                    case a, b

                    var id: Self {
                        self
                    }
                }
            }

            extension Wrapper.Kind: Identifiable {
            }
            """,
            macros: testMacros
        )
    }

    func testDeeplyNestedEnum() {
        assertMacroExpansion(
            """
            public struct Outer {
                public struct Inner {
                    @IdentifiableEnum
                    public enum State {
                        case a, b
                    }
                }
            }
            """,
            expandedSource: """
            public struct Outer {
                public struct Inner {
                    public enum State {
                        case a, b

                        public var id: Self {
                            self
                        }
                    }
                }
            }

            extension Outer.Inner.State: Identifiable {
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - Diagnostics

    func testErrorOnPrivateNestedEnum() {
        assertMacroExpansion(
            """
            struct Container {
                @IdentifiableEnum
                private enum Hidden {
                    case a
                }
            }
            """,
            expandedSource: """
            struct Container {
                private enum Hidden {
                    case a
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@IdentifiableEnum cannot be applied to a private nested enum — " +
                             "a file-scope extension cannot reference a private member; " +
                             "use 'fileprivate' or higher, or add 'Identifiable' conformance manually",
                    line: 2,
                    column: 5
                )
            ],
            macros: testMacros
        )
    }

    func testErrorOnNonEnum() {
        assertMacroExpansion(
            """
            @IdentifiableEnum
            struct Foo {}
            """,
            expandedSource: """
            struct Foo {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@IdentifiableEnum can only be applied to enums",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    func testErrorOnLocalEnum() {
        assertMacroExpansion(
            """
            func doSomething() {
                @IdentifiableEnum
                enum Local {
                    case a, b
                }
            }
            """,
            expandedSource: """
            func doSomething() {
                enum Local {
                    case a, b
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@IdentifiableEnum cannot be applied to a local enum — " +
                             "extensions cannot be generated for types defined inside functions",
                    line: 2,
                    column: 5
                )
            ],
            macros: testMacros
        )
    }
}
