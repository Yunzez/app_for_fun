import SwiftUI
import SwiftData

struct HabitFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    /// nil = creating a new habit; non-nil = editing.
    let habit: Habit?

    @State private var name: String = ""
    @State private var iconName: String = "star.fill"
    @State private var accentSlot: Int = 0
    @State private var goalKind: GoalKind = .count
    @State private var countTarget: Int = 1
    @State private var durationMinutes: Int = 30
    @State private var scheduleKind: ScheduleKind = .daily
    @State private var weeklyDays: Set<Weekday> = [.monday, .wednesday, .friday]
    @State private var monthlyDays: Set<Int> = [1]
    @State private var flexibleTimes: Int = 3
    @State private var hasReminder: Bool = false
    @State private var reminderTime: Date = HabitFormView.defaultReminderTime
    @State private var healthBinding: HealthBinding? = nil

    @State private var didLoad: Bool = false

    enum ScheduleKind: String, CaseIterable, Identifiable {
        case daily, weekly, monthly, flexible
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .daily: "Daily"
            case .weekly: "Weekly"
            case .monthly: "Monthly"
            case .flexible: "Flexible"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                BasicsSection(
                    name: $name,
                    iconName: $iconName,
                    accentSlot: $accentSlot,
                    palette: theme.habitPalette
                )
                GoalSection(
                    goalKind: $goalKind,
                    countTarget: $countTarget,
                    durationMinutes: $durationMinutes
                )
                ScheduleSection(
                    scheduleKind: $scheduleKind,
                    weeklyDays: $weeklyDays,
                    monthlyDays: $monthlyDays,
                    flexibleTimes: $flexibleTimes
                )
                ReminderSection(hasReminder: $hasReminder, reminderTime: $reminderTime)
                HealthSection(binding: $healthBinding)
            }
            .navigationTitle(habit == nil ? "New Habit" : "Edit Habit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(habit == nil ? "Create" : "Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            if !didLoad {
                loadFromHabit()
                didLoad = true
            }
        }
    }

    // MARK: - Load / Save

    private func loadFromHabit() {
        guard let habit else { return }
        name = habit.name
        iconName = habit.iconName
        accentSlot = habit.accentSlot
        goalKind = habit.goalKind
        switch habit.goalKind {
        case .count:
            countTarget = max(1, Int(habit.goalTarget))
        case .duration:
            durationMinutes = max(1, Int(habit.goalTarget / 60))
        }
        switch habit.schedule {
        case .daily:
            scheduleKind = .daily
        case .weekly(let days):
            scheduleKind = .weekly
            weeklyDays = days
        case .monthly(let days):
            scheduleKind = .monthly
            monthlyDays = days
        case .flexible(let n):
            scheduleKind = .flexible
            flexibleTimes = n
        }
        if let r = habit.reminderTime {
            hasReminder = true
            reminderTime = r
        }
        healthBinding = habit.healthBinding
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let target: Double = goalKind == .count
            ? Double(countTarget)
            : Double(durationMinutes * 60)
        let schedule: HabitSchedule = {
            switch scheduleKind {
            case .daily: return .daily
            case .weekly: return .weekly(weekdays: weeklyDays.isEmpty ? [.monday] : weeklyDays)
            case .monthly: return .monthly(daysOfMonth: monthlyDays.isEmpty ? [1] : monthlyDays)
            case .flexible: return .flexible(timesPerWeek: max(1, flexibleTimes))
            }
        }()
        let reminder: Date? = hasReminder ? reminderTime : nil

        if let habit {
            habit.name = trimmed
            habit.iconName = iconName
            habit.accentSlot = accentSlot
            habit.goalKind = goalKind
            habit.goalTarget = target
            habit.schedule = schedule
            habit.reminderTime = reminder
            habit.healthBinding = healthBinding
        } else {
            HabitStore(context: context).createHabit(
                name: trimmed,
                iconName: iconName,
                accentSlot: accentSlot,
                goalKind: goalKind,
                goalTarget: target,
                schedule: schedule,
                reminderTime: reminder,
                healthBinding: healthBinding
            )
        }
        dismiss()
    }

    private static var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    }
}

// MARK: - Sections

private struct BasicsSection: View {
    @Environment(\.theme) private var theme
    @Binding var name: String
    @Binding var iconName: String
    @Binding var accentSlot: Int
    let palette: [Color]

    var body: some View {
        Section("Basics") {
            TextField("Name", text: $name)
            IconPicker(selected: $iconName)
            AccentPicker(selected: $accentSlot, palette: palette)
        }
    }
}

private struct GoalSection: View {
    @Binding var goalKind: GoalKind
    @Binding var countTarget: Int
    @Binding var durationMinutes: Int

