import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle") }

            HabitListView()
                .tabItem { Label("Habits", systemImage: "list.bullet") }

            InboxView()
                .tabItem { Label("Inbox", systemImage: "tray") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(\.theme, .slate)
        .environment(TimerService())
}
