// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DotEnvy",
    products: [
        .executable(
            name: "dotenv-tool",
            targets: [
                "CLI",
            ]
        ),
        .library(
            name: "DotEnvy",
            targets: ["DotEnvy"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.1"),
    ],
    targets: [
        .target(
            name: "DotEnvy"
        ),
        .executableTarget(
            name: "CLI",
            dependencies: [
                "DotEnvy",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "DotEnvyTests",
            dependencies: ["DotEnvy"]
        ),
    ]
)
