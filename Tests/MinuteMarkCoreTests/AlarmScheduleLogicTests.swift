import Foundation
import Testing
@testable import MinuteMarkCore

struct AlarmScheduleLogicTests {
    @Test
    func activeHoursWrapAroundMidnight() {
        #expect(AlarmScheduleLogic.activeHours(startHour: 22, endHour: 1) == [22, 23, 0, 1])
    }

    @Test
    func minuteCapacityScalesWithHourCount() {
        #expect(AlarmScheduleLogic.minuteCapacity(startHour: 20, endHour: 20) == 64)
        #expect(AlarmScheduleLogic.minuteCapacity(startHour: 20, endHour: 23) == 16)
        #expect(AlarmScheduleLogic.minuteCapacity(startHour: 22, endHour: 1) == 16)
    }

    @Test
    func clampedMinutesPreserveEarliestSelections() {
        let minutes = [5, 10, 15, 20, 25]
        let clamped = AlarmScheduleLogic.clampedMinutesPreservingEarliest(
            selectionHistory: minutes,
            startHour: 8,
            endHour: 9,
            maximumRequests: 4
        )

        #expect(clamped == [5, 10])
    }

    @Test
    func upcomingAlertDatesReturnSortedFutureDates() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 17, hour: 20, minute: 10))
        )

        let alerts = AlarmScheduleLogic.upcomingAlertDates(
            now: now,
            minutes: [15, 45],
            startHour: 20,
            endHour: 21,
            limit: 4,
            calendar: calendar
        )

        let expected = [
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 17, hour: 20, minute: 15)),
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 17, hour: 20, minute: 45)),
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 17, hour: 21, minute: 15)),
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 17, hour: 21, minute: 45)),
        ].compactMap { $0 }

        #expect(alerts == expected)
    }
}
