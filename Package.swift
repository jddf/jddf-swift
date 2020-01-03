// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "JDDF",
    products: [
        .library(name: "JDDF", targets: ["JDDF"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "JDDF", dependencies: []),
        .testTarget(name: "JDDFTests", dependencies: ["JDDF"]),
    ]
)
