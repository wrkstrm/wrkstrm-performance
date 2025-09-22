# PerfRunner — Lightweight Timing Helpers

WrkstrmPerformance provides minimal, closure‑based timing utilities for quick measurements that are
portable across packages and tooling layers. These are the single source of truth for duration and
iteration loops.

## APIs

```swift
public enum PerfRunner {
  public static func iterations(
    _ count: Int,
    targetHz: Double? = nil,
    body: @Sendable () async throws -> Void
  ) async rethrows -> (iterations: Int, totalMS: Double, averageMS: Double)

  public static func duration(
    seconds: Double,
    targetHz: Double? = nil,
    body: @Sendable () async throws -> Void
  ) async rethrows -> (iterations: Int, totalMS: Double, averageMS: Double)
}
```

- ``iterations``: run the body a fixed number of times; reports total and average ms.
- ``duration``: run the body until the time budget elapses; reports the number of iterations and
  total/average ms.
- ``targetHz``: optional pacing hint (simple sleep‑based pacing after each body run).

## Using with CommonShell

If you want to measure process invocations via CommonShell without coupling the core target to
WrkstrmPerformance, depend on the opt‑in **CommonShellPerf** library (shipped with the CommonShell
package) and use its extensions:

```swift
import CommonShell
import CommonShellPerf
import CommonProcess

let shell = CommonShell(executable: .path("/usr/bin/env"))
let (iterations, total, avg) = try await shell.perfForInterval(
  host: .env(options: []), executable: .name("echo"), arguments: ["bench"],
  durationSeconds: 0.25, targetHz: 144
)
```

Under the hood, `CommonShellPerf` delegates to `WrkstrmPerformance.PerfRunner` to do timing, while
`CommonShell` itself avoids importing this package.

## Using directly (no processes)

```swift
let res = try await PerfRunner.iterations(1_000) {
  _ = (0..<100).reduce(0,+)
}
print(res.iterations, res.averageMS)
```

## See also

- CommonShellPerf README for usage with execution hosts and executables.
- common-cli-perf for a JSON‑driven perf harness that uses `CommonShellPerf`.
