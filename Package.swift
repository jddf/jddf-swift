// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "JDDF",
    products: [
        .library(name: "JDDF", targets: ["JDDF"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "JDDF", dependencies: ["SwiftyJSON"]),
        .testTarget(name: "JDDFTests", dependencies: ["JDDF"]),
    ]
)
