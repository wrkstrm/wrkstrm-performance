import Testing

@testable import WrkstrmPerformance

private struct SampleStruct {
  let a: Int32
  let b: Int8
}

@Test
func metricsMatchMemoryLayout() {
  let metrics = StructSizeMonitor.metrics(for: SampleStruct.self)
  #expect(metrics.size == MemoryLayout<SampleStruct>.size)
  #expect(metrics.stride == MemoryLayout<SampleStruct>.stride)
  #expect(metrics.alignment == MemoryLayout<SampleStruct>.alignment)
}

@Test
func logMetricsReturnSameValuesAsMetrics() {
  let metrics = StructSizeMonitor.metrics(for: SampleStruct.self)
  let logged = StructSizeMonitor.logMetrics(for: SampleStruct.self)
  #expect(logged.size == metrics.size)
  #expect(logged.stride == metrics.stride)
  #expect(logged.alignment == metrics.alignment)
}

@Test
func compareTypesProducesExpectedDeltas() {
  struct TypeA { let x: Int32 }
  struct TypeB { let x: Int64 }
  StructSizeMonitor.compare(TypeA.self, TypeB.self)
  let expectedSizeDelta = MemoryLayout<TypeA>.size - MemoryLayout<TypeB>.size
  let expectedStrideDelta = MemoryLayout<TypeA>.stride - MemoryLayout<TypeB>.stride
  let expectedAlignmentDelta = MemoryLayout<TypeA>.alignment - MemoryLayout<TypeB>.alignment
  #expect(expectedSizeDelta != 0 || expectedStrideDelta != 0 || expectedAlignmentDelta != 0)
}
