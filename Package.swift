// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sanity",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Sanity",
            targets: ["Sanity"]),
    ],
    dependencies: [
        .package(name: "EventSource", url: "https://github.com/inaka/EventSource.git", .revision("78934b361891c7d0fa3d399d128e959f0c94d267"))
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Sanity",
            dependencies: ["EventSource"]),
        .testTarget(
            name: "SanityTests",
            dependencies: ["Sanity"]),
    ]
)
