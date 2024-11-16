// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CatuiServer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CatuiServer",
            targets: ["CatuiServer"]),
    ],
    targets: [
        .target(
            name: "CatuiServer",
            dependencies: ["msgstream", "unixsocket", "catui"]
        ),
        .target(
            name: "msgstream"
        ),
        .target(
            name: "unixsocket"
        ),
        .target(
            name: "catui",
            dependencies: ["msgstream", "unixsocket", "cJSON"]
        ),
        .target(
            name: "cJSON",
            cSettings: [
                .headerSearchPath("include/cjson")
            ]
        ),
        .testTarget(
            name: "CatuiServerTests",
            dependencies: ["CatuiServer"]),
    ]
)
