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
    var schedule: HabitSchedule = HabitSchedule.daily
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
        self.schedule = schedule
        self.reminderTime = reminderTime
        self.healthBinding = healthBinding
        self.sortOrder = sortOrder
        self.isArchived = false
        self.createdAt = .now
    }
}
