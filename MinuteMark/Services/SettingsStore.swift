//
//  SettingsStore.swift
//  MinuteMark
//
//  Created by Admin on 3/17/26.
//

import Foundation

class SettingsStore {
    private let key = "MinuteMarkSettings"
    private let legacyKey = "HourPulseSettings"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func save(_ settings: AlarmSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: key)
        }
    }

    func load() -> AlarmSettings {
        if let data = userDefaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(AlarmSettings.self, from: data) {
            return decoded
        }

        if let data = userDefaults.data(forKey: legacyKey),
           let decoded = try? JSONDecoder().decode(AlarmSettings.self, from: data) {
            userDefaults.set(data, forKey: key)
            userDefaults.removeObject(forKey: legacyKey)
            return decoded
        }

        let currentHour = Calendar.current.component(.hour, from: Date())
        return AlarmSettings(
            minutes: [],
            startHour: currentHour,
            endHour: currentHour,
            soundName: "default"
        )
    }
}
