import Foundation
import Testing

@testable import WrkstrmPerformance

@Test
func markTimestampRecordsEvent() {
  let event = "test_event"
  TimeMonitor.shared.markTimestamp(event)
  let report = TimeMonitor.shared.generateReport()
  #expect(report.contains(event))
}

@Test
func recordPreciseMeasurementUsesProvidedEndTimeForStartupTracking() {
  let start = uptimeNanoseconds()
  let monitor = TimeMonitor(startTime: start)

  let measurementStart = uptimeNanoseconds()
  Thread.sleep(forTimeInterval: 0.01)
  let measurementEnd = uptimeNanoseconds()
  Thread.sleep(forTimeInterval: 0.01)

  monitor.recordPreciseMeasurement(
    name: "custom_measurement",
    start: measurementStart,
    end: measurementEnd,
    trackSinceStartup: true
  )

  let recorded = monitor.timestamp(for: "custom_measurement.startup")
  #expect(recorded == measurementEnd)
}
