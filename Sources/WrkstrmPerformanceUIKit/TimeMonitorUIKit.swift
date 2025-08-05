#if canImport(UIKit)
import UIKit
import WrkstrmPerformance

/// Hooks into `UIApplication` lifecycle notifications and forwards them to
/// `TimeMonitor`.
public final class TimeMonitorUIKit: NSObject {
  private let monitor: TimeMonitor
  private let notificationCenter: NotificationCenter

  public init(
    monitor: TimeMonitor = .shared,
    notificationCenter: NotificationCenter = .default
  ) {
    self.monitor = monitor
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

  @objc private func applicationDidFinishLaunching() {
    monitor.applicationDidFinishLaunching()
  }

  @objc private func applicationDidBecomeActive() {
    monitor.applicationDidBecomeActive()
  }

  deinit {
    notificationCenter.removeObserver(self)
  }
}
#endif

