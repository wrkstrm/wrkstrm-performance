import CommonLog

extension Log {
  /// The time logger instance, used for mach time logging.
  /// This instance should be used for mach time only.
  ///
  /// Example usage:
  /// ```
  /// Log.mach.info("Application started")
  /// ```
  public nonisolated(unsafe) static var time: Log = .init(
    system: "mach-time", category: "performance",
  )
  {
    didSet {
      verbose("New Logger: \(shared)")
    }
  }
}
