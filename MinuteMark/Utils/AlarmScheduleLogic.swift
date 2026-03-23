import Foundation

enum AlarmScheduleLogic {
    static let maximumRepeatingRequests = 64

    static func activeHours(startHour: Int, endHour: Int) -> [Int] {
        let normalizedStart = ((startHour % 24) + 24) % 24
        let normalizedEnd = ((endHour % 24) + 24) % 24

        if normalizedStart <= normalizedEnd {
            return Array(normalizedStart...normalizedEnd)
        }

        return Array(normalizedStart...23) + Array(0...normalizedEnd)
    }

    static func minuteCapacity(startHour: Int, endHour: Int, maximumRequests: Int = maximumRepeatingRequests) -> Int {
        let hourCount = activeHours(startHour: startHour, endHour: endHour).count
        guard hourCount > 0 else {
            return 0
        }

        return max(maximumRequests / hourCount, 0)
    }

    static func clampedMinutesPreservingEarliest(
        selectionHistory: [Int],
        startHour: Int,
        endHour: Int,
        maximumRequests: Int = maximumRepeatingRequests
    ) -> [Int] {
        let capacity = minuteCapacity(startHour: startHour, endHour: endHour, maximumRequests: maximumRequests)
        return Array(selectionHistory.prefix(capacity))
    }

    static func upcomingAlertDates(
        now: Date,
        minutes: [Int],
        startHour: Int,
        endHour: Int,
        limit: Int,
        calendar: Calendar = .current
    ) -> [Date] {
        guard !minutes.isEmpty else {
            return []
        }

        let candidates = activeHours(startHour: startHour, endHour: endHour).flatMap { hour in
            minutes.compactMap { minute -> Date? in
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                components.second = 0

                return calendar.nextDate(
                    after: now.addingTimeInterval(-1),
                    matching: components,
                    matchingPolicy: .nextTime,
                    repeatedTimePolicy: .first,
                    direction: .forward
                )
            }
        }

        return Array(Set(candidates))
            .sorted()
            .prefix(limit)
            .map { $0 }
    }
}
