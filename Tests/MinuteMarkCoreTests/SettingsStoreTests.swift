import Foundation
import Testing
@testable import MinuteMarkCore

struct SettingsStoreTests {
    @Test
    func loadReturnsCurrentHourDefaultsWhenNoSettingsExist() {
        let suiteName = "MinuteMarkCoreTests.defaults.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = SettingsStore(userDefaults: defaults)
        let settings = store.load()
        let currentHour = Calendar.current.component(.hour, from: Date())

        #expect(settings.minutes.isEmpty)
        #expect(settings.startHour == currentHour)
        #expect(settings.endHour == currentHour)
        #expect(settings.soundName == "default")
    }

    @Test
    func saveAndLoadRoundTripSettings() {
        let suiteName = "MinuteMarkCoreTests.persist.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = SettingsStore(userDefaults: defaults)
        let saved = AlarmSettings(minutes: [5, 30, 45], startHour: 9, endHour: 12, soundName: "cuckoo_clock.caf")

        store.save(saved)
        let loaded = store.load()

        #expect(loaded.minutes == saved.minutes)
        #expect(loaded.startHour == saved.startHour)
        #expect(loaded.endHour == saved.endHour)
        #expect(loaded.soundName == saved.soundName)
    }
}
