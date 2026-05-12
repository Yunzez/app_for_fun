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
        unit: String,
        direction: GoalDirection,
        schedule: HabitSchedule,
        showOnToday: Bool,
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
            unit: unit,
            direction: direction,
            schedule: schedule,
            showOnToday: showOnToday,
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

    // MARK: - Logs & Plans

    /// Add a completed log directly under `habit` (retroactive: "I did this").
    /// If `value > 0`, credits the entry once (loose attribution).
    @discardableResult
    func addLog(to habit: Habit, title: String, value: Double = 0, on date: Date = .now) -> ActivityLog {
        let log = ActivityLog(title: title, value: value, habit: habit, completedAt: date)
        context.insert(log)
        if value > 0 {
            let parent = entry(for: habit, on: date)
            parent.value += value
            parent.source = .manual
        }
        return log
    }

    /// Add a plan (pre-completion). `habit` is optional — nil = loose/inbox,
    /// user picks the habit when marking it done.
    @discardableResult
    func addPlan(title: String, value: Double = 0, habit: Habit? = nil) -> ActivityLog {
        let plan = ActivityLog(title: title, value: value, habit: habit, completedAt: nil)
        context.insert(plan)
        return plan
    }

    /// Mark a plan done and attribute to a habit. Credits the entry on the
    /// completion day if `value > 0`. Plan becomes a log.
    func complete(_ plan: ActivityLog, habit: Habit, value: Double, on date: Date = .now) {
        plan.habit = habit
        plan.value = value
        plan.completedAt = date
        if value > 0 {
            let parent = entry(for: habit, on: date)
            parent.value += value
            parent.source = .manual
        }
    }

    /// Update an existing log or plan in place. Per loose attribution, does
    /// NOT change the parent Entry.value.
    func updateLog(_ log: ActivityLog, title: String? = nil, value: Double? = nil) {
        if let title { log.title = title }
        if let value { log.value = value }
    }

    /// Delete a log or plan. Per loose attribution, does NOT subtract from
    /// Entry.value — the credit stays. Users can adjust the entry manually
    /// if they want to undo.
    func delete(_ log: ActivityLog) {
        context.delete(log)
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
}
