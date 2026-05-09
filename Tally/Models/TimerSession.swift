import Foundation
import SwiftData

@Model
final class TimerSession {
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var endedAt: Date? = nil
    var pausedAccumulated: TimeInterval = 0

    var entry: Entry?

    init(entry: Entry, startedAt: Date = .now) {
        self.id = UUID()
        self.entry = entry
        self.startedAt = startedAt
        self.endedAt = nil
        self.pausedAccumulated = 0
    }
}
