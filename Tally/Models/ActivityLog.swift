import Foundation
import SwiftData

/// A user-added line item under a day's `Entry`. Captures *what* the user
/// actually did during the habit's time/units — e.g., "Bench press 3×8".
///
/// Loose attribution (design): creating a log with `value > 0` credits the
/// parent `Entry.value` once. Edits and deletes do NOT propagate. Treat the
/// log as a labelled credit, not a strict line item.
@Model
final class ActivityLog {
    var id: UUID = UUID()
    var title: String = ""
    var value: Double = 0
    var loggedAt: Date = Date()

    var entry: Entry?

    init(title: String, value: Double = 0, entry: Entry? = nil, loggedAt: Date = .now) {
        self.id = UUID()
        self.title = title
        self.value = value
        self.entry = entry
        self.loggedAt = loggedAt
    }
}
