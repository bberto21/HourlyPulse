//
//  AlarmViewModel.swift
//  HourPulse
//
//  Created by Admin on 3/17/26.
//

import Foundation
import Combine
import WatchConnectivity

@MainActor
final class AlarmViewModel: ObservableObject {
    @Published var minutes: [Int] = []
    @Published var startHour: Int = 9
    @Published var endHour: Int = 17
    @Published var soundName: String = "default"

    private let notificationManager = NotificationManager()
    private let store = SettingsStore()

    init() {
        load()
    }

    func toggleMinute(_ minute: Int, isOn: Bool) {
        if isOn {
            minutes.append(minute)
        } else {
            minutes.removeAll { $0 == minute }
        }

        minutes = Array(Set(minutes)).sorted()
        syncAlarms()
    }

    func updateHours(startHour: Int? = nil, endHour: Int? = nil) {
        if let startHour {
            self.startHour = startHour
        }

        if let endHour {
            self.endHour = endHour
        }

        syncAlarms()
    }

    func updateSoundName(_ soundName: String) {
        guard self.soundName != soundName else {
            return
        }

        self.soundName = soundName
        syncAlarms()
    }

    func syncAlarms() {
        let settings = AlarmSettings(
            minutes: minutes,
            startHour: startHour,
            endHour: endHour,
            soundName: soundName
        )

        save()

        guard !settings.minutes.isEmpty else {
            notificationManager.clearAll()
            return
        }

        notificationManager.requestPermission { [weak self] granted in
            guard granted else {
                print("Notifications are disabled. Enable them in Settings to start alerts.")
                return
            }

            Task { @MainActor in
                self?.notificationManager.schedule(
                    minutes: settings.minutes,
                    startHour: settings.startHour,
                    endHour: settings.endHour,
                    soundName: settings.soundName
                )
            }
        }

        if WCSession.default.isReachable {
            WatchSessionManager.shared.send(settings: settings)
        }
    }

    private func save() {
        let settings = AlarmSettings(
            minutes: minutes,
            startHour: startHour,
            endHour: endHour,
            soundName: soundName
        )
        store.save(settings)
    }

    private func load() {
        let settings = store.load()
        minutes = settings.minutes
        startHour = settings.startHour
        endHour = settings.endHour
        soundName = settings.soundName
    }
}
