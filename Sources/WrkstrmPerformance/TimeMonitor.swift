import Foundation
import WrkstrmLog

/// Provides the process start time using Swift's uptime clock. This avoids
/// having each app declare its own conditional startup timestamp and keeps the
/// core library free of Objective-C references for Linux compatibility.
enum BootTime: @unchecked Sendable {
  static let start: UInt64 = uptimeNanoseconds()
}

public actor TimeMonitor: @unchecked Sendable {
  public static let shared = TimeMonitor(startTime: BootTime.start)

  var startTime: UInt64
  private var timestamps: [String: UInt64] = [:]

  public init(startTime: UInt64) {
    self.startTime = startTime
    Task { await markTimestamp("monitor_init") }
    Log.time.verbose("Time Monitor enabled!")
  }

  /// Convert uptime nanoseconds to seconds
  @inline(__always)
  private func timeIntervalSinceStartTime(_ timeStamp: UInt64) -> Double {
    let elapsed = timeStamp - startTime
    return Double(elapsed) / 1_000_000_000
  }

  /// Mark a timestamp for a specific event
  public func markTimestamp(
    _ event: String,
    timestamp: UInt64 = uptimeNanoseconds(),
    file _: String = #file,
    line _: Int = #line
  ) {
    timestamps[event] = timestamp

    // Log the time since process start
    let timeSinceStart = timeIntervalSinceStartTime(timestamp)
    Log.time.verbose("📊 [\(event)] +\(String(format: "%.6f", timeSinceStart))s")
  }

  // MARK: - App Lifecycle Events

  public func applicationDidFinishLaunching() {
    markTimestamp("application_did_finish_launching")
  }

  public func applicationDidBecomeActive() {
    markTimestamp("application_did_become_active")
  }

  /// Generate a detailed boot time report
  func generateReport() -> String {
    var report = "📱 Detailed Boot Time Report:\n"

    // Sort events chronologically
    let sortedEvents = timestamps.sorted { $0.value < $1.value }

    // Calculate times relative to process start
    for (event, ts) in sortedEvents {
      let timeSinceStart = timeIntervalSinceStartTime(ts)
      report += "[\(event)] +\(String(format: "%.6f", timeSinceStart))s\n"
    }

    return report
  }

  /// Add additional timing points for key app events
  func recordMetric(name: String, startTime: TimeInterval) {
    let endTime = Date().timeIntervalSinceReferenceDate
    let duration = endTime - startTime
    Log.time.verbose("⏱️ [\(name)] took \(String(format: "%.6f", duration))s")
  }

  /// Converts a duration between two uptime nanosecond values to seconds
  /// - Parameters:
  ///   - start: Starting uptime value
  ///   - end: Ending uptime value
  /// - Returns: Duration in seconds as a Double
  @inline(__always)
  func duration(from start: UInt64, to end: UInt64) -> Double {
    let elapsed = end - start
    return Double(elapsed) / 1_000_000_000
  }

  /// Records a timestamped measurement with nanosecond precision
  /// - Parameters:
  ///   - name: Name of the measurement
  ///   - start: Starting uptime value
  ///   - end: Ending uptime value (defaults to current time if not provided)
  public func recordPreciseMeasurement(
    name: String,
    start: UInt64,
    end: UInt64 = uptimeNanoseconds(),
    trackSinceStartup: Bool = false
  ) {
    let durationSeconds = duration(from: start, to: end)
    Log.time.verbose("⏱️ [\(name)] took \(String(format: "%.9f", durationSeconds))s")

    if trackSinceStartup {
      // Also mark the timestamp for the measurement completion
      markTimestamp("\(name).startup", timestamp: end)
    }
  }

  /// Retrieves a recorded timestamp for the specified event
  func timestamp(for event: String) -> UInt64? {
    timestamps[event]
  }
}

// MARK: - Nonisolated static helpers
extension TimeMonitor {
  /// Mark a timestamp for early boot events
  public nonisolated static func markEarlyTimestamp(_ event: String) {
    Task { await shared.markTimestamp(event) }
  }

  /// Mark a timestamp for a specific event
  public nonisolated static func mark(_ event: String) {
    Task { await shared.markTimestamp(event) }
  }

  public nonisolated static func applicationDidFinishLaunching() {
    Task { @MainActor in await shared.applicationDidFinishLaunching() }
  }

  public nonisolated static func applicationDidBecomeActive() {
    Task { @MainActor in await shared.applicationDidBecomeActive() }
  }

  public nonisolated static func recordPreciseMeasurement(
    name: String,
    start: UInt64,
    end: UInt64 = uptimeNanoseconds(),
    trackSinceStartup: Bool = false
  ) {
    Task {
      await shared.recordPreciseMeasurement(
        name: name,
        start: start,
        end: end,
        trackSinceStartup: trackSinceStartup
      )
    }
  }
}
