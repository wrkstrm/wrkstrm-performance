import Foundation
import CommonLog
import WrkstrmMain

// Canonical definitions of JSON parse metrics live here in WrkstrmPerformance.
// Other packa  ges should import (or re-export) this module rather than redefining.
extension WrkstrmMain.JSON {
  public enum ParseOperation: String, Codable, Sendable { case encode, decode }

  /// A single encode/decode measurement.
  public struct ParseMetricEvent: Codable, Sendable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let op: ParseOperation
    public let typeName: String
    public let parserName: String
    public let sizeBytes: Int?
    public let durationNanoseconds: Int64
    public let success: Bool
    public let context: String?
    public let errorDescription: String?

    public init(
      id: UUID = UUID(),
      timestamp: Date = Date(),
      op: ParseOperation,
      typeName: String,
      parserName: String,
      sizeBytes: Int?,
      durationNanoseconds: Int64,
      success: Bool,
      context: String?,
      errorDescription: String?
    ) {
      self.id = id
      self.timestamp = timestamp
      self.op = op
      self.typeName = typeName
      self.parserName = parserName
      self.sizeBytes = sizeBytes
      self.durationNanoseconds = durationNanoseconds
      self.success = success
      self.context = context
      self.errorDescription = errorDescription
    }
  }

  /// In-memory ring buffer for parse events with simple snapshot access.
  public actor ParseMetricsStore {
    private let capacity: Int
    private var buffer: [ParseMetricEvent] = []
    private var nextIndex: Int = 0
    private var aggregates: [Key: Aggregate] = [:]
    private let logger: Log

    public init(capacity: Int = 10_000, logger: Log? = nil) {
      self.capacity = max(1, capacity)
      self.buffer.reserveCapacity(self.capacity)
      self.logger = logger ?? Log.shared
    }

    public func append(_ event: ParseMetricEvent) {
      if buffer.count < capacity {
        buffer.append(event)
      } else {
        buffer[nextIndex] = event
        nextIndex = (nextIndex + 1) % capacity
      }
      updateAggregates(with: event)
      logTraceSummary(for: event)
    }

    /// Snapshot of all events in time order (oldest → newest).
    public func snapshot() -> [ParseMetricEvent] {
      guard buffer.count == capacity else { return buffer }
      let head = buffer[nextIndex..<capacity]
      let tail = buffer[0..<nextIndex]
      return Array(head + tail)
    }

    // MARK: - Aggregates

    private struct Key: Hashable {
      let parser: String
      let op: ParseOperation
    }
    private struct Aggregate {
      var count: Int = 0
      var successCount: Int = 0
      var totalDurationNs: Int64 = 0
      var minDurationNs: Int64 = .max
      var maxDurationNs: Int64 = 0
      var totalSizeBytes: Int64 = 0
    }

    private func updateAggregates(with e: ParseMetricEvent) {
      let key = Key(parser: e.parserName, op: e.op)
      var agg = aggregates[key] ?? Aggregate()
      agg.count &+= 1
      if e.success { agg.successCount &+= 1 }
      agg.totalDurationNs &+= e.durationNanoseconds
      if e.durationNanoseconds < agg.minDurationNs { agg.minDurationNs = e.durationNanoseconds }
      if e.durationNanoseconds > agg.maxDurationNs { agg.maxDurationNs = e.durationNanoseconds }
      if let sz = e.sizeBytes { agg.totalSizeBytes &+= Int64(sz) }
      aggregates[key] = agg
    }

    private func logTraceSummary(for e: ParseMetricEvent) {
      let key = Key(parser: e.parserName, op: e.op)
      let agg = aggregates[key]
      let ok = agg?.successCount ?? 0
      let n = agg?.count ?? 0
      let err = max(0, n - ok)
      let avgNs: Int64 = (agg?.totalDurationNs ?? 0) / Int64(max(1, n))
      let avgUs = Double(avgNs) / 1_000.0
      let lastUs = Double(e.durationNanoseconds) / 1_000.0
      let avgSize = (agg?.totalSizeBytes ?? 0) / Int64(max(1, n))
      let avgUsString = String(format: "%.2f", avgUs)
      let lastUsString = String(format: "%.2f", lastUs)
      let contextValue = e.context ?? "-"
      let metricsLine = [
        "JSONParse",
        "parser=\(e.parserName)",
        "op=\(e.op.rawValue)",
        "n=\(n)",
        "ok=\(ok)",
        "err=\(err)",
        "avg_us=\(avgUsString)",
        "last_us=\(lastUsString)",
        "avg_size=\(avgSize)B",
        "type=\(e.typeName)",
        "ctx=\(contextValue)",
      ].joined(separator: " ")
      let line = metricsLine
      logger.trace(line)
    }
  }
}
