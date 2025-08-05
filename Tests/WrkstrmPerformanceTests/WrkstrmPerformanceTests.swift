import Testing
@testable import WrkstrmPerformance

@Test
func markTimestampRecordsEvent() {
  let event = "test_event"
  TimeMonitor.shared.markTimestamp(event)
  let report = TimeMonitor.shared.generateReport()
  #expect(report.contains(event))
}
