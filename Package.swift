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
            name: "SpoofDeviceDetectionModel",
            targets: ["SpoofDeviceDetectionModel"])
    ],
    dependencies: [
        .package(url: "https://github.com/AppliedRecognition/Liveness-Detection-Core-Apple.git", revision: "c8f9cc500e8f62a58b758ab83e559e361662a104")
//        .package(path: "../LivenessDetection")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SpoofDeviceDetection",
            dependencies: [
                .product(
                    name: "LivenessDetection",
                    package: "Liveness-Detection-Core-Apple"
                )
            ]),
        .target(
            name: "SpoofDeviceDetectionModel",
            dependencies: ["SpoofDeviceDetection"],
            resources: [
                .copy("Resources/ARC_PSD-001_1.1.122_bst_yl80201_NMS_ult201_cml70.mlpackage")
            ],
            swiftSettings: [.define("SPM")]),
        .testTarget(
            name: "SpoofDeviceDetectionTests",
            dependencies: ["SpoofDeviceDetectionModel"],
            resources: [
                .copy("Resources/face_on_iPad_001.jpg")
            ])
    ]
)
