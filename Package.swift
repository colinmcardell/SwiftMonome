// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftMonome",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftMonome",
            targets: ["SwiftMonome"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
                // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .systemLibrary(
            name: "clibmonome"
        ),
        .target(
            name: "SwiftMonome",
            dependencies: ["clibmonome"]
        ),
        .target(
            name: "monome-project",
            dependencies: ["SwiftMonome"]
        ),
        .testTarget(
            name: "SwiftMonomeTests",
            dependencies: ["SwiftMonome"]
        ),
    ]
)
