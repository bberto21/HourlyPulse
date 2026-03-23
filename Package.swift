// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MinuteMarkCore",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "MinuteMarkCore",
            targets: ["MinuteMarkCore"]
        ),
    ],
    targets: [
        .target(
            name: "MinuteMarkCore",
            path: "MinuteMark",
            exclude: [
                "ContentView.swift",
                "MinuteMarkApp.swift",
                "Resources",
                "Sounds",
                "Utils/MinuteParser.swift",
                "Services/NotificationManager.swift",
                "ViewModels",
            ],
            sources: [
                "Models/AlarmSettings.swift",
                "Models/NotificationAccessState.swift",
                "Services/SettingsStore.swift",
                "Utils/AlarmScheduleLogic.swift",
                "Utils/AlarmStatusLogic.swift",
            ]
        ),
        .testTarget(
            name: "MinuteMarkCoreTests",
            dependencies: ["MinuteMarkCore"]
        ),
    ]
)
