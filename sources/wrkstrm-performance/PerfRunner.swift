import Foundation

public enum PerfRunner {
  /// Run a body a fixed number of iterations and report timing.
  public static func iterations(
    _ count: Int,
    targetHz: Double? = nil,
    body: @escaping @Sendable () async throws -> Void,
  ) async rethrows -> (iterations: Int, totalMS: Double, averageMS: Double) {
    let iterations = max(count, 0)
    guard iterations > 0 else { return (0, 0, 0) }
    let start = DispatchTime.now().uptimeNanoseconds
    let periodNs: UInt64? =
      targetHz.map { hz in hz > 0 ? UInt64((1.0 / hz) * 1_000_000_000.0) : 0 }
    for _ in 0..<iterations {
      try await body()
      if let ns = periodNs { try? await Task.sleep(nanoseconds: ns) }
    }
    let end = DispatchTime.now().uptimeNanoseconds
    let totalMs = Double(end &- start) / 1_000_000.0
    let avgMs = totalMs / Double(iterations)
    return (iterations, totalMs, avgMs)
  }

  /// Run a body repeatedly until duration elapses and report timing.
  public static func duration(
    seconds: Double,
    targetHz: Double? = nil,
    body: @escaping @Sendable () async throws -> Void,
  ) async rethrows -> (iterations: Int, totalMS: Double, averageMS: Double) {
    let budgetNs = UInt64(max(0.0, seconds) * 1_000_000_000.0)
    let start = DispatchTime.now().uptimeNanoseconds
    let periodNs: UInt64? =
      targetHz.map { hz in hz > 0 ? UInt64((1.0 / hz) * 1_000_000_000.0) : 0 }
    var iterations = 0
    while true {
      let now = DispatchTime.now().uptimeNanoseconds
      if now &- start >= budgetNs { break }
      try await body()
      iterations &+= 1
      if let ns = periodNs { try? await Task.sleep(nanoseconds: ns) }
    }
    let end = DispatchTime.now().uptimeNanoseconds
    let totalMs = Double(end &- start) / 1_000_000.0
    let avgMs = iterations > 0 ? totalMs / Double(iterations) : totalMs
    return (iterations, totalMs, avgMs)
  }
}
