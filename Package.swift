// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BoolBuilder",
    products: [
        .library(
            name: "BoolBuilder",
            targets: ["BoolBuilder"]),
    ],
    targets: [
        .target(
            name: "BoolBuilder",
            dependencies: []),
        .testTarget(
            name: "BoolBuilderTests",
            dependencies: ["BoolBuilder"]),
    ]
)
