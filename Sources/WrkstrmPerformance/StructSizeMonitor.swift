import WrkstrmLog

/// Provides size, stride, and alignment metrics for Swift types.
public enum StructSizeMonitor {
  /// Returns the size, stride, and alignment for the given type.
  public static func metrics<T>(for _: T.Type) -> (size: Int, stride: Int, alignment: Int) {
    (
      MemoryLayout<T>.size,
      MemoryLayout<T>.stride,
      MemoryLayout<T>.alignment,
    )
  }

  /// Logs the metrics for the given type and returns them.
  @discardableResult
  public static func logMetrics(for type: (some Any).Type) -> (
    size: Int, stride: Int, alignment: Int
  ) {
    let (size, stride, alignment) = metrics(for: type)
    Log.time.verbose("\(type): size=\(size) stride=\(stride) alignment=\(alignment)")
    return (size, stride, alignment)
  }

  /// Compares two types and logs the differences in their metrics.
  public static func compare(_ lhs: (some Any).Type, _ rhs: (some Any).Type) {
    let lhsMetrics = metrics(for: lhs)
    let rhsMetrics = metrics(for: rhs)
    let sizeDelta = lhsMetrics.size - rhsMetrics.size
    let strideDelta = lhsMetrics.stride - rhsMetrics.stride
    let alignmentDelta = lhsMetrics.alignment - rhsMetrics.alignment
    Log.time.verbose(
      "\(lhs) vs \(rhs) Δsize=\(sizeDelta) Δstride=\(strideDelta) Δalignment=\(alignmentDelta)",
    )
  }
}
