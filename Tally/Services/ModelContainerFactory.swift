import Foundation
import SwiftData

enum ModelContainerFactory {
    /// Flip to `false` for a local-only store (no CloudKit sync).
    /// Useful when debugging container-init failures caused by a missing or
    /// misconfigured iCloud container in the Apple Developer account.
    static let useCloudKit: Bool = false

    /// Build the app's SwiftData container.
    /// When `useCloudKit` is true, `cloudKitDatabase: .automatic` reads the
    /// container identifier from the entitlements file at runtime.
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Habit.self,
            Entry.self,
            TimerSession.self,
            TodoTask.self
        ])
        let configuration = ModelConfiguration(
            "Tally",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: useCloudKit ? .automatic : .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
