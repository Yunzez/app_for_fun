import SwiftUI

struct ContentView: View {
    var body: some View {
        HabitListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(\.theme, .slate)
}
