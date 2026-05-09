import Foundation
import SwiftData

enum ModelContainerFactory {
    /// Build the app's SwiftData container with CloudKit sync.
    /// `cloudKitDatabase: .automatic` reads the container identifier
    /// from the entitlements file at runtime.
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Ping.self
        ])
        let configuration = ModelConfiguration(
            "Tally",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
