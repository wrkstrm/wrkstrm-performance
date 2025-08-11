import Benchmark
import Foundation
import WrkstrmPerformance

let benchmarks: @Sendable () -> Void = {
  Benchmark("RecordPreciseMeasurement") { _ in
    for _ in 0..<100 {
      let start = uptimeNanoseconds()
      TimeMonitor.recordPreciseMeasurement(name: "bench", start: start, end: start)
    }
  }

  Benchmark("MeasureAverageExecutionTime") { _ in
    _ = await TimeMonitor.measureAverageExecutionTime(name: "noop", iterations: 10) {
      blackHole(1)
    }
  }
}

let timeMonitorBenchmarks = BenchmarkSuite(name: "TimeMonitorBenchmarks") { suite in
  suite.benchmarkAsync("measureAverageExecutionTime") { _ in
    _ = try? await TimeMonitor.measureAverageExecutionTime(
      name: "noop",
      iterations: 10
    ) {
      for _ in 0..<1000 {
        _ = 1 + 1
      }
    }
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
