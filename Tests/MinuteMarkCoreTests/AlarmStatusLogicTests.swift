import Testing
@testable import MinuteMarkCore

struct AlarmStatusLogicTests {
    @Test
    func rejectedMinuteStatusTakesPriority() {
        let status = AlarmStatusLogic.makeStatus(
            minutes: [15],
            capacity: 1,
            pendingAlertCount: 1,
            accessState: .authorized,
            rejectedMinute: 45
        )

        #expect(status.title == "Minute Not Added")
        #expect(status.systemImage == "exclamationmark.circle.fill")
        #expect(status.message.contains(":45 was not added."))
    }

    @Test
    func deniedStatusExplainsSettingsRequirement() {
        let status = AlarmStatusLogic.makeStatus(
            minutes: [15],
            capacity: 8,
            pendingAlertCount: 0,
            accessState: .denied
        )

        #expect(status.title == "Notifications Disabled")
        #expect(status.systemImage == "exclamationmark.triangle.fill")
    }

    @Test
    func emptyAuthorizedStatusUsesCapacityGuidance() {
        let status = AlarmStatusLogic.makeStatus(
            minutes: [],
            capacity: 16,
            pendingAlertCount: 0,
            accessState: .authorized
        )

        #expect(status.title == "Notifications Ready")
        #expect(status.message == "Choose up to 16 minutes for the current active-hour range.")
    }

    @Test
    func scheduledStatusShowsPendingCount() {
        let status = AlarmStatusLogic.makeStatus(
            minutes: [0, 30],
            capacity: 16,
            pendingAlertCount: 8,
            accessState: .authorized
        )

        #expect(status.title == "Notifications Ready")
        #expect(status.message == "8/64 alerts scheduled.")
    }
}
