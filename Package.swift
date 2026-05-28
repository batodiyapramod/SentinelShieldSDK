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
            url: "https://github.com/batodiyapramod/SentinelShieldSDK/releases/download/1.0.0/SentinelShieldSDK-1.0.0.xcframework.zip",
            checksum: "7714c132af95723292dabf99fd067ac4bec7abacc11673d17f8739b9061fd6c9"
        ),
    ]
)
