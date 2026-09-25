// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CountdownCore",
    platforms: [.iOS(.v17), .watchOS(.v10)],
    products: [
        .library(name: "CountdownCore", targets: ["CountdownCore"])
    ],
    targets: [
        .target(name: "CountdownCore"),
        .testTarget(name: "CountdownCoreTests", dependencies: ["CountdownCore"])
    ]
)
