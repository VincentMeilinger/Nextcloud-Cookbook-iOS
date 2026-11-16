// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RecipeScraperKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "RecipeScraperKit", targets: ["RecipeScraperKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.1"),
    ],
    targets: [
        .target(
            name: "RecipeScraperKit",
            dependencies: ["SwiftSoup"]
        ),
        .testTarget(
            name: "RecipeScraperKitTests",
            dependencies: ["RecipeScraperKit"]
        ),
    ]
)
