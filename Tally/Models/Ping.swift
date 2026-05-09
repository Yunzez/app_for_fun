import Foundation
import SwiftData

/// Placeholder model used only during M0 to verify SwiftData + CloudKit sync
/// before the real domain models are introduced. Removed in M1.
@Model
final class Ping {
    var id: UUID = UUID()
    var label: String = ""
    var createdAt: Date = Date()

    init(label: String, createdAt: Date = .now) {
        self.id = UUID()
        self.label = label
        self.createdAt = createdAt
    }
}
