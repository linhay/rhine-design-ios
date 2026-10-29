// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RhineDesign",
    platforms: [.iOS(.v17)],
    products: [.library(name: "RhineDesign", targets: ["RhineDesign"])],
    targets: [
        .target(name: "RhineDesign"),
        .testTarget(name: "RhineDesignTests", dependencies: ["RhineDesign"])
    ],
    swiftLanguageModes: [.v6]
)
