import SwiftUI

struct ContentView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        HabitListView()
            .background(theme.backgroundPrimary.ignoresSafeArea())
            .foregroundStyle(theme.textPrimary)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
        .environment(\.theme, .slate)
}
