// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpoofDeviceDetection",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SpoofDeviceDetection",
            targets: ["SpoofDeviceDetection"]),
        .library(
            name: "SpoofDeviceDetectionFull",
            targets: ["SpoofDeviceDetectionFull"])
    ],
    dependencies: [
        .package(url: "https://github.com/AppliedRecognition/Liveness-Detection-Core-Apple.git", from: "1.0.0")
//        .package(path: "../LivenessDetection")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SpoofDeviceDetection",
            dependencies: ["LivenessDetection"]),
        .target(
            name: "SpoofDeviceDetectionFull",
            dependencies: ["LivenessDetection", "SpoofDeviceDetection"],
            resources: [
                .copy("Resources/ARC_PSD-001_1.1.122_bst_yl80201_NMS_ult201_cml70.mlpackage")
            ],
            swiftSettings: [.define("SPM")]),
        .testTarget(
            name: "SpoofDeviceDetectionTests",
            dependencies: ["SpoofDeviceDetectionFull"],
            resources: [
                .copy("Resources/face_on_iPad_001.jpg")
            ])
    ]
)
