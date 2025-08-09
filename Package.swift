// swift-tools-version:6.1
import Foundation
import PackageDescription

// MARK: - Package Configuration

Package.Inject.local.dependencies = [
  .package(name: "WrkstrmLog", path: "../WrkstrmLog")
]

Package.Inject.remote.dependencies = [
  .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", from: "1.0.0"),
  .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0"))
]

var packageProducts: [Product] = [
  .library(name: "WrkstrmPerformance", targets: ["WrkstrmPerformance"])
]

var packageTargets: [Target] = [
  .target(
    name: "WrkstrmPerformance",
    dependencies: [
      "WrkstrmLog",
      .product(name: "Benchmark", package: "package-benchmark")
    ],
    swiftSettings: Package.Inject.shared.swiftSettings
  ),
  .testTarget(
    name: "WrkstrmPerformanceTests",
    dependencies: [
      "WrkstrmPerformance",
      .product(name: "Benchmark", package: "package-benchmark")
    ],
    swiftSettings: Package.Inject.shared.swiftSettings
  ),
]

if ProcessInfo.processInfo.environment["ENABLE_BENCHMARKS"] == "true" {
  packageTargets.append(
    .executableTarget(
      name: "TimeMonitorBenchmarks",
      dependencies: [
        "WrkstrmPerformance",
        .product(name: "Benchmark", package: "package-benchmark")
      ],
      path: "Benchmarks/TimeMonitorBenchmarks",
      swiftSettings: Package.Inject.shared.swiftSettings,
      plugins: [
        .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
      ]
    )
  )
}

#if !os(Linux)
  packageProducts.append(
    .library(name: "WrkstrmPerformanceObjC", targets: ["WrkstrmPerformanceObjC"])
  )
  packageProducts.append(
    .library(name: "WrkstrmPerformanceUIKit", targets: ["WrkstrmPerformanceUIKit"])
  )
  packageTargets.insert(
    .target(
      name: "WrkstrmPerformanceObjC",
      dependencies: ["WrkstrmPerformance"],
      publicHeadersPath: "include",
      swiftSettings: Package.Inject.shared.swiftSettings
    ),
    at: 1
  )
  packageTargets.insert(
    .target(
      name: "WrkstrmPerformanceUIKit",
      dependencies: ["WrkstrmPerformance", "WrkstrmPerformanceObjC"],
      swiftSettings: Package.Inject.shared.swiftSettings
    ),
    at: 2
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
