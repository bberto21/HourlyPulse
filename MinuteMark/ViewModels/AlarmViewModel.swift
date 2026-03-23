//
//  AlarmViewModel.swift
//  MinuteMark
//
//  Created by Admin on 3/17/26.
//

import Foundation
import Combine

@MainActor
final class AlarmViewModel: ObservableObject {
    @Published var minutes: [Int] = []
    @Published var startHour: Int = 9
    @Published var endHour: Int = 17
    @Published var soundName: String = "default"
    @Published private(set) var notificationAccessState: NotificationAccessState = .notDetermined
    @Published private(set) var pendingAlertCount: Int = 0
    @Published private(set) var scheduleStatus = AlarmStatusLogic.makeStatus(
        minutes: [],
        capacity: AlarmScheduleLogic.minuteCapacity(startHour: 9, endHour: 17),
        pendingAlertCount: 0,
        accessState: .notDetermined
    )

    private let notificationManager = NotificationManager()
    private let store = SettingsStore()
    private var selectionHistory: [Int] = []
    private var rejectedMinute: Int?

    init() {
        load()
        refreshNotificationStatus()
    }

    func toggleMinute(_ minute: Int, isOn: Bool) {
        if isOn {
            let capacity = AlarmScheduleLogic.minuteCapacity(startHour: startHour, endHour: endHour)
            if minutes.count >= capacity, !minutes.contains(minute) {
                rejectedMinute = minute
                refreshScheduleStatus()
                return
            }

            rejectedMinute = nil
            selectionHistory.removeAll { $0 == minute }
            selectionHistory.append(minute)
            minutes.append(minute)
        } else {
            rejectedMinute = nil
            minutes.removeAll { $0 == minute }
            selectionHistory.removeAll { $0 == minute }
        }

        minutes = Array(Set(minutes)).sorted()
        clampMinutesToCapacity()
        refreshScheduleStatus()
        syncAlarms()
    }

    func updateHours(startHour: Int? = nil, endHour: Int? = nil) {
        rejectedMinute = nil

        if let startHour {
            self.startHour = startHour
        }

        if let endHour {
            self.endHour = endHour
        }

        syncAlarms()
    }

    func resetHoursToCurrentRange() {
        rejectedMinute = nil
        startHour = Self.currentHour
        endHour = startHour
        syncAlarms()
    }

    func updateSoundName(_ soundName: String) {
        guard self.soundName != soundName else {
            return
        }

        rejectedMinute = nil
        self.soundName = soundName
        syncAlarms()
    }

    func enableAlerts() {
        notificationManager.requestPermission { [weak self] granted in
            Task { @MainActor in
                self?.notificationAccessState = granted ? .authorized : .denied
                self?.rejectedMinute = nil
                self?.refreshScheduleStatus()

                guard granted else { return }

                self?.syncAlarms()
            }
        }
    }

    func refreshPermissionState() {
        refreshNotificationStatus()
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
            pendingAlertCount = 0
            refreshScheduleStatus()
            return
        }

        guard notificationAccessState == .authorized else {
            refreshScheduleStatus()
            return
        }

        notificationManager.schedule(
            minutes: settings.minutes,
            startHour: settings.startHour,
            endHour: settings.endHour,
            soundName: settings.soundName
        )

        refreshPendingAlertCount { [weak self] in
            self?.refreshScheduleStatus()
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
        selectionHistory = settings.minutes
        startHour = settings.startHour
        endHour = settings.endHour
        soundName = settings.soundName
        clampMinutesToCapacity()
        refreshScheduleStatus()
    }

    private func clampMinutesToCapacity() {
        let capacity = AlarmScheduleLogic.minuteCapacity(startHour: startHour, endHour: endHour)

        guard minutes.count > capacity else {
            return
        }

        let preservedMinutes = AlarmScheduleLogic.clampedMinutesPreservingEarliest(
            selectionHistory: selectionHistory,
            startHour: startHour,
            endHour: endHour
        )
        selectionHistory = preservedMinutes
        minutes = preservedMinutes.sorted()
    }

    private func refreshNotificationStatus() {
        notificationManager.fetchAccessState { [weak self] state in
            Task { @MainActor in
                self?.notificationAccessState = state
                self?.refreshPendingAlertCount {
                    self?.refreshScheduleStatus()
                }
            }
        }
    }

    private func refreshPendingAlertCount(completion: (() -> Void)? = nil) {
        notificationManager.pendingRequestCount { [weak self] count in
            Task { @MainActor in
                self?.pendingAlertCount = count
                completion?()
            }
        }
    }

    private func refreshScheduleStatus() {
        let capacity = AlarmScheduleLogic.minuteCapacity(startHour: startHour, endHour: endHour)
        scheduleStatus = AlarmStatusLogic.makeStatus(
            minutes: minutes,
            capacity: capacity,
            pendingAlertCount: pendingAlertCount,
            accessState: notificationAccessState,
            rejectedMinute: rejectedMinute
        )
    }

    private static var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }
}
