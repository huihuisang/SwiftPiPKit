// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftPiPKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftPiPKit",
            targets: ["SwiftPiPKit"]),
    ],
    targets: [
        .target(
            name: "SwiftPiPKit",
            dependencies: []),
        .testTarget(
            name: "SwiftPiPKitTests",
            dependencies: ["SwiftPiPKit"]),
    ]
)

