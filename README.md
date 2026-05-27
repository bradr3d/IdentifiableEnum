# IdentifiableEnum

A Swift macro that makes any enum `Identifiable` with a single annotation — no boilerplate required.

## What it does

`@IdentifiableEnum` synthesizes `var id: Self { self }` and adds an `Identifiable` conformance, so your enum can be used directly in `ForEach`, `List`, `Picker`, and anywhere else Swift expects an `Identifiable` type.

```swift
// Before
enum Direction: Identifiable {
    case north, south, east, west
    var id: Self { self }
}

// After
@IdentifiableEnum
enum Direction {
    case north, south, east, west
}
```

## Installation

Add the package in Xcode via **File → Add Package Dependencies**:

```
https://github.com/bradr3d/IdentifiableEnum
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bradr3d/IdentifiableEnum", from: "1.0.0")
],
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "IdentifiableEnumV2", package: "IdentifiableEnum")
    ])
]
```

## Usage

### Basic enum

```swift
import IdentifiableEnumV2

@IdentifiableEnum
enum Tab {
    case home, search, settings
}

// Works directly in ForEach
ForEach(Tab.allCases) { tab in
    TabView(tab)
}
```

### With associated access levels

The synthesized `id` property mirrors the enum's access level:

```swift
@IdentifiableEnum public  enum Status  { case active, inactive }
@IdentifiableEnum         enum Filter  { case all, unread }       // internal
@IdentifiableEnum private enum Mode    { case light, dark }       // → fileprivate id
```

### Nested enums

Works at any nesting depth — the conformance extension is generated with the fully-qualified type name:

```swift
struct FeedView {
    @IdentifiableEnum
    enum SortOrder { case newest, oldest, relevance }

    @IdentifiableEnum
    enum Layout { case list, grid, magazine }
}

Picker("Sort", selection: $sortOrder) {
    ForEach(FeedView.SortOrder.allCases) { order in
        Text(order.rawValue).tag(order)
    }
}
```

### With `RawRepresentable`

Pairs naturally with `String` or `Int` raw values:

```swift
@IdentifiableEnum
enum Priority: String, CaseIterable {
    case low, medium, high
}

ForEach(Priority.allCases) { priority in
    Label(priority.rawValue.capitalized, systemImage: "flag")
}
```

## Limitations

- **Local enums** (declared inside a function or closure) are not supported — Swift cannot generate file-scope extensions for local types.
- **Private nested enums** are not supported — `private` members of an enclosing type are invisible at file scope. Use `fileprivate` or higher instead.
