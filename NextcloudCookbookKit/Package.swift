// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NextcloudCookbookKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "NextcloudCookbookKit",
            targets: ["NextcloudCookbookKit"]
        ),
    ],
    targets: [
        .target(
            name: "NextcloudCookbookKit",
            path: "Sources/NextcloudCookbookKit"
        ),
        .testTarget(
            name: "NextcloudCookbookKitTests",
            dependencies: ["NextcloudCookbookKit"],
            path: "Tests/NextcloudCookbookKitTests"
        ),
    ]
)
