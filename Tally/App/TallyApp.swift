import SwiftUI
import SwiftData

@main
struct TallyApp: App {
    let modelContainer: ModelContainer
    @State private var timerService = TimerService()
    @State private var healthKitService = HealthKitService()

    init() {
        do {
            modelContainer = try ModelContainerFactory.makeContainer()
        } catch {
            Self.logContainerError(error)
            fatalError("Unable to create SwiftData ModelContainer: \(error)")
        }
    }

    private static func logContainerError(_ error: Error) {
        let ns = error as NSError
        print("━━━ SwiftData ModelContainer init failed ━━━")
        print("domain: \(ns.domain)")
        print("code:   \(ns.code)")
        print("desc:   \(ns.localizedDescription)")
        if let reason = ns.localizedFailureReason { print("reason: \(reason)") }
        if let fix = ns.localizedRecoverySuggestion { print("fix:    \(fix)") }
        if !ns.userInfo.isEmpty {
            print("userInfo:")
            for (k, v) in ns.userInfo { print("  \(k) = \(v)") }
        }
        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? NSError {
            print("underlying:")
            print("  domain: \(underlying.domain)")
            print("  code:   \(underlying.code)")
            print("  desc:   \(underlying.localizedDescription)")
            for (k, v) in underlying.userInfo { print("  userInfo \(k) = \(v)") }
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.theme, .slate)
                .environment(timerService)
                .environment(healthKitService)
        }
        .modelContainer(modelContainer)
    }
}
