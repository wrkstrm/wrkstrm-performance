import Benchmark
import WrkstrmPerformance
import Foundation

let timeMonitorBenchmarks = BenchmarkSuite(name: "TimeMonitorBenchmarks") { suite in
  suite.benchmark("measureAverageExecutionTime") { _ in
    let group = DispatchGroup()
    group.enter()
    Task {
      _ = try? await TimeMonitor.measureAverageExecutionTime(
        name: "noop",
        iterations: 10
      ) {
        for _ in 0..<1000 {
          _ = 1 + 1
        }
      }
      group.leave()
    }
    group.wait()
  }

  suite.benchmark("manualLoop") { _ in
    let iterations = 10
    var total: UInt64 = 0
    for _ in 0..<iterations {
      let start = uptimeNanoseconds()
      for _ in 0..<1000 {
        _ = 1 + 1
      }
      total += uptimeNanoseconds() - start
    }
    _ = Double(total) / Double(iterations) / 1_000_000_000
  }
}

Benchmark.main([timeMonitorBenchmarks])
