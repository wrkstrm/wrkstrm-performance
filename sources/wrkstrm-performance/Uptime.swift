#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// Returns the system uptime using the most precise monotonic clock in
/// nanoseconds.
/// - Note: On Apple platforms this uses `clock_gettime_nsec_np` with
/// `CLOCK_UPTIME_RAW` for nanosecond precision. On Linux it prefers
/// `CLOCK_BOOTTIME` and falls back to `CLOCK_MONOTONIC_RAW` if needed.
@inlinable @inline(__always)
public func uptimeNanoseconds() -> UInt64 {
  #if canImport(Darwin)
  return clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
  #else
  var timeSpec = timespec()
  #if os(Linux)
  // Prefer CLOCK_BOOTTIME which continues ticking during suspend.
  // If unavailable, fall back to the raw hardware clock.
  if clock_gettime(CLOCK_BOOTTIME, &timeSpec) != 0 {
    clock_gettime(CLOCK_MONOTONIC_RAW, &timeSpec)
  }
  #else
  clock_gettime(CLOCK_MONOTONIC_RAW, &timeSpec)
  #endif
  return UInt64(timeSpec.tv_sec) * 1_000_000_000 + UInt64(timeSpec.tv_nsec)
  #endif
}
