#if canImport(Benchmark)
import Benchmark

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif
import Dispatch

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
    let startSnapshot = captureUsageSnapshot()
    let start = uptimeNanoseconds()

    body(benchmark)

    let end = uptimeNanoseconds()
    var endUsage = rusage()
    getrusage(RUSAGE_SELF, &endUsage)
    let endSnapshot = captureUsageSnapshot()

    var results: [BenchmarkMetric: BenchmarkResult] = [:]

    let usageDelta = usageDifference(start: startSnapshot, end: endSnapshot)

    for metric in configuration.metrics {
      switch metric {
      case .wallClock:
        addTimeMetric(metric, value: end &- start, configuration: configuration, into: &results)
      case .cpuSystem:
        let systemDelta = systemTimeDelta(start: startUsage, end: endUsage)
        addTimeMetric(metric, value: systemDelta, configuration: configuration, into: &results)
      case .cpuUser:
        if usageDelta.userTimeNs > 0 {
          addTimeMetric(
            metric,
            value: usageDelta.userTimeNs,
            configuration: configuration,
            into: &results
          )
        }
      case .cpuTotal:
        let total = usageDelta.userTimeNs &+ usageDelta.systemTimeNs
        if total > 0 {
          addTimeMetric(metric, value: total, configuration: configuration, into: &results)
        }
      case .peakMemoryResident:
        addPeakResidentMetric(metric, endUsage: endUsage, configuration: configuration, into: &results)
      case .peakMemoryResidentDelta:
        if usageDelta.residentDeltaBytes > 0 {
          addCountMetric(
            metric,
            value: usageDelta.residentDeltaBytes,
            units: .count,
            configuration: configuration,
            into: &results
          )
        }
      case .peakMemoryVirtual:
        if usageDelta.virtualSizeBytes > 0 {
          addCountMetric(
            metric,
            value: usageDelta.virtualSizeBytes,
            units: .count,
            configuration: configuration,
            into: &results
          )
        }
      case .allocatedResidentMemory:
        if usageDelta.physFootprintBytes > 0 {
          addCountMetric(
            metric,
            value: usageDelta.physFootprintBytes,
            units: .count,
            configuration: configuration,
            into: &results
          )
        }
      case .syscalls:
        if usageDelta.syscalls > 0 {
          addCountMetric(
            metric,
            value: usageDelta.syscalls,
            units: .count,
            configuration: configuration,
            into: &results
          )
        }
      case .contextSwitches:
        if usageDelta.contextSwitches > 0 {
          addCountMetric(
            metric,
            value: usageDelta.contextSwitches,
            units: .count,
            configuration: configuration,
            into: &results
          )
        }
      case .threads:
        if usageDelta.threadCountPeak > 0 {
          addCountMetric(
            metric,
            value: UInt64(usageDelta.threadCountPeak),
            units: .count,
            configuration: configuration,
            into: &results
          )
        }
      case .threadsRunning:
        if usageDelta.threadsRunningPeak > 0 {
          addCountMetric(
            metric,
            value: UInt64(usageDelta.threadsRunningPeak),
            units: .count,
            configuration: configuration,
            into: &results
          )
        }
      case .instructions:
        if usageDelta.instructions > 0 {
          addCountMetric(
            metric,
            value: usageDelta.instructions,
            units: .count,
            configuration: configuration,
            into: &results
          )
        }
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

  /// Convenience overload that bridges an async body into the synchronous benchmark runner.
  @discardableResult
  public static func measureAsync(
    _ name: String,
    configuration: Benchmark.Configuration,
    _ body: @escaping () async throws -> Void
  ) async throws -> [BenchmarkMetric: BenchmarkResult] {
    var thrownError: Error?
    let results = measure(name, configuration: configuration) { _ in
      let semaphore = DispatchSemaphore(value: 0)
      Task {
        do {
          try await body()
        } catch {
          thrownError = error
        }
        semaphore.signal()
      }
      semaphore.wait()
    }
    if let error = thrownError { throw error }
    return results
  }
}

private func addTimeMetric(
  _ metric: BenchmarkMetric,
  value: UInt64,
  configuration: Benchmark.Configuration,
  into results: inout [BenchmarkMetric: BenchmarkResult]
) {
  guard value > 0 else { return }
  let stats = Statistics(units: .automatic, prefersLarger: metric.polarity == .prefersLarger)
  stats.add(clampToInt(value))
  var timeUnits: BenchmarkTimeUnits = .nanoseconds
  if let override = configuration.units[metric] {
    timeUnits = BenchmarkTimeUnits(override)
  }
  results[metric] = BenchmarkResult(
    metric: metric,
    timeUnits: timeUnits,
    scalingFactor: configuration.scalingFactor,
    warmupIterations: configuration.warmupIterations,
    thresholds: configuration.thresholds?[metric],
    tags: configuration.tags,
    statistics: stats
  )
}

private func addCountMetric(
  _ metric: BenchmarkMetric,
  value: UInt64,
  units: Statistics.Units,
  configuration: Benchmark.Configuration,
  into results: inout [BenchmarkMetric: BenchmarkResult]
) {
  guard value > 0 else { return }
  let stats = Statistics(units: units, prefersLarger: metric.polarity == .prefersLarger)
  stats.add(clampToInt(value))
  var timeUnits: BenchmarkTimeUnits = .automatic
  if let override = configuration.units[metric] {
    timeUnits = BenchmarkTimeUnits(override)
  }
  results[metric] = BenchmarkResult(
    metric: metric,
    timeUnits: timeUnits,
    scalingFactor: configuration.scalingFactor,
    warmupIterations: configuration.warmupIterations,
    thresholds: configuration.thresholds?[metric],
    tags: configuration.tags,
    statistics: stats
  )
}

private func addPeakResidentMetric(
  _ metric: BenchmarkMetric,
  endUsage: rusage,
  configuration: Benchmark.Configuration,
  into results: inout [BenchmarkMetric: BenchmarkResult]
) {
#if canImport(Glibc)
  let memBytes = UInt64(endUsage.ru_maxrss) * 1024
#elseif canImport(Darwin)
  let memBytes = UInt64(endUsage.ru_maxrss)
#else
  let memBytes = UInt64(endUsage.ru_maxrss)
#endif
  guard memBytes > 0 else { return }
  let stats = Statistics(units: .count, prefersLarger: metric.polarity == .prefersLarger)
  stats.add(clampToInt(memBytes))
  var timeUnits: BenchmarkTimeUnits = .nanoseconds
  if let override = configuration.units[metric] {
    timeUnits = BenchmarkTimeUnits(override)
  }
  results[metric] = BenchmarkResult(
    metric: metric,
    timeUnits: timeUnits,
    scalingFactor: configuration.scalingFactor,
    warmupIterations: configuration.warmupIterations,
    thresholds: configuration.thresholds?[metric],
    tags: configuration.tags,
    statistics: stats
  )
}

private func systemTimeDelta(start: rusage, end: rusage) -> UInt64 {
  let startNS =
    Double(start.ru_stime.tv_sec) * 1_000_000_000 + Double(start.ru_stime.tv_usec) * 1000
  let endNS =
    Double(end.ru_stime.tv_sec) * 1_000_000_000 + Double(end.ru_stime.tv_usec) * 1000
  let delta = endNS - startNS
  return delta > 0 ? UInt64(delta) : 0
}

private func clampToInt(_ value: UInt64) -> Int {
  value > UInt64(Int.max) ? Int.max : Int(value)
}

private struct UsageSnapshot {
  var userTimeNs: UInt64
  var systemTimeNs: UInt64
  var residentBytes: UInt64
  var virtualBytes: UInt64
  var physFootprintBytes: UInt64
  var syscalls: UInt64
  var contextSwitches: UInt64
  var threadCount: Int32
  var threadsRunning: Int32
  var instructions: UInt64
}

private struct UsageDelta {
  var userTimeNs: UInt64
  var systemTimeNs: UInt64
  var residentDeltaBytes: UInt64
  var virtualSizeBytes: UInt64
  var physFootprintBytes: UInt64
  var syscalls: UInt64
  var contextSwitches: UInt64
  var threadCountPeak: Int32
  var threadsRunningPeak: Int32
  var instructions: UInt64
}

private func usageDifference(start: UsageSnapshot, end: UsageSnapshot) -> UsageDelta {
  UsageDelta(
    userTimeNs: end.userTimeNs &- start.userTimeNs,
    systemTimeNs: end.systemTimeNs &- start.systemTimeNs,
    residentDeltaBytes: end.residentBytes > start.residentBytes
      ? end.residentBytes &- start.residentBytes
      : 0,
    virtualSizeBytes: end.virtualBytes,
    physFootprintBytes: end.physFootprintBytes,
    syscalls: end.syscalls > start.syscalls ? end.syscalls &- start.syscalls : 0,
    contextSwitches: end.contextSwitches > start.contextSwitches
      ? end.contextSwitches &- start.contextSwitches
      : 0,
    threadCountPeak: max(end.threadCount, start.threadCount),
    threadsRunningPeak: max(end.threadsRunning, start.threadsRunning),
    instructions: end.instructions > start.instructions
      ? end.instructions &- start.instructions
      : 0
  )
}

private func captureUsageSnapshot() -> UsageSnapshot {
#if canImport(Darwin)
  let pid = getpid()

  var taskInfo = proc_taskinfo()
  let taskInfoSize = MemoryLayout<proc_taskinfo>.size
  let taskResult = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, Int32(taskInfoSize))

  var usageInfo = rusage_info_current()
  let rusageResult = withUnsafeMutablePointer(to: &usageInfo) {
    $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
      proc_pid_rusage(pid, RUSAGE_INFO_CURRENT, $0)
    }
  }

  let userTime = rusageResult == 0 ? usageInfo.ri_user_time : 0
  let systemTime = rusageResult == 0 ? usageInfo.ri_system_time : 0
  let physFootprint = rusageResult == 0 ? usageInfo.ri_phys_footprint : 0
  let instructions = rusageResult == 0 ? usageInfo.ri_instructions : 0

  let resident = taskResult == taskInfoSize ? taskInfo.pti_resident_size : 0
  let virtual = taskResult == taskInfoSize ? taskInfo.pti_virtual_size : 0
  let syscalls = taskResult == taskInfoSize
    ? UInt64(taskInfo.pti_syscalls_mach + taskInfo.pti_syscalls_unix)
    : 0
  let contextSwitches = taskResult == taskInfoSize ? UInt64(taskInfo.pti_csw) : 0
  let threadCount = taskResult == taskInfoSize ? taskInfo.pti_threadnum : 0
  let threadsRunning = taskResult == taskInfoSize ? taskInfo.pti_numrunning : 0

  return UsageSnapshot(
    userTimeNs: userTime,
    systemTimeNs: systemTime,
    residentBytes: resident,
    virtualBytes: virtual,
    physFootprintBytes: physFootprint,
    syscalls: syscalls,
    contextSwitches: contextSwitches,
    threadCount: threadCount,
    threadsRunning: threadsRunning,
    instructions: instructions
  )
#else
  var usage = rusage()
  getrusage(RUSAGE_SELF, &usage)
  let user = UInt64(usage.ru_utime.tv_sec) * 1_000_000_000
    + UInt64(usage.ru_utime.tv_usec) * 1000
  let system = UInt64(usage.ru_stime.tv_sec) * 1_000_000_000
    + UInt64(usage.ru_stime.tv_usec) * 1000
  let contextSwitches = UInt64(usage.ru_nvcsw) + UInt64(usage.ru_nivcsw)
  return UsageSnapshot(
    userTimeNs: user,
    systemTimeNs: system,
    residentBytes: 0,
    virtualBytes: 0,
    physFootprintBytes: 0,
    syscalls: 0,
    contextSwitches: contextSwitches,
    threadCount: 0,
    threadsRunning: 0,
    instructions: 0
  )
#endif
}
#endif
