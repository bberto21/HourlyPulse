import Combine
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AlarmViewModel

    private let allMinutes = Array(0..<60)
    private let availableSounds: [(title: String, fileName: String)] = [
        ("Default", "default"),
        ("Cuckoo Clock", "cuckoo_clock.caf")
    ]

    @State private var selectedStartHour: Int = 9
    @State private var selectedEndHour: Int = 17
    @State private var isAlwaysActive: Bool = true
    @State private var selectedSoundName: String = "default"
    @State private var upcomingAlerts: [UpcomingAlert] = []

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    private let minuteColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    private let selectedMinuteColumns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
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

                Color.black
                    .frame(height: proxy.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        heroSection
                        selectedMinutesSection
                        activeHoursSection
                        minutesSection
                        soundSection
                        upcomingAlertsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, max(proxy.safeAreaInsets.top, 12) + 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            isAlwaysActive = viewModel.isAlwaysActive
            selectedStartHour = viewModel.startHour
            selectedEndHour = viewModel.endHour
            selectedSoundName = viewModel.soundName
            refreshUpcomingAlerts()
        }
        .onReceive(timer) { _ in
            refreshUpcomingAlerts()
        }
        .onChange(of: isAlwaysActive) { _, newValue in
            viewModel.updateActiveHoursMode(isAlwaysActive: newValue)
            refreshUpcomingAlerts()
        }
        .onChange(of: selectedStartHour) { _, newValue in
            guard !isAlwaysActive else {
                return
            }

            viewModel.updateHours(startHour: newValue)
            refreshUpcomingAlerts()
        }
        .onChange(of: selectedEndHour) { _, newValue in
            guard !isAlwaysActive else {
                return
            }

            viewModel.updateHours(endHour: newValue)
            refreshUpcomingAlerts()
        }
        .onChange(of: selectedSoundName) { _, newValue in
            viewModel.updateSoundName(newValue)
        }
        .onChange(of: viewModel.minutes) { _, _ in
            refreshUpcomingAlerts()
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HourPulse")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Set repeating minute chimes with a cleaner live schedule.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.72))
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
        sectionCard(title: "Selected Minutes", subtitle: "Selections schedule immediately.") {
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

    private var activeHoursSection: some View {
        sectionCard(title: "Active Hours", subtitle: "Always is the default, or switch to a custom range.") {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Mode", selection: $isAlwaysActive) {
                    Text("Always").tag(true)
                    Text("Custom").tag(false)
                }
                .pickerStyle(.segmented)

                if isAlwaysActive {
                    Text("Alerts can fire at every selected minute across the full day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        hourRow(title: "Start", hour: selectedStartHour)
                        Stepper("", value: $selectedStartHour, in: 0...23)
                            .labelsHidden()

                        hourRow(title: "End", hour: selectedEndHour)
                        Stepper("", value: $selectedEndHour, in: 0...23)
                            .labelsHidden()
                    }
                }
            }
        }
    }

    private var minutesSection: some View {
        sectionCard(title: "Minutes", subtitle: "Tap to toggle the repeating minutes you want.") {
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
            Picker("Sound", selection: $selectedSoundName) {
                ForEach(availableSounds, id: \.fileName) { sound in
                    Text(sound.title).tag(sound.fileName)
                }
            }
            .pickerStyle(.segmented)
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
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private func hourRow(title: String, hour: Int) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(String(format: "%02d:00", hour))
                .font(.system(.body, design: .rounded, weight: .bold))
                .monospacedDigit()
        }
        .padding(.horizontal, 2)
    }

    private func refreshUpcomingAlerts() {
        upcomingAlerts = buildUpcomingAlerts(limit: 8)
    }

    private func buildUpcomingAlerts(limit: Int) -> [UpcomingAlert] {
        guard !viewModel.minutes.isEmpty else {
            return []
        }

        let now = Date()
        let calendar = Calendar.current

        let candidates = activeHours().flatMap { hour in
            viewModel.minutes.compactMap { minute -> Date? in
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
            .map { date in
                UpcomingAlert(date: date, now: now)
            }
    }

    private func activeHours() -> [Int] {
        if viewModel.isAlwaysActive {
            return Array(0...23)
        }

        if viewModel.startHour <= viewModel.endHour {
            return Array(viewModel.startHour...viewModel.endHour)
        }

        return Array(viewModel.startHour...23) + Array(0...viewModel.endHour)
    }
}

private struct UpcomingAlert: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let minutesUntil: Int

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
