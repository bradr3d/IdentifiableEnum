import IdentifiableEnumV2

// Top-level enums
@IdentifiableEnum public enum Direction  { case north, south, east, west }
@IdentifiableEnum        enum Season     { case spring, summer, autumn, winter }
@IdentifiableEnum private enum Mode     { case light, dark }

// Nested enums (non-private — extension uses fully-qualified name at file scope)
public struct Container {
    @IdentifiableEnum public   enum PublicState    { case on, off }
    @IdentifiableEnum          enum InternalState  { case on, off }
    @IdentifiableEnum fileprivate enum FileState   { case on, off }
}

// Doubly-nested
public struct Outer {
    public struct Inner {
        @IdentifiableEnum public enum State { case a, b }
    }
}

print(Direction.north.id)               // north
print(Season.summer.id)                 // summer
print(Mode.dark.id)                     // dark

print(Container.PublicState.on.id)      // on
print(Container.InternalState.on.id)    // on
print(Container.FileState.on.id)        // on

print(Outer.Inner.State.a.id)           // a
