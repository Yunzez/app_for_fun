import Foundation
import SwiftData

/// A user-added line item. Lives in two states:
///   - **Plan**: `completedAt == nil`. The user typed it intending to do it
///     later. `habit` may be nil (loose / inbox) or pre-attached.
///   - **Log**: `completedAt != nil`. The user marked it done; if a habit
///     was attached and `value > 0`, it credited that habit's entry on
///     completion (loose attribution: subsequent edits/deletes do not
///     propagate back to the entry).
///
/// Plans are shown in the Plan section on Today. Logs are shown in the
/// destination habit's Logs section, scoped to their completion day.
@Model
final class ActivityLog {
    var id: UUID = UUID()
    var title: String = ""
    var value: Double = 0
    var habit: Habit?
    var createdAt: Date = Date()
    var completedAt: Date? = nil

    init(
        title: String,
        value: Double = 0,
        habit: Habit? = nil,
        completedAt: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.value = value
        self.habit = habit
        self.createdAt = .now
        self.completedAt = completedAt
    }

    var isPlan: Bool { completedAt == nil }
    var isCompleted: Bool { completedAt != nil }
}
