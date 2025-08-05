import Foundation
import WrkstrmPerformance

@objc(WSMBootTimeMonitor)
public final class BootTimeMonitor: NSObject {
  @objc public static let shared = BootTimeMonitor()

  private override init() {}

  @objc(markEarlyTimestamp:)
  public class func markEarlyTimestamp(_ event: String) {
    TimeMonitor.markEarlyTimestamp(event)
  }
}
