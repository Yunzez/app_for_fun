import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(HealthKitService.self) private var hk
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle") }

            HabitListView()
                .tabItem { Label("Habits", systemImage: "list.bullet") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
        }
        .task {
            await hk.startIfEnabled(context: context)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await hk.syncOnForeground(context: context) }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(\.theme, .slate)
        .environment(TimerService())
        .environment(HealthKitService())
}
