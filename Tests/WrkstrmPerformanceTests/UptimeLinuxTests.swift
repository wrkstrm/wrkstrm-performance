#if os(Linux)
import Glibc
import Testing
@testable import WrkstrmPerformance

@Test
func uptimeMonotonicIncreases() {
  let start = uptimeNanoseconds()
  usleep(1000)  // sleep for 1ms to ensure measurable difference
  let end = uptimeNanoseconds()
  let elapsed = end - start
  #expect(elapsed >= 1_000_000)
}
#endif
