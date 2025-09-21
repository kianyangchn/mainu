// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MainuModules",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "Analytics", targets: ["Analytics"]),
        .library(name: "Capture", targets: ["Capture"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "InteractiveMenu", targets: ["InteractiveMenu"]),
        .library(name: "MenuProcessing", targets: ["MenuProcessing"]),
        .library(name: "OrderCart", targets: ["OrderCart"]),
        .library(name: "ShareLink", targets: ["ShareLink"])
    ],
    targets: [
        .target(
            name: "Analytics",
            path: "Analytics/Sources"
        ),
        .testTarget(
            name: "AnalyticsTests",
            dependencies: ["Analytics"],
            path: "Analytics/Tests"
        ),
        .target(
            name: "Capture",
            path: "Capture/Sources",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend", "-strict-concurrency=minimal",
                    "-Xfrontend", "-warn-concurrency"
                ])
            ]
        ),
        .testTarget(
            name: "CaptureTests",
            dependencies: ["Capture"],
            path: "Capture/Tests"
        ),
        .target(
            name: "DesignSystem",
            path: "DesignSystem/Sources"
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            path: "DesignSystem/Tests"
        ),
        .target(
            name: "MenuProcessing",
            path: "MenuProcessing/Sources"
        ),
        .testTarget(
            name: "MenuProcessingTests",
            dependencies: ["MenuProcessing"],
            path: "MenuProcessing/Tests"
        ),
        .target(
            name: "InteractiveMenu",
            dependencies: [
                "MenuProcessing",
                "DesignSystem"
            ],
            path: "InteractiveMenu/Sources"
        ),
        .testTarget(
            name: "InteractiveMenuTests",
            dependencies: ["InteractiveMenu", "MenuProcessing"],
            path: "InteractiveMenu/Tests"
        ),
        .target(
            name: "ShareLink",
            path: "ShareLink/Sources"
        ),
        .testTarget(
            name: "ShareLinkTests",
            dependencies: ["ShareLink"],
            path: "ShareLink/Tests"
        ),
        .target(
            name: "OrderCart",
            dependencies: ["MenuProcessing"],
            path: "OrderCart/Sources"
        ),
        .testTarget(
            name: "OrderCartTests",
            dependencies: ["OrderCart", "MenuProcessing"],
            path: "OrderCart/Tests"
        ),
        .target(
            name: "AppFeature",
            dependencies: [
                "Analytics",
                "Capture",
                "DesignSystem",
                "InteractiveMenu",
                "MenuProcessing",
                "OrderCart",
                "ShareLink"
            ],
            path: "AppFeature/Sources"
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: ["AppFeature"],
            path: "AppFeature/Tests"
        )
    ]
)
