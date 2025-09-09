// swift-tools-version:6.1
import Foundation
import PackageDescription

// MARK: - Package Configuration

Package.Inject.local.dependencies = [
  .package(name: "WrkstrmLog", path: "../WrkstrmLog")
]

Package.Inject.remote.dependencies = [
  .package(url: "https://github.com/wrkstrm/WrkstrmLog.git", from: "2.0.0")
]
#if !os(Linux)
Package.Inject.remote.dependencies.append(
  .package(url: "https://github.com/ordo-one/package-benchmark.git", .upToNextMajor(from: "1.4.0"))
)
#endif

var packageProducts: [Product] = [
  .library(name: "WrkstrmPerformance", targets: ["WrkstrmPerformance"])
]
#if !os(Linux)
packageProducts.append(
  .library(
    name: "WrkstrmPerformanceObjC",
    type: .static,
    targets: ["WrkstrmPerformanceObjC"]
  )
)
packageProducts.append(
  .library(
    name: "WrkstrmPerformanceUIKit",
    type: .static,
    targets: ["WrkstrmPerformanceUIKit"]
  )
)
#endif
// Perf support library (universal)
packageProducts.append(
  .library(name: "WrkstrmPerfSupport", targets: ["WrkstrmPerfSupport"])
)

var wrkstrmPerformanceDependencies: [Target.Dependency] = [
  "WrkstrmLog"
]
var wrkstrmPerformanceTestDependencies: [Target.Dependency] = [
  "WrkstrmPerformance"
]

//#if !os(Linux) && canImport(Darwin)
//wrkstrmPerformanceDependencies.append(
//  .product(name: "Benchmark", package: "package-benchmark")
//)
//wrkstrmPerformanceTestDependencies.append(
//  .product(name: "Benchmark", package: "package-benchmark")
//)
//#endif  // !os(Linux) && canImport(Darwin)

var packageTargets: [Target] = [
  .target(
    name: "WrkstrmPerformance",
    dependencies: wrkstrmPerformanceDependencies,
    swiftSettings: Package.Inject.shared.swiftSettings
  )
]
#if !os(Linux)
packageTargets += [
  .target(
    name: "WrkstrmPerformanceObjC",
    publicHeadersPath: "include"
  ),
  .target(
    name: "WrkstrmPerformanceUIKit",
    dependencies: [
      "WrkstrmPerformance",
      "WrkstrmPerformanceObjC",
    ],
    swiftSettings: Package.Inject.shared.swiftSettings
  ),
]
#endif
packageTargets.append(
  .testTarget(
    name: "WrkstrmPerformanceTests",
    dependencies: wrkstrmPerformanceTestDependencies,
    swiftSettings: Package.Inject.shared.swiftSettings
  )
)
// Perf support target (no additional deps needed)
packageTargets.append(
  .target(
    name: "WrkstrmPerfSupport",
    dependencies: [],
    swiftSettings: Package.Inject.shared.swiftSettings
  )
)

//#if !os(Linux)
//packageTargets.append(
//  .executableTarget(
//    name: "TimeMonitorBenchmarks",
//    dependencies: [
//      "WrkstrmPerformance",
//      .product(name: "Benchmark", package: "package-benchmark"),
//    ],
//    path: "Benchmarks/TimeMonitorBenchmarks",
//    swiftSettings: Package.Inject.shared.swiftSettings,
//    plugins: [
//      .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
//    ]
//  )
//)
//#endif

let package = Package(
  name: "WrkstrmPerformance",
  platforms: [
    .iOS(.v16),
    .macOS(.v15),
    .macCatalyst(.v16),
    .tvOS(.v16),
    .visionOS(.v1),
    .watchOS(.v10),
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
