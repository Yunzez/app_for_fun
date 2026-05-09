import Foundation

enum GoalKind: String, Codable, Hashable, CaseIterable {
    case count
    case duration
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
    case flexible(timesPerWeek: Int)

    /// Whether this schedule is "scheduled" for a given calendar date.
    /// Used by Today view (M2) to filter habits.
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
