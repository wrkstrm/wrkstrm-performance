#if canImport(Benchmark)
import Benchmark

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

/// Utility wrapper for running benchmarks with simple APIs.
/// Accepts a `Benchmark.Configuration` and returns captured metric results.
public enum BenchmarkMonitor {
  /// Runs the provided closure as a benchmark and returns results keyed by metric.
  /// Only a subset of metrics are currently supported.
  /// - Parameters:
  ///   - name: Name of the benchmark.
  ///   - configuration: Configuration describing metrics and limits.
  ///   - body: Closure containing the work to benchmark.
  /// - Returns: Dictionary mapping each requested metric to its `BenchmarkResult`.
  @discardableResult
  public static func measure(
    _ name: String,
    configuration: Benchmark.Configuration,
    _ body: @escaping (_ benchmark: Benchmark) -> Void
  ) -> [BenchmarkMetric: BenchmarkResult] {
    guard let benchmark = Benchmark(name, configuration: configuration, closure: { _ in }) else {
      return [:]
    }

    var startUsage = rusage()
    getrusage(RUSAGE_SELF, &startUsage)
    let start = uptimeNanoseconds()

    body(benchmark)

    let end = uptimeNanoseconds()
    var endUsage = rusage()
    getrusage(RUSAGE_SELF, &endUsage)

    var results: [BenchmarkMetric: BenchmarkResult] = [:]

    for metric in configuration.metrics {
      switch metric {
      case .wallClock:
        let stats = Statistics()
        stats.add(Int(end - start))
        results[metric] = BenchmarkResult(
          metric: metric,
          timeUnits: .nanoseconds,
          scalingFactor: configuration.scalingFactor,
          warmupIterations: configuration.warmupIterations,
          thresholds: configuration.thresholds?[metric],
          tags: configuration.tags,
          statistics: stats
        )
      case .cpuSystem:
        let startNS =
          Double(startUsage.ru_stime.tv_sec) * 1_000_000_000 + Double(startUsage.ru_stime.tv_usec)
          * 1000
        let endNS =
          Double(endUsage.ru_stime.tv_sec) * 1_000_000_000 + Double(endUsage.ru_stime.tv_usec)
          * 1000
        let stats = Statistics()
        stats.add(Int(endNS - startNS))
        results[metric] = BenchmarkResult(
          metric: metric,
          timeUnits: .nanoseconds,
          scalingFactor: configuration.scalingFactor,
          warmupIterations: configuration.warmupIterations,
          thresholds: configuration.thresholds?[metric],
          tags: configuration.tags,
          statistics: stats
        )
      case .peakMemoryResident:
        #if canImport(Glibc)
        // On Linux, ru_maxrss is in kilobytes, so multiply by 1024
        let memBytes = Int(endUsage.ru_maxrss) * 1024
        #elseif canImport(Darwin)
        // On macOS, ru_maxrss is in bytes, so use as-is
        let memBytes = Int(endUsage.ru_maxrss)
        #else
        let memBytes = Int(endUsage.ru_maxrss)  // Fallback: assume bytes
        #endif
        let stats = Statistics(units: .count)
        stats.add(memBytes)
        results[metric] = BenchmarkResult(
          metric: metric,
          timeUnits: .nanoseconds,
          scalingFactor: configuration.scalingFactor,
          warmupIterations: configuration.warmupIterations,
          thresholds: configuration.thresholds?[metric],
          tags: configuration.tags,
          statistics: stats
        )
      default:
        continue
      }
    }

    return results
  }

  /// Convenience overload where the closure does not require the `Benchmark` parameter.
  @discardableResult
  public static func measure(
    _ name: String,
    configuration: Benchmark.Configuration,
    _ body: @escaping () -> Void
  ) -> [BenchmarkMetric: BenchmarkResult] {
    measure(name, configuration: configuration) { _ in body() }
  }
}
#endif
