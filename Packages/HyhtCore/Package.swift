// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HyhtCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "HyhtCore",
            targets: ["HyhtCore"]
        )
    ],
    targets: [
        .target(
            name: "HyhtCore",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "HyhtCoreTests",
            dependencies: ["HyhtCore"]
        )
    ]
)
