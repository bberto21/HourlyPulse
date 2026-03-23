import Combine
import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    private let allMinutes = Array(0..<60)
    private let availableSounds: [(title: String, fileName: String)] = [
        ("Default", "default"),
        ("Cuckoo Clock", "cuckoo_clock.caf")
    ]

    @State private var selectedStartHour: Int = 9
    @State private var selectedEndHour: Int = 17
    @State private var selectedSoundName: String = "default"
    @State private var upcomingAlerts: [UpcomingAlert] = []

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    private let minuteColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    private let selectedMinuteColumns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.07, green: 0.09, blue: 0.14),
                    Color(red: 0.93, green: 0.95, blue: 0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    heroSection
                    selectedMinutesSection
                    activeHoursSection
                    minutesSection
                    soundSection
                    upcomingAlertsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
        }
        .safeAreaInset(edge: .top) {
            Color.black
                .frame(height: 0)
                .background(Color.black)
        }
        .onAppear {
            selectedStartHour = viewModel.startHour
            selectedEndHour = viewModel.endHour
            selectedSoundName = viewModel.soundName
            refreshUpcomingAlerts()
        }
        .onReceive(timer) { _ in
            refreshUpcomingAlerts()
        }
        .onChange(of: selectedStartHour) { _, newValue in
            viewModel.updateHours(startHour: newValue)
            refreshUpcomingAlerts()
        }
        .onChange(of: selectedEndHour) { _, newValue in
            viewModel.updateHours(endHour: newValue)
            refreshUpcomingAlerts()
        }
        .onChange(of: selectedSoundName) { _, newValue in
            viewModel.updateSoundName(newValue)
        }
        .onChange(of: viewModel.minutes) { _, _ in
            refreshUpcomingAlerts()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            viewModel.refreshPermissionState()
        }
    }

    private var heroSection: some View {
        HStack(spacing: 18) {
            Image("BrandMark")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text("MinuteMark Alerts")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Repeat alerts in your chosen work window.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.72))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private var selectedMinutesSection: some View {
        sectionCard(
            title: "Selected Minutes",
            subtitle: "Selections schedule immediately. Limit: \(minuteCapacity) minute\(minuteCapacity == 1 ? "" : "s") for this range."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Label(viewModel.scheduleStatus.title, systemImage: viewModel.scheduleStatus.systemImage)
                    .font(.subheadline.weight(.semibold))

                Text(viewModel.scheduleStatus.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if viewModel.notificationAccessState == .notDetermined {
                    Button("Enable Alerts") {
                        viewModel.enableAlerts()
                    }
                    .buttonStyle(.borderedProminent)
                } else if viewModel.notificationAccessState == .denied {
                    HStack(spacing: 12) {
                        Button("Enable Alerts") {
                            viewModel.enableAlerts()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Open Settings") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }
                            openURL(url)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if viewModel.minutes.isEmpty {
                    Text("Choose any minute below to start building your alert rhythm.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    LazyVGrid(columns: selectedMinuteColumns, alignment: .center, spacing: 12) {
                        ForEach(viewModel.minutes, id: \.self) { minute in
                            Text(String(format: ":%02d", minute))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.accentColor,
                                                    Color.accentColor.opacity(0.7)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private var activeHoursSection: some View {
        sectionCard(title: "Active Hours", subtitle: "Start at the current hour for the most alerts, then extend the end hour as needed.") {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Spacer()
                    Button("Reset to Current Hour") {
                        viewModel.resetHoursToCurrentRange()
                        selectedStartHour = viewModel.startHour
                        selectedEndHour = viewModel.endHour
                        refreshUpcomingAlerts()
                    }
                    .buttonStyle(.bordered)
                }

                VStack(spacing: 12) {
                    hourControlRow(title: "Start", hour: $selectedStartHour)
                    hourControlRow(title: "End", hour: $selectedEndHour)
                }
            }
        }
    }

    private var minutesSection: some View {
        sectionCard(
            title: "Minutes",
            subtitle: "\(viewModel.minutes.count)/\(minuteCapacity) selected for the current active hours."
        ) {
            LazyVGrid(columns: minuteColumns, spacing: 10) {
                ForEach(allMinutes, id: \.self) { minute in
                    let isSelected = viewModel.minutes.contains(minute)

                    Button {
                        viewModel.toggleMinute(minute, isOn: !isSelected)
                        refreshUpcomingAlerts()
                    } label: {
                        Text(String(format: "%02d", minute))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(isSelected ? Color.accentColor : Color.black.opacity(0.05), lineWidth: 1)
                            )
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var soundSection: some View {
        sectionCard(title: "Sound", subtitle: "Choose the tone for each alert.") {
            HStack(spacing: 8) {
                ForEach(availableSounds, id: \.fileName) { sound in
                    Button {
                        selectedSoundName = sound.fileName
                    } label: {
                        Text(sound.title)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(selectedSoundName == sound.fileName ? Color.white : Color.black.opacity(0.85))
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selectedSoundName == sound.fileName ? Color.accentColor : Color.white)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.05))
            )
        }
    }

    private var upcomingAlertsSection: some View {
        sectionCard(title: "Upcoming Alerts", subtitle: "Live preview of the next scheduled times.") {
            VStack(alignment: .leading, spacing: 14) {
                if let nextAlert = upcomingAlerts.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next alert")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(nextAlert.timeText)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text(nextAlert.relativeText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.black.opacity(0.04))
                    )
                } else {
                    Text("No alerts scheduled")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if upcomingAlerts.isEmpty {
                    Text("Select at least one minute to preview the upcoming schedule.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 10) {
                        ForEach(upcomingAlerts) { alert in
                            HStack {
                                Text(alert.timeText)
                                    .font(.body.monospacedDigit())
                                Spacer()
                                Text(alert.relativeText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)

                            if alert.id != upcomingAlerts.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.88))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.black.opacity(0.62))
            }

            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Color.black.opacity(0.85))
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.97))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
    }

    private func hourControlRow(title: String, hour: Binding<Int>) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(width: 48, alignment: .leading)
            Spacer()
            Text(String(format: "%02d:00", hour.wrappedValue))
                .font(.system(.body, design: .rounded, weight: .bold))
                .monospacedDigit()
            Spacer()
                .frame(width: 16)
            Stepper("", value: hour, in: 0...23)
                .labelsHidden()
                .fixedSize()
        }
        .frame(minHeight: 32, alignment: .center)
        .padding(.horizontal, 2)
    }

    private func refreshUpcomingAlerts() {
        upcomingAlerts = buildUpcomingAlerts(limit: 8)
    }

    private var minuteCapacity: Int {
        AlarmScheduleLogic.minuteCapacity(startHour: viewModel.startHour, endHour: viewModel.endHour)
    }

    private func buildUpcomingAlerts(limit: Int) -> [UpcomingAlert] {
        let now = Date()
        return AlarmScheduleLogic.upcomingAlertDates(
            now: now,
            minutes: viewModel.minutes,
            startHour: viewModel.startHour,
            endHour: viewModel.endHour,
            limit: limit
        )
            .map { date in
                UpcomingAlert(date: date, now: now)
            }
    }

    private func activeHours() -> [Int] {
        AlarmScheduleLogic.activeHours(startHour: viewModel.startHour, endHour: viewModel.endHour)
    }
}

private struct UpcomingAlert: Identifiable, Hashable {
    let date: Date
    let minutesUntil: Int

    var id: Date { date }

    init(date: Date, now: Date) {
        self.date = date
        minutesUntil = max(Int(date.timeIntervalSince(now).rounded(.down) / 60), 0)
    }

    var timeText: String {
        date.formatted(.dateTime.hour().minute())
    }

    var relativeText: String {
        if minutesUntil == 0 {
            return "now"
        }

        if minutesUntil == 1 {
            return "in 1 min"
        }

        return "in \(minutesUntil) min"
    }
}
