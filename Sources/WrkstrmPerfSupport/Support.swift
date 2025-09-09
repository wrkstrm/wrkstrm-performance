import Foundation

public actor DurationAggregator {
  private var samples: [Double] = []  // milliseconds
  private var failures: Int = 0
  public init() {}
  public func add(_ ms: Double) { samples.append(ms) }
  public func fail() { failures += 1 }
  public func values() -> [Double] { samples }
  public func summary() -> LatencySummary {
    let n = samples.count
    guard n > 0 else {
      return LatencySummary(
        count: 0, failures: failures, min: nil, max: nil, mean: nil, p50: nil, p90: nil, p99: nil)
    }
    let sorted = samples.sorted()
    let minv = sorted.first!
    let maxv = sorted.last!
    let mean = sorted.reduce(0, +) / Double(n)
    func pct(_ p: Double) -> Double {
      let idx = Int((Double(n - 1) * p).rounded())
      return sorted[max(0, min(n - 1, idx))]
    }
    return LatencySummary(
      count: n, failures: failures, min: minv, max: maxv, mean: mean, p50: pct(0.50),
      p90: pct(0.90), p99: pct(0.99))
  }
}

public struct LatencySummary: Sendable {
  public let count: Int
  public let failures: Int
  public let min: Double?
  public let max: Double?
  public let mean: Double?
  public let p50: Double?
  public let p90: Double?
  public let p99: Double?

  public init(
    count: Int, failures: Int, min: Double?, max: Double?, mean: Double?, p50: Double?,
    p90: Double?, p99: Double?
  ) {
    self.count = count
    self.failures = failures
    self.min = min
    self.max = max
    self.mean = mean
    self.p50 = p50
    self.p90 = p90
    self.p99 = p99
  }

  public func render() -> String {
    func fmt(_ x: Double?) -> String { x.map { String(format: "%.2f", $0) } ?? "-" }
    return """
      📊 latency (ms): count=\(count) fail=\(failures)
        min=\(fmt(min)) mean=\(fmt(mean)) max=\(fmt(max))
        p50=\(fmt(p50)) p90=\(fmt(p90)) p99=\(fmt(p99))
      """
  }

  public func renderOneLine(backend: String, wrapper: String) -> String {
    func f(_ x: Double?) -> String { x.map { String(format: "%.2f", $0) } ?? "-" }
    return
      "summary backend=\(backend) wrapper=\(wrapper) n=\(count) fail=\(failures) mean=\(f(mean)) p90=\(f(p90)) p99=\(f(p99)) min=\(f(min)) max=\(f(max)) ms"
  }
}

public struct MultiResult: Sendable {
  public let backend: String
  public let wrapper: String
  public let command: String
  public let summary: LatencySummary
  public init(backend: String, wrapper: String, command: String, summary: LatencySummary) {
    self.backend = backend
    self.wrapper = wrapper
    self.command = command
    self.summary = summary
  }
}

public enum Renderer {
  public static func summaryTable(_ rs: [MultiResult]) -> String {
    if rs.isEmpty { return "(no results)" }
    var rows: [[String]] = [
      ["backend", "wrapper", "cmd", "n", "fail", "mean", "p90", "p99", "min", "max"]
    ]
    for r in rs {
      func f(_ x: Double?) -> String { x.map { String(format: "%.2f", $0) } ?? "-" }
      rows.append([
        r.backend,
        r.wrapper,
        r.command,
        String(r.summary.count),
        String(r.summary.failures),
        f(r.summary.mean),
        f(r.summary.p90),
        f(r.summary.p99),
        f(r.summary.min),
        f(r.summary.max),
      ])
    }
    var widths = Array(repeating: 0, count: rows.first!.count)
    for row in rows { for (i, col) in row.enumerated() { widths[i] = max(widths[i], col.count) } }
    func pad(_ s: String, _ w: Int) -> String {
      s + String(repeating: " ", count: max(0, w - s.count))
    }
    var out = ""
    for (ri, row) in rows.enumerated() {
      let line = row.enumerated().map { pad($0.element, widths[$0.offset]) }.joined(separator: "  ")
      out += line + "\n"
      if ri == 0 {
        out += widths.map { String(repeating: "-", count: $0) }.joined(separator: "  ") + "\n"
      }
    }
    return out
  }

  public static func summaryTableMarkdown(_ rs: [MultiResult]) -> String {
    if rs.isEmpty { return "(no results)" }
    var rows: [[String]] = [
      ["backend", "wrapper", "cmd", "n", "fail", "mean", "p90", "p99", "min", "max"]
    ]
    for r in rs {
      func f(_ x: Double?) -> String { x.map { String(format: "%.2f", $0) } ?? "-" }
      rows.append([
        r.backend,
        r.wrapper,
        r.command,
        String(r.summary.count),
        String(r.summary.failures),
        f(r.summary.mean),
        f(r.summary.p90),
        f(r.summary.p99),
        f(r.summary.min),
        f(r.summary.max),
      ])
    }
    var out = "| " + rows[0].joined(separator: " | ") + " |\n"
    out += "|" + rows[0].map { _ in " --- " }.joined(separator: "|") + "|\n"
    for row in rows.dropFirst() { out += "| " + row.joined(separator: " | ") + " |\n" }
    return out
  }
}
