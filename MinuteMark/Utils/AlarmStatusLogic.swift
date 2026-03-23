import Foundation

struct AlarmStatusSnapshot: Equatable {
    let title: String
    let message: String
    let systemImage: String
}

enum AlarmStatusLogic {
    static func makeStatus(
        minutes: [Int],
        capacity: Int,
        pendingAlertCount: Int,
        accessState: NotificationAccessState,
        rejectedMinute: Int? = nil
    ) -> AlarmStatusSnapshot {
        if let rejectedMinute {
            return AlarmStatusSnapshot(
                title: "Minute Not Added",
                message: String(
                    format: ":%02d was not added. Capacity is full and earliest selected minutes are preserved.",
                    rejectedMinute
                ),
                systemImage: "exclamationmark.circle.fill"
            )
        }

        switch accessState {
        case .denied:
            return AlarmStatusSnapshot(
                title: "Notifications Disabled",
                message: "Notifications are disabled. Enable alerts and sounds in Settings.",
                systemImage: "exclamationmark.triangle.fill"
            )
        case .notDetermined:
            return AlarmStatusSnapshot(
                title: "Alerts Not Enabled",
                message: "Enable alerts to allow notifications for your selected minutes.",
                systemImage: "bell.badge"
            )
        case .authorized:
            break
        }

        if minutes.count == capacity, capacity > 0 {
            return AlarmStatusSnapshot(
                title: "Capacity Reached",
                message: "Alert capacity reached. Earliest selected minutes are preserved.",
                systemImage: "exclamationmark.circle.fill"
            )
        }

        if minutes.isEmpty {
            return AlarmStatusSnapshot(
                title: "Notifications Ready",
                message: "Choose up to \(capacity) minutes for the current active-hour range.",
                systemImage: "checkmark.circle.fill"
            )
        }

        return AlarmStatusSnapshot(
            title: "Notifications Ready",
            message: "\(pendingAlertCount)/\(AlarmScheduleLogic.maximumRepeatingRequests) alerts scheduled.",
            systemImage: "checkmark.circle.fill"
        )
    }
}
