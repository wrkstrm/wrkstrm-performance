import Foundation

#if canImport(ObjectiveC)
  @MainActor
  @objc(WSMBootTimeMonitor)
  public final class BootTimeMonitor: NSObject {
    @objc public static let shared = BootTimeMonitor()

    private override init() {}

    @objc(markEarlyTimestamp:)
    public class func markEarlyTimestamp(_ event: String) {
      TimeMonitor.markEarlyTimestamp(event)
    }
  }
#endif
