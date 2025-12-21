#if canImport(Benchmark)
import Benchmark
import Testing

@testable import WrkstrmPerformance

@Test
func benchmarkMonitorCapturesMetrics() {
  let configuration = Benchmark.Configuration(
    metrics: [
      .peakMemoryResident,
      .cpuSystem,
      .cpuUser,
      .cpuTotal,
      .threads,
      .instructions,
    ],
    warmupIterations: 0,
    maxIterations: 1,
  )

  let results = BenchmarkMonitor.measure("allocation", configuration: configuration) {
    var array: [Int] = []
    for i in 0..<10000 {
      array.append(i)
    }
    blackHole(array.count)
  }

  #expect(results[.peakMemoryResident] != nil)
  #if canImport(Darwin)
  #expect((results[.cpuSystem]?.statistics.average ?? 0) > 0)
  #expect((results[.cpuUser]?.statistics.average ?? 0) > 0)
  #expect((results[.cpuTotal]?.statistics.average ?? 0) > 0)
  #expect((results[.threads]?.statistics.average ?? 0) >= 1)
  #expect((results[.instructions]?.statistics.average ?? 0) > 0)
  #else
  #expect((results[.cpuSystem]?.statistics.average ?? 0) > 0)
  #expect((results[.cpuUser]?.statistics.average ?? 0) > 0)
  #expect((results[.cpuTotal]?.statistics.average ?? 0) > 0)
  #expect(results[.threads] == nil)
  #expect(results[.instructions] == nil)
  #endif
}
#endif
