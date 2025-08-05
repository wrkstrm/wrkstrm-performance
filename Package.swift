// swift-tools-version:6.1
import Foundation
import PackageDescription

// MARK: - Package Configuration

Package.Inject.local.dependencies = [
  .package(name: "WrkstrmLog", path: "../WrkstrmLog")
]

Package.Inject.remote.dependencies = [
  .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", from: "1.0.0")
]

var targetDependencies: [Target.Dependency] = [
  "WrkstrmLog"
]

#if canImport(Darwin)
  targetDependencies.append(
    .target(
      name: "WrkstrmPerformanceObjC",
      condition: .when(platforms: [
        .iOS, .macOS, .macCatalyst, .tvOS, .visionOS, .watchOS,
      ])
    )
  )
#endif

var packageTargets: [Target] = [
  .target(
    name: "WrkstrmPerformance",
    dependencies: targetDependencies,
    swiftSettings: Package.Inject.shared.swiftSettings
  ),
  .testTarget(
    name: "WrkstrmPerformanceTests",
    dependencies: ["WrkstrmPerformance"],
    swiftSettings: Package.Inject.shared.swiftSettings
  ),
]

#if canImport(Darwin)
  packageTargets.append(
    .target(
      name: "WrkstrmPerformanceObjC",
      publicHeadersPath: "include"
    )
  )
#endif

#if canImport(UIKit)
  packageTargets.append(
    .target(
      name: "WrkstrmPerformanceUIKit",
      dependencies: ["WrkstrmPerformance"],
      swiftSettings: Package.Inject.shared.swiftSettings
    )
  )
#endif

var packageProducts: [Product] = [
  .library(name: "WrkstrmPerformance", targets: ["WrkstrmPerformance"])
]

#if canImport(UIKit)
  packageProducts.append(
    .library(name: "WrkstrmPerformanceUIKit", targets: ["WrkstrmPerformanceUIKit"])
  )
#endif

let package = Package(
  name: "WrkstrmPerformance",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .macCatalyst(.v13),
    .tvOS(.v16),
    .visionOS(.v1),
    .watchOS(.v9),
  ],
  products: packageProducts,
  dependencies: Package.Inject.shared.dependencies,
  targets: packageTargets
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

    static var local: Inject = .init(swiftSettings: [.localSwiftSettings])
    static var remote: Inject = .init()
  }
}

// MARK: - PackageDescription extensions

extension SwiftSetting {
  public static let localSwiftSettings: SwiftSetting = .unsafeFlags([
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
