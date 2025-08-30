// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MaceSecure",
    platforms: [.macOS(.v15), .iOS(.v16)],
    products: [
        .executable(name: "mace", targets: ["Mace"]),
        .executable(name: "keygen", targets: ["KeyGen"]),
        .library(name: "MaceCore", targets: ["MaceCore"])
    ],
    dependencies: [
        // Cross-platform crypto support
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.5.0"),
        // CLI argument parsing
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "MaceCore",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
            ],
            swiftSettings: [
                .define("MACE_ENABLE_PQC", .when(platforms: [.macOS]))
            ]
        ),
        .executableTarget(
            name: "Mace",
            dependencies: [
                "MaceCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .executableTarget(
            name: "KeyGen",
            dependencies: [
                "MaceCore"
            ]
        ),
        .testTarget(name: "MaceTests", dependencies: ["MaceCore", "Mace"], resources: [.copy("Fixtures")])
    ]
)


