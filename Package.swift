// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AddaMeRouteHandlers",
    platforms: [.macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "AddaMeRouteHandlers", targets: ["AddaMeRouteHandlers"]),
        .library(name: "AuthEngineHandlers", targets: ["AuthEngineHandlers"]),
        .library(name: "ChatEngineHandlers", targets: ["ChatEngineHandlers"]),
        .library(name: "EventEngineHandlers", targets: ["EventEngineHandlers"]),
        .library(name: "AppExtensions", targets: ["AppExtensions"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.62.1"),
        .package(url: "https://github.com/AddaMeSPB/AddaSharedModels.git", branch: "route"),
    ],
    targets: [
        .target(
            name: "AddaMeRouteHandlers",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AddaSharedModels", package: "AddaSharedModels"),
                "AuthEngineHandlers", "ChatEngineHandlers", "EventEngineHandlers"
            ]),
        
        .target(
            name: "AuthEngineHandlers",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AddaSharedModels", package: "AddaSharedModels"),
                "AppExtensions", "ChatEngineHandlers"
            ]),
    
        .target(
            name: "ChatEngineHandlers",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AddaSharedModels", package: "AddaSharedModels"),
                "AppExtensions"
            ]),
    
        .target(
            name: "EventEngineHandlers",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AddaSharedModels", package: "AddaSharedModels"),
                "AppExtensions"
            ]),
        
        .target(
            name: "AppExtensions",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "AddaSharedModels", package: "AddaSharedModels"),
            ]),
        
        
        .testTarget(
            name: "AddaMeRouteHandlersTests",
            dependencies: ["AddaMeRouteHandlers"]),
    ]
)
