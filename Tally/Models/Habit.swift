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

    @Relationship(deleteRule: .cascade, inverse: \TodoTask.habit)
    var tasks: [TodoTask] = []

    init(
        name: String,
        iconName: String = "star.fill",
        accentSlot: Int = 0,
        goalKind: GoalKind = .count,
        goalTarget: Double = 1,
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
        self.scheduleData = (try? JSONEncoder().encode(schedule)) ?? Data()
        self.reminderTime = reminderTime
        self.healthBinding = healthBinding
        self.sortOrder = sortOrder
        self.isArchived = false
        self.createdAt = .now
    }
}
