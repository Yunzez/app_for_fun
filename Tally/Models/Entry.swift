import Foundation
import SwiftData

@Model
final class Entry {
    var id: UUID = UUID()
    var date: Date = Date()
    var value: Double = 0
    var note: String? = nil
    var source: EntrySource? = nil
    var createdAt: Date = Date()

    var habit: Habit?

    @Relationship(deleteRule: .cascade, inverse: \TimerSession.entry)
    var sessions: [TimerSession] = []

    @Relationship(deleteRule: .cascade, inverse: \ActivityLog.entry)
    var logs: [ActivityLog] = []

    init(habit: Habit, date: Date, value: Double = 0, note: String? = nil, source: EntrySource? = nil) {
        self.id = UUID()
        self.habit = habit
        self.date = Calendar.current.startOfDay(for: date)
        self.value = value
        self.note = note
        self.source = source
        self.createdAt = .now
    }
}
