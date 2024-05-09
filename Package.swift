// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DotEnvy",
    products: [
        .library(
            name: "DotEnvy",
            targets: ["DotEnvy"]
        ),
    ],
    targets: [
        .target(
            name: "DotEnvy"
        ),
        .testTarget(
            name: "DotEnvyTests",
            dependencies: ["DotEnvy"]
        ),
    ]
)
