// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CalendarApp",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "CalendarApp",
            targets: ["CalendarApp"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "CalendarApp",
            dependencies: [],
            path: "Sources",
            exclude: ["CalendarApp/Info.plist"],
            resources: [
                .copy("CalendarApp/Resources")
            ]
        )
    ]
) 