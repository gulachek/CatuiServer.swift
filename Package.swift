// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CatuiServer",
    products: [
        .library(
            name: "CatuiServer",
            targets: ["CatuiServer"]),
    ],
    targets: [
        .target(
            name: "CatuiServer"),
        .testTarget(
            name: "CatuiServerTests",
            dependencies: ["CatuiServer"]),
    ]
)
