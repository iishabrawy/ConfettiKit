// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ConfettiKit",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17),
        .tvOS(.v17)
    ],
    products: [
        .library(name: "ConfettiKit", targets: ["ConfettiKit"])
    ],
    targets: [
        .target(name: "ConfettiKit"),
        .testTarget(
            name: "ConfettiKitTests",
            dependencies: ["ConfettiKit"]
        )
    ]
)
