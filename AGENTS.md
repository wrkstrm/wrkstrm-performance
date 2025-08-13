# AGENTS — WrkstrmPerformance
[//]: # (Author & Architect: Rismay)

WrkstrmPerformance provides instrumentation utilities for timing and benchmarking Swift code.

## Goals
- Measure performance regressions and improvements across packages
- Surface timing metrics so agents can validate optimizations
- Expose simple start/stop APIs that integrate with XCTest
- Strive for time and space efficiency, pulling in as few resources as possible

## Future Goals
- Investigate structure packing to minimize instrumentation overhead

## Usage
- Add `WrkstrmPerformance` as a dependency in `Package.swift`
- Wrap critical code with timing helpers to record durations
- Compare metrics before and after changes to quantify impact


- Always declare Swift object types instead of relying on inference. Explicit types speed builds and development.

### Swift initializer shorthand

When the variable’s type is known, Swift lets you use the `.init` shorthand.
These two lines are equivalent:

```swift
let split = UISplitViewController(style: .doubleColumn)       // type inferred
let split: UISplitViewController = .init(style: .doubleColumn) // explicit type + .init shorthand
```

In both cases, the `style: .doubleColumn` initializer sets up the split view
controller with the double-column layout introduced in iOS 14. The `.init`
style works only when the compiler can already determine the variable’s type.
