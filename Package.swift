// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PhotoManager",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "PhotoManager",
            targets: ["PhotoManager"]
        )
    ],
    targets: [
        .executableTarget(
            name: "PhotoManager",
            dependencies: [],
            path: "Sources/PhotoManager",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
    ]
)
