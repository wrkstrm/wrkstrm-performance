// swift-tools-version:6.1
import Foundation
import PackageDescription

// MARK: - Package Configuration

Package.Inject.local.dependencies = [
  .package(name: "WrkstrmLog", path: "../WrkstrmLog"),
  .package(name: "WrkstrmMain", path: "../WrkstrmMain"),
  .package(name: "WrkstrmFoundation", path: "../WrkstrmFoundation"),
]

Package.Inject.remote.dependencies = [
  .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", from: "2.0.0"),
  .package(url: "https://github.com/wrkstrm/WrkstrmMain.git", from: "2.4.0"),
  .package(url: "https://github.com/wrkstrm/WrkstrmFoundation.git", from: "2.0.0"),
]

var packageProducts: [Product] = [
  .library(name: "WrkstrmPerformance", targets: ["WrkstrmPerformance"]),
  .library(name: "WrkstrmEnvironment", targets: ["WrkstrmEnvironment"]),
]

#if !os(Linux)
packageProducts.append(
  .library(
    name: "WrkstrmPerformanceObjC",
    type: .static,
    targets: ["WrkstrmPerformanceObjC"],
  ),
)
packageProducts.append(
  .library(
    name: "WrkstrmPerformanceUIKit",
    type: .static,
    targets: ["WrkstrmPerformanceUIKit"],
  ),
)
#endif
// Perf support library (universal)
packageProducts.append(
  .library(name: "WrkstrmPerfSupport", targets: ["WrkstrmPerfSupport"]),
)

var wrkstrmPerformanceDependencies: [Target.Dependency] = [
  "WrkstrmLog",
  "WrkstrmMain",
  "WrkstrmFoundation",
]
var wrkstrmPerformanceTestDependencies: [Target.Dependency] = [
  "WrkstrmPerformance"
]

var packageTargets: [Target] = [
  .target(
    name: "WrkstrmPerformance",
    dependencies: wrkstrmPerformanceDependencies,
    swiftSettings: Package.Inject.shared.swiftSettings,
  ),
  .target(
    name: "WrkstrmEnvironment",
    dependencies: [],
    path: "Sources/WrkstrmEnvironment",
    swiftSettings: Package.Inject.shared.swiftSettings,
  ),
]
#if !os(Linux)
packageTargets += [
  .target(
    name: "WrkstrmPerformanceObjC",
    publicHeadersPath: "include",
  ),
  .target(
    name: "WrkstrmPerformanceUIKit",
    dependencies: [
      "WrkstrmPerformance",
      "WrkstrmPerformanceObjC",
    ],
    swiftSettings: Package.Inject.shared.swiftSettings,
  ),
]
#endif
packageTargets.append(
  .testTarget(
    name: "WrkstrmPerformanceTests",
    dependencies: wrkstrmPerformanceTestDependencies,
    swiftSettings: Package.Inject.shared.swiftSettings,
  ),
)
packageTargets.append(
  .testTarget(
    name: "WrkstrmEnvironmentTests",
    dependencies: ["WrkstrmEnvironment"],
    path: "Tests/WrkstrmEnvironmentTests",
    swiftSettings: Package.Inject.shared.swiftSettings,
  ),
)
// Perf support target (no additional deps needed)
packageTargets.append(
  .target(
    name: "WrkstrmPerfSupport",
    dependencies: [],
    swiftSettings: Package.Inject.shared.swiftSettings,
  ),
)

let package = Package(
  name: "WrkstrmPerformance",
  platforms: [
    .iOS(.v16),
    .macOS(.v14),
    .macCatalyst(.v16),
    .tvOS(.v16),
    .visionOS(.v1),
    .watchOS(.v10),
  ],
  products: packageProducts,
  dependencies: Package.Inject.shared.dependencies,
  targets: packageTargets,
)

// MARK: - Package Service

extension Package {
  @MainActor
  public struct Inject {
    public static let version = "0.0.1"

    public var swiftSettings: [SwiftSetting] = []
    var dependencies: [PackageDescription.Package.Dependency] = []

    public static let shared: Inject =
      ProcessInfo.useLocalDeps ? .local : .remote

    static var local: Inject = .init(swiftSettings: [.local])
    static var remote: Inject = .init()
  }
}

// MARK: - PackageDescription extensions

extension SwiftSetting {
  public static let local: SwiftSetting = .unsafeFlags([
    "-Xfrontend",
    "-warn-long-expression-type-checking=10",
  ])
}

// MARK: - Foundation extensions

extension ProcessInfo {
  public static var useLocalDeps: Bool {
    ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] == "true"
  }
}

// PACKAGE_SERVICE_END_V1
