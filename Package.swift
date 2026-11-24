// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ConfettiKit",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17)
    ],
    products: [
        .library(name: "ConfettiKit", targets: ["ConfettiKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.2"),
        .package(url: "https://github.com/rive-app/rive-ios", from: "6.24.0")
    ],
    targets: [
        .target(
            name: "ConfettiKit",
            dependencies: [
                .product(name: "Lottie", package: "lottie-spm"),
                .product(name: "RiveRuntime", package: "rive-ios")
            ]
        ),
        .testTarget(
            name: "ConfettiKitTests",
            dependencies: ["ConfettiKit"]
        )
    ]
)
