import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "checkmark.circle") }

            InboxView()
                .tabItem { Label("Inbox", systemImage: "tray") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(\.theme, .slate)
        .environment(TimerService())
}
