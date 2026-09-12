// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "cloud_firestore", path: "../.packages/cloud_firestore-6.0.2"),
        .package(name: "connectivity_plus", path: "../.packages/connectivity_plus-6.1.5"),
        .package(name: "firebase_auth", path: "../.packages/firebase_auth-6.1.0"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.1.1"),
        .package(name: "path_provider_foundation", path: "../.packages/path_provider_foundation-2.4.2"),
        .package(name: "share_plus", path: "../.packages/share_plus-12.0.0"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.4"),
        .package(name: "speech_to_text", path: "../.packages/speech_to_text-7.4.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "cloud-firestore", package: "cloud_firestore"),
                .product(name: "connectivity-plus", package: "connectivity_plus"),
                .product(name: "firebase-auth", package: "firebase_auth"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "share-plus", package: "share_plus"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "speech-to-text", package: "speech_to_text"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
