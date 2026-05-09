import Foundation
import SwiftData

@Model
final class TodoTask {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String? = nil
    var isDone: Bool = false
    var sortOrder: Int = 0
    var dueDate: Date? = nil
    var createdAt: Date = Date()
    var completedAt: Date? = nil

    /// `nil` ⇒ Inbox task. Non-nil ⇒ scoped to that habit.
    var habit: Habit?

    init(title: String, habit: Habit? = nil, sortOrder: Int = 0, dueDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.notes = nil
        self.isDone = false
        self.sortOrder = sortOrder
        self.dueDate = dueDate
        self.createdAt = .now
        self.completedAt = nil
        self.habit = habit
    }
}
