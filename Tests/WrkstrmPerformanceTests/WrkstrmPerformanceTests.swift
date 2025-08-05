import Testing
import Foundation

@testable import WrkstrmPerformance

@Test
func markTimestampRecordsEvent() {
  let event = "test_event"
  TimeMonitor.shared.markTimestamp(event)
  let report = TimeMonitor.shared.generateReport()
  #expect(report.contains(event))
}

@Test
func generateReportUsesEventTimestamps() {
  let start = uptimeNanoseconds()
  let monitor = TimeMonitor(startTime: start)

  monitor.markTimestamp("first")
  Thread.sleep(forTimeInterval: 0.001)
  monitor.markTimestamp("second")

  let report = monitor.generateReport()

  func elapsed(for event: String) -> Double {
    let line = report.split(separator: "\n").first { $0.contains("[\(event)]") } ?? ""
    let components = line.split(separator: "+")
    let timePart = components.count > 1 ? components[1].replacingOccurrences(of: "s", with: "") : "0"
    return Double(timePart) ?? 0
  }

  let firstTime = elapsed(for: "first")
  let secondTime = elapsed(for: "second")

  #expect(firstTime < secondTime)
}
