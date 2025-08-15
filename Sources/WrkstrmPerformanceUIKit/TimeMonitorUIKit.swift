#if canImport(UIKit)
import UIKit
import WrkstrmPerformance
import WrkstrmPerformanceObjC

/// Hooks into `UIApplication` lifecycle notifications and forwards them to
/// `TimeMonitor`.
public final class TimeMonitorUIKit: NSObject {
  private let notificationCenter: NotificationCenter

  public init(notificationCenter: NotificationCenter = .default) {
    self.notificationCenter = notificationCenter
    super.init()

    notificationCenter.addObserver(
      self,
      selector: #selector(applicationDidFinishLaunching),
      name: UIApplication.didFinishLaunchingNotification,
      object: nil
    )

    notificationCenter.addObserver(
      self,
      selector: #selector(applicationDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
  }

  @MainActor @objc private func applicationDidFinishLaunching() {
    TimeMonitor.applicationDidFinishLaunching()
  }

  @MainActor @objc private func applicationDidBecomeActive() {
    TimeMonitor.applicationDidBecomeActive()
  }

  deinit {
    notificationCenter.removeObserver(self)
  }
}
#endif
