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
