import Foundation
import Testing

@testable import WrkstrmPerformance

@Test
func markTimestampRecordsEvent() async {
  let event = "test_event"
  await TimeMonitor.shared.markTimestamp(event)
  let report = await TimeMonitor.shared.generateReport()
  #expect(report.contains(event))
}

@Test
func generateReportUsesEventTimestamps() async {
  let start = uptimeNanoseconds()
  let monitor = TimeMonitor(startTime: start)

  await monitor.markTimestamp("first")
  try? await Task.sleep(nanoseconds: 1_000_000)
  await monitor.markTimestamp("second")

  let report = await monitor.generateReport()

  func elapsed(for event: String) -> Double {
    let line = report.split(separator: "\n").first { $0.contains("[\(event)]") } ?? ""
    let components = line.split(separator: "+")
    let timePart =
      components.count > 1 ? components[1].replacingOccurrences(of: "s", with: "") : "0"
    return Double(timePart) ?? 0
  }

  let firstTime = elapsed(for: "first")
  let secondTime = elapsed(for: "second")

  #expect(firstTime < secondTime)
}

@Test
func recordPreciseMeasurementUsesProvidedEndTimeForStartupTracking() async {
  let start = uptimeNanoseconds()
  let monitor = TimeMonitor(startTime: start)

  let measurementStart = uptimeNanoseconds()
  try? await Task.sleep(nanoseconds: 10_000_000)
  let measurementEnd = uptimeNanoseconds()
  try? await Task.sleep(nanoseconds: 10_000_000)

  await monitor.recordPreciseMeasurement(
    name: "custom_measurement",
    start: measurementStart,
    end: measurementEnd,
    trackSinceStartup: true
  )

  let recorded = await monitor.timestamp(for: "custom_measurement.startup")
  #expect(recorded == measurementEnd)
}
