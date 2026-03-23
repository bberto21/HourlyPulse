//
//  MinuteMarkApp.swift
//  MinuteMark
//
//  Created by Admin on 3/17/26.
//
import SwiftUI
import UserNotifications

@main
struct MinuteMarkApp: App {
    private let notificationDelegate = ForegroundNotificationDelegate()

    init() {
        let center = UNUserNotificationCenter.current()
        center.delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AlarmViewModel())
        }
    }
}

final class ForegroundNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
