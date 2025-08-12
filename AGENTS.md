# AGENTS — WrkstrmPerformance
> Author & Architect: Rismay

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

