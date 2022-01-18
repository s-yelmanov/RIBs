// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "RIBs",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "RIBs", targets: ["RIBs"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "RIBs",
            dependencies: [],
            path: "ios/RIBs"
        ),
        .testTarget(
            name: "RIBsTests",
            dependencies: ["RIBs"],
            path: "ios/RIBsTests"
        ),
    ]
)
