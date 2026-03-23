//
//  NotificationManager.swift
//  MinuteMark
//
//  Created by Admin on 3/17/26.
//
import Foundation
import UserNotifications

final class NotificationManager {
    private let center = UNUserNotificationCenter.current()
    static let maximumRepeatingRequests = AlarmScheduleLogic.maximumRepeatingRequests

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        center.getNotificationSettings { [center] settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion?(true)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    completion?(granted)
                }
            case .denied:
                completion?(false)
            @unknown default:
                completion?(false)
            }
        }
    }

    func fetchAccessState(completion: @escaping (NotificationAccessState) -> Void) {
        center.getNotificationSettings { settings in
            let state: NotificationAccessState

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                state = .authorized
            case .denied:
                state = .denied
            case .notDetermined:
                state = .notDetermined
            @unknown default:
                state = .notDetermined
            }

            completion(state)
        }
    }

    func allowedMinuteCapacity(forHourCount hourCount: Int) -> Int {
        guard hourCount > 0 else {
            return 0
        }

        return max(Self.maximumRepeatingRequests / hourCount, 0)
    }

    func pendingRequestCount(completion: @escaping (Int) -> Void) {
        center.getPendingNotificationRequests { requests in
            completion(requests.count)
        }
    }

    func schedule(minutes: [Int], startHour: Int, endHour: Int, soundName: String) {
        let validMinutes = Array(Set(minutes.filter { (0...59).contains($0) })).sorted()
        let scheduledHours = AlarmScheduleLogic.activeHours(startHour: startHour, endHour: endHour)

        guard !validMinutes.isEmpty, !scheduledHours.isEmpty else {
            clearAll()
            return
        }

        let requestedCount = validMinutes.count * scheduledHours.count
        if requestedCount > Self.maximumRepeatingRequests {
            print("MinuteMark Alerts can only schedule \(Self.maximumRepeatingRequests) repeating alerts. Requested \(requestedCount).")
        }

        center.removeAllPendingNotificationRequests()

        for hour in scheduledHours {
            for minute in validMinutes {
                var components = DateComponents()
                components.calendar = Calendar.current
                components.timeZone = .current
                components.hour = hour
                components.minute = minute
                components.second = 0

                let content = UNMutableNotificationContent()
                content.title = "MinuteMark Alerts"
                content.body = "Time: \(hour):\(String(format: "%02d", minute))"
                content.sound = Self.notificationSound(named: soundName)
                content.interruptionLevel = .timeSensitive
                content.relevanceScore = 1

                let id = "h_\(hour)_m_\(minute)"
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request) { error in
                    if let error {
                        print("Failed to schedule \(id): \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func clearAll() {
        center.removeAllPendingNotificationRequests()
        print("All scheduled notifications cleared.")
    }

    static func notificationSound(named soundName: String) -> UNNotificationSound {
        guard soundName != "default" else {
            return .default
        }

        let parts = soundName.split(separator: ".", maxSplits: 1).map(String.init)
        let resourceName = parts.first ?? soundName
        let resourceExtension = parts.count > 1 ? parts[1] : nil

        guard Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) != nil else {
            print("Custom notification sound not found in bundle: \(soundName)")
            return .default
        }

        return UNNotificationSound(named: UNNotificationSoundName(soundName))
    }
}
