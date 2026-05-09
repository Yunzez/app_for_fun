import Foundation
import SwiftData

/// Thin facade over `ModelContext` for write operations that need
/// business rules (e.g., one Entry per habit per day, sortOrder bookkeeping).
/// Reads use `@Query` directly in views.
@MainActor
struct HabitStore {
    let context: ModelContext

    // MARK: - Habits

    @discardableResult
    func createHabit(
        name: String,
        iconName: String,
        accentSlot: Int,
        goalKind: GoalKind,
        goalTarget: Double,
        schedule: HabitSchedule,
        reminderTime: Date?,
        healthBinding: HealthBinding?
    ) -> Habit {
        let nextSortOrder = (try? maxSortOrder() + 1) ?? 0
        let habit = Habit(
            name: name,
            iconName: iconName,
            accentSlot: accentSlot,
            goalKind: goalKind,
            goalTarget: goalTarget,
            schedule: schedule,
            reminderTime: reminderTime,
            healthBinding: healthBinding,
            sortOrder: nextSortOrder
        )
        context.insert(habit)
        return habit
    }

    func archive(_ habit: Habit) {
        habit.isArchived = true
    }

    func unarchive(_ habit: Habit) {
        habit.isArchived = false
    }

    func delete(_ habit: Habit) {
        context.delete(habit)
    }

    func reorder(_ habits: [Habit]) {
        for (index, habit) in habits.enumerated() {
            habit.sortOrder = index
        }
    }

    // MARK: - Entries

    /// Returns the habit's Entry for `date` (day-aligned), creating one if needed.
    @discardableResult
    func entry(for habit: Habit, on date: Date = .now) -> Entry {
        let day = Calendar.current.startOfDay(for: date)
        if let existing = habit.entries.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: day)
        }) {
            return existing
        }
        let entry = Entry(habit: habit, date: day)
        context.insert(entry)
        return entry
    }

    /// Adjust today's Entry value by `amount` (negative to decrement). Floors at 0.
    /// Marks the entry as manually edited so HealthKit auto-fill won't overwrite it.
    func adjust(_ habit: Habit, by amount: Double, on date: Date = .now) {
        let entry = entry(for: habit, on: date)
        entry.value = max(0, entry.value + amount)
        entry.source = .manual
    }

    /// Set today's Entry value directly. Used for manual corrections.
    /// Marks the entry as manually edited.
    func setValue(_ habit: Habit, to value: Double, on date: Date = .now) {
        let entry = entry(for: habit, on: date)
        entry.value = max(0, value)
        entry.source = .manual
    }

    /// Set today's Entry note (clears if `note` is nil or whitespace-only).
    func setNote(_ habit: Habit, to note: String?, on date: Date = .now) {
        let entry = entry(for: habit, on: date)
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.note = (trimmed?.isEmpty ?? true) ? nil : trimmed
    }

    // MARK: - Tasks

    /// Create a task. `habit == nil` puts it in the Inbox.
    @discardableResult
    func createTask(in habit: Habit?, title: String) -> TodoTask {
        let nextSort = (try? maxTaskSortOrder(in: habit) + 1) ?? 0
        let task = TodoTask(title: title, habit: habit, sortOrder: nextSort)
        context.insert(task)
        return task
    }

    func delete(_ task: TodoTask) {
        context.delete(task)
    }

    func toggleDone(_ task: TodoTask) {
        task.isDone.toggle()
        task.completedAt = task.isDone ? .now : nil
    }

    /// Move a task to a different container. `habit == nil` moves it to the Inbox.
    /// Per design §10 #5, this is a *move*: a task has exactly one container.
    func move(_ task: TodoTask, toHabit habit: Habit?) {
        task.habit = habit
        let nextSort = (try? maxTaskSortOrder(in: habit) + 1) ?? 0
        task.sortOrder = nextSort
    }

    /// Reorder a list of tasks. Sets `sortOrder` to match array order.
    func reorderTasks(_ tasks: [TodoTask]) {
        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
    }

    // MARK: - Internals

    private func maxSortOrder() throws -> Int {
        var descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let result = try context.fetch(descriptor)
        return result.first?.sortOrder ?? -1
    }

    private func maxTaskSortOrder(in habit: Habit?) throws -> Int {
        let all = try context.fetch(FetchDescriptor<TodoTask>())
        let scoped: [TodoTask]
        if let habit {
            scoped = all.filter { $0.habit?.id == habit.id }
        } else {
            scoped = all.filter { $0.habit == nil }
        }
        return scoped.map(\.sortOrder).max() ?? -1
    }
}
