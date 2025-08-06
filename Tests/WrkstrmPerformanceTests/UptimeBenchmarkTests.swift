import Testing
@testable import WrkstrmPerformance

@Test
func uptimeInliningBenchmark() {
  @inline(__always)
  func inlined() -> UInt64 {
    uptimeNanoseconds()
  }
  @inline(never)
  func notInlined() -> UInt64 {
    uptimeNanoseconds()
  }

  let iterations = 1_000_000

  let inlineStart = uptimeNanoseconds()
  for _ in 0..<iterations {
    _ = inlined()
  }
  let inlineDuration = uptimeNanoseconds() - inlineStart

  let nonInlineStart = uptimeNanoseconds()
  for _ in 0..<iterations {
    _ = notInlined()
  }
  let nonInlineDuration = uptimeNanoseconds() - nonInlineStart

  print("inline: \(inlineDuration) ns, no-inline: \(nonInlineDuration) ns")
}
