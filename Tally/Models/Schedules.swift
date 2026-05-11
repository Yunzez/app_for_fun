import Foundation

enum GoalKind: String, Codable, Hashable, CaseIterable {
    case count
    case duration
}

/// Which side of the target counts as "winning".
///   .atLeast — meet or exceed the target (read 30 pages, walk 10k steps)
///   .atMost  — stay at or below the target (2000 cal, screen time)
enum GoalDirection: String, Codable, Hashable, CaseIterable {
    case atLeast
    case atMost

    var displayName: String {
        switch self {
        case .atLeast: "Aim for at least"
        case .atMost: "Stay under"
        }
    }
}

/// Where the value on an `Entry` came from. `.manual` always wins over
/// `.healthkit` — once the user touches an entry, HealthKit can't overwrite it.
enum EntrySource: String, Codable, Hashable {
    case manual
    case healthkit
}

enum Weekday: Int, Codable, Hashable, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var shortLabel: String {
        switch self {
        case .sunday: "S"
        case .monday: "M"
        case .tuesday: "T"
        case .wednesday: "W"
        case .thursday: "T"
        case .friday: "F"
        case .saturday: "S"
        }
    }

    var fullLabel: String {
        switch self {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        }
    }
}

enum HabitSchedule: Codable, Hashable {
    case daily
    case weekly(weekdays: Set<Weekday>)
    case monthly(daysOfMonth: Set<Int>)
    /// Cooldown schedule: re-appears on Today `everyDays` after last entry
    /// with activity. (Renamed semantically from "N times per week" on
    /// 2026-05-10 — old persisted `timesPerWeek` JSON no longer decodes and
    /// silently falls back to `.daily` in `Habit.schedule`.)
    case flexible(everyDays: Int)

    /// Pure date-based scheduling check (no habit history). For `.flexible`,
    /// this returns true and the cooldown is applied separately by
    /// `Habit.isScheduledForToday(_:)`.
    func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        switch self {
        case .daily:
            return true
        case .weekly(let days):
            let weekdayInt = calendar.component(.weekday, from: date)
            return days.contains(where: { $0.rawValue == weekdayInt })
        case .monthly(let days):
            let day = calendar.component(.day, from: date)
            return days.contains(day)
        case .flexible:
            return true
        }
    }
}

enum HealthBinding: String, Codable, Hashable, CaseIterable {
    case steps
    case activeEnergy
    case workoutDuration
    case sleepHours
    case mindfulMinutes

    var displayName: String {
        switch self {
        case .steps: "Steps"
        case .activeEnergy: "Active Energy"
        case .workoutDuration: "Workouts"
        case .sleepHours: "Sleep"
        case .mindfulMinutes: "Mindful Minutes"
        }
    }
}
