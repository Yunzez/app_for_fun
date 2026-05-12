import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = "star.fill"
    var accentSlot: Int = 0
    var goalKind: GoalKind = GoalKind.count
    var goalTarget: Double = 1
    /// Custom unit label for count habits ("pages", "glasses"). Empty = no
    /// unit shown. Duration habits ignore this and always render "min".
    var unit: String = ""
    /// Optional to survive lightweight migration from before the field
    /// existed. Treat nil as `.atLeast`.
    var direction: GoalDirection? = nil

    /// Persisted JSON form of `schedule`. SwiftData can't natively persist
    /// `Codable` enums with `Set`-typed associated values (it errors with
    /// `Builtin.BridgeObject`), so we hand-roll Data backing with a computed
    /// accessor. Read/write through `schedule`, never `scheduleData`.
    private var scheduleData: Data = Data()

    var schedule: HabitSchedule {
        get {
            guard !scheduleData.isEmpty else { return .daily }
            return (try? JSONDecoder().decode(HabitSchedule.self, from: scheduleData)) ?? .daily
        }
        set {
            scheduleData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var reminderTime: Date? = nil
    var healthBinding: HealthBinding? = nil
    var sortOrder: Int = 0
    var isArchived: Bool = false
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Entry.habit)
    var entries: [Entry] = []

    @Relationship(deleteRule: .cascade, inverse: \ActivityLog.habit)
    var logs: [ActivityLog] = []

    /// `value` is in the native unit (raw count for `.count`, seconds for
    /// `.duration`). Renders with the habit's display unit.
    /// Examples: "12", "12 pages", "30 min".
    func formatValue(_ value: Double) -> String {
        switch goalKind {
        case .count:
            let v = Int(value)
            return unit.isEmpty ? "\(v)" : "\(v) \(unit)"
        case .duration:
            return "\(Int(value / 60)) min"
        }
    }

    /// Like `formatValue` but pairs value with the target.
    /// Examples: "12 / 30", "12 / 30 pages", "8 / 30 min".
    func formatProgress(_ value: Double) -> String {
        switch goalKind {
        case .count:
            let v = Int(value)
            let t = Int(goalTarget)
            return unit.isEmpty ? "\(v) / \(t)" : "\(v) / \(t) \(unit)"
        case .duration:
            return "\(Int(value / 60)) / \(Int(goalTarget / 60)) min"
        }
    }

    init(
        name: String,
        iconName: String = "star.fill",
        accentSlot: Int = 0,
        goalKind: GoalKind = .count,
        goalTarget: Double = 1,
        unit: String = "",
        direction: GoalDirection = .atLeast,
        schedule: HabitSchedule = .daily,
        reminderTime: Date? = nil,
        healthBinding: HealthBinding? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.accentSlot = accentSlot
        self.goalKind = goalKind
        self.goalTarget = goalTarget
        self.unit = unit
        self.direction = direction
        self.scheduleData = (try? JSONEncoder().encode(schedule)) ?? Data()
        self.reminderTime = reminderTime
        self.healthBinding = healthBinding
        self.sortOrder = sortOrder
        self.isArchived = false
        self.createdAt = .now
    }
}

extension Habit {
    /// Effective direction, falling back to `.atLeast` for legacy rows.
    var resolvedDirection: GoalDirection { direction ?? .atLeast }

    /// Is this habit scheduled to be done on `date`? Combines the schedule
    /// rule with (for `.flexible`) the cooldown since last active entry.
    /// Flexible habits also resolve to false once today already has activity
    /// — the cooldown is "do it, then come back in N days".
    func isScheduledForToday(_ date: Date = .now, calendar: Calendar = .current) -> Bool {
        switch schedule {
        case .daily, .weekly, .monthly:
            return schedule.isScheduled(on: date, calendar: calendar)
        case .flexible(let everyDays):
            if hasActivity(on: date, calendar: calendar) { return false }
            return daysSinceLastActivity(before: date, calendar: calendar) >= everyDays
        }
    }

    /// True if there's an entry with `value > 0` on the same day as `date`.
    func hasActivity(on date: Date, calendar: Calendar = .current) -> Bool {
        entries.contains { entry in
            entry.value > 0 && calendar.isDate(entry.date, inSameDayAs: date)
        }
    }

    /// Days between the most recent entry-with-activity strictly before
    /// `date` and `date` itself. Returns `.max` if no prior activity exists.
    func daysSinceLastActivity(before date: Date, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: date)
        let lastActive = entries
            .filter { $0.value > 0 && $0.date < today }
            .map { calendar.startOfDay(for: $0.date) }
            .max()
        guard let last = lastActive else { return .max }
        return calendar.dateComponents([.day], from: last, to: today).day ?? 0
    }

    /// Day-end streak rule: does `value` count toward the streak for this
    /// habit's direction? Liberal for atLeast (any activity > 0 passes —
    /// preserves the original "engagement counts" rule). Strict for atMost
    /// (must be > 0 and ≤ target — must engage *and* stay under).
    func successForStreak(_ value: Double) -> Bool {
        switch resolvedDirection {
        case .atLeast: return value > 0
        case .atMost: return value > 0 && value <= goalTarget
        }
    }

    /// Strict "did you hit the goal" check used for completion badges.
    /// Differs from `successForStreak` only for atLeast, where this requires
    /// `value >= target` rather than just any activity.
    func goalMet(_ value: Double) -> Bool {
        switch resolvedDirection {
        case .atLeast: return value >= goalTarget
        case .atMost: return value > 0 && value <= goalTarget
        }
    }
}
