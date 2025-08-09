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
