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
        self.scheduleData = (try? JSONEncoder().encode(schedule)) ?? Data()
        self.reminderTime = reminderTime
        self.healthBinding = healthBinding
        self.sortOrder = sortOrder
        self.isArchived = false
        self.createdAt = .now
    }
}
