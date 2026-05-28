// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SentinelShieldSDK",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "SentinelShieldSDK",
            targets: ["SentinelShieldSDK"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "SentinelShieldSDK",
            url: "https://downloads.example.com/sentinel-shield/SentinelShieldSDK-1.0.0.xcframework.zip",
            checksum: "REPLACE_WITH_SWIFTPM_CHECKSUM"
        ),
    ]
)
