import Foundation
import WrkstrmLog

#if canImport(WrkstrmPerformanceObjC)
  import WrkstrmPerformanceObjC
#endif

/// Provides the process start time, using the ObjC shim when available or a
/// Swift fallback when it is not. This avoids having each app declare its own
/// conditional startup timestamp.
enum BootTime: @unchecked Sendable {
  static let start: UInt64 = {
    #if canImport(WrkstrmPerformanceObjC)
      return WSMGetGlobalStartTime()
    #else
      return uptimeNanoseconds()
    #endif
  }()
}

/// Monitors and logs various stages of app boot time including pre-main stages
/// Example usage:
///
/// class AppDelegate {
///     let bootMonitor = TimeMonitor.shared
///
///     func applicationDidFinishLaunching() {
///         let startTime = Date().timeIntervalSinceReferenceDate
///
///         // Your initialization code here
///
///         bootMonitor.recordMetric(name: "app_initialization", startTime: startTime)
///     }
/// }
public final class TimeMonitor: @unchecked Sendable {
  public static let shared = TimeMonitor()

  /// Convert uptime nanoseconds to seconds
  private func timeIntervalSince(_ startTime: UInt64) -> Double {
    let elapsed = uptimeNanoseconds() - startTime
    return Double(elapsed) / 1_000_000_000
  }

  // Track important timestamps using uptime nanoseconds for higher precision
  private var timestamps: [String: UInt64] = [:]

  private init() {
    markTimestamp("monitor_init")
    Log.time.verbose("Time Monitor enabled!")
  }

  /// Mark a timestamp for early boot events
  public static func markEarlyTimestamp(_ event: String) {
    shared.markTimestamp(event)
  }

  /// Mark a timestamp for a specific event
  public func markTimestamp(_ event: String, file _: String = #file, line _: Int = #line) {
    let timestamp = uptimeNanoseconds()
    timestamps[event] = timestamp

    // Log the time since process start
    let timeSinceStart = timeIntervalSince(BootTime.start)
    Log.time.verbose("📊 [\(event)] +\(String(format: "%.6f", timeSinceStart))s")
  }

  // MARK: - App Lifecycle Events

  @MainActor public func applicationDidFinishLaunching() {
    markTimestamp("application_did_finish_launching")
  }

  @MainActor public func applicationDidBecomeActive() {
    markTimestamp("application_did_become_active")
  }

  /// Generate a detailed boot time report
  func generateReport() -> String {
    var report = "📱 Detailed Boot Time Report:\n"

    // Sort events chronologically
    let sortedEvents = timestamps.sorted { $0.value < $1.value }

    // Calculate times relative to process start
    for (event, _) in sortedEvents {
      let timeSinceStart = timeIntervalSince(BootTime.start)
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
}

extension TimeMonitor {
  /// Converts a duration between two uptime nanosecond values to seconds
  /// - Parameters:
  ///   - start: Starting uptime value
  ///   - end: Ending uptime value
  /// - Returns: Duration in seconds as a Double
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
    trackSinceStartup: Bool = false,
  ) {
    let durationSeconds = duration(from: start, to: end)
    Log.time.verbose("⏱️ [\(name)] took \(String(format: "%.9f", durationSeconds))s")

    if trackSinceStartup {
      // Also mark the timestamp for the measurement completion
      markTimestamp("\(name).startup")
    }
  }
}

