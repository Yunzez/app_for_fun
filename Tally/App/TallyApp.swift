import SwiftUI
import SwiftData

@main
struct TallyApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainerFactory.makeContainer()
        } catch {
            fatalError("Unable to create SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.theme, .slate)
        }
        .modelContainer(modelContainer)
    }
}
