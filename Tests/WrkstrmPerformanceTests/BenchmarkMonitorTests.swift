#if canImport(Benchmark)
  import Benchmark
  import Testing

  @testable import WrkstrmPerformance

  @Test
  func benchmarkMonitorCapturesMetrics() {
    let configuration = Benchmark.Configuration(
      metrics: [.peakMemoryResident, .cpuSystem],
      warmupIterations: 0,
      maxIterations: 1
    )

    let results = BenchmarkMonitor.measure("allocation", configuration: configuration) {
      var array: [Int] = []
      for i in 0..<10_000 { array.append(i) }
      blackHole(array.count)
    }

    #expect(results[.peakMemoryResident] != nil)
    #expect(results[.cpuSystem] != nil)
  }
#endif
