// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MarkitdownMac",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "MarkitdownMac", targets: ["MarkitdownMac"])
    ],
    targets: [
        .executableTarget(
            name: "MarkitdownMac",
            path: "Sources/MarkitdownMac"
        )
    ]
)
