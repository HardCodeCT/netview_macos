// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetView",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "NetView",
            targets: ["NetView"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "NetView",
            dependencies: [],
            path: "NetView",
            sources: [
                "NetViewApp.swift",
                "DataManager.swift",
                "HistoryManager.swift",
                "LicenseManager.swift",
                "AutoStartManager.swift",
                "StatusBarController.swift",
                "MonitorView.swift",
                "HistoryWindowView.swift",
                "PaymentWindowView.swift"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        ),
    ]
)