    var body: some View {
        Section("Goal") {
            Picker("Kind", selection: $goalKind) {
                Text("Count").tag(GoalKind.count)
                Text("Duration").tag(GoalKind.duration)
            }
            .pickerStyle(.segmented)

            switch goalKind {
            case .count:
                Stepper(value: $countTarget, in: 1...999) {
                    HStack {
                        Text("Target")
                        Spacer()
                        Text("\(countTarget)×").foregroundStyle(.secondary)
                    }
                }
            case .duration:
                Stepper(value: $durationMinutes, in: 1...600, step: 5) {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(formatDuration(durationMinutes)).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func formatDuration(_ m: Int) -> String {
        if m < 60 { return "\(m) min" }
        let h = m / 60, r = m % 60
        return r == 0 ? "\(h) hr" : "\(h) hr \(r) min"
    }
}

private struct ScheduleSection: View {
    @Binding var scheduleKind: HabitFormView.ScheduleKind
    @Binding var weeklyDays: Set<Weekday>
    @Binding var monthlyDays: Set<Int>
    @Binding var flexibleTimes: Int

    var body: some View {
        Section("Schedule") {
            Picker("Repeat", selection: $scheduleKind) {
                ForEach(HabitFormView.ScheduleKind.allCases) { k in
                    Text(k.displayName).tag(k)
                }
            }

            switch scheduleKind {
            case .daily:
                EmptyView()
            case .weekly:
                WeekdayPicker(selected: $weeklyDays)
            case .monthly:
                MonthDayPicker(selected: $monthlyDays)
            case .flexible:
                Stepper(value: $flexibleTimes, in: 1...7) {
                    HStack {
                        Text("Times per week")
                        Spacer()
                        Text("\(flexibleTimes)").foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct WeekdayPicker: View {
    @Environment(\.theme) private var theme
    @Binding var selected: Set<Weekday>

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Weekday.allCases) { day in
                let on = selected.contains(day)
                Button {
                    if on { selected.remove(day) } else { selected.insert(day) }
                } label: {
                    Text(day.shortLabel)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(on ? theme.accentPrimary : theme.backgroundTertiary)
                        .foregroundStyle(on ? theme.backgroundPrimary : theme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MonthDayPicker: View {
    @Environment(\.theme) private var theme
    @Binding var selected: Set<Int>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(1...31, id: \.self) { day in
                let on = selected.contains(day)
                Button {
                    if on { selected.remove(day) } else { selected.insert(day) }
                } label: {
                    Text("\(day)")
                        .font(.caption)
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(on ? theme.accentPrimary : theme.backgroundTertiary)
                        .foregroundStyle(on ? theme.backgroundPrimary : theme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ReminderSection: View {
    @Binding var hasReminder: Bool
    @Binding var reminderTime: Date

    var body: some View {
        Section("Reminder") {
            Toggle("Daily reminder", isOn: $hasReminder)
            if hasReminder {
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
            }
        }
    }
}

private struct HealthSection: View {
    @Binding var binding: HealthBinding?

    var body: some View {
        Section("Health Auto-Fill") {
            Picker("Source", selection: $binding) {
                Text("None").tag(nil as HealthBinding?)
                Text("Steps").tag(HealthBinding.steps as HealthBinding?)
                Text("Active Energy").tag(HealthBinding.activeEnergy as HealthBinding?)
                Text("Workouts").tag(HealthBinding.workoutDuration as HealthBinding?)
                Text("Sleep").tag(HealthBinding.sleepHours as HealthBinding?)
                Text("Mindful Minutes").tag(HealthBinding.mindfulMinutes as HealthBinding?)
            }
        }
    }
}

private struct IconPicker: View {
    @Environment(\.theme) private var theme
    @Binding var selected: String

    private let icons: [String] = [
        "star.fill", "flame.fill", "heart.fill", "moon.fill", "sun.max.fill",
        "bolt.fill", "drop.fill", "leaf.fill", "book.fill", "pencil",
        "figure.run", "figure.walk", "figure.strengthtraining.traditional",
        "dumbbell.fill", "fork.knife", "cup.and.saucer.fill",
        "headphones", "music.note", "paintbrush.fill", "camera.fill",
        "globe", "house.fill", "briefcase.fill", "graduationcap.fill"
    ]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .foregroundStyle(theme.textSecondary)
                .font(.subheadline)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(icons, id: \.self) { icon in
                    let on = selected == icon
                    Button {
                        selected = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(on ? theme.accentPrimary.opacity(0.2) : theme.backgroundTertiary)
                            .foregroundStyle(on ? theme.accentPrimary : theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AccentPicker: View {
    @Environment(\.theme) private var theme
    @Binding var selected: Int
    let palette: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .foregroundStyle(theme.textSecondary)
                .font(.subheadline)
            HStack(spacing: 10) {
                ForEach(0..<palette.count, id: \.self) { i in
                    Button {
                        selected = i
                    } label: {
                        ZStack {
                            Circle()
                                .fill(palette[i])
                                .frame(width: 28, height: 28)
                            if i == selected {
                                Circle()
                                    .strokeBorder(theme.textPrimary, lineWidth: 2)
                                    .frame(width: 32, height: 32)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
