import SwiftUI

struct ContentView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        PingListView()
            .background(theme.backgroundPrimary.ignoresSafeArea())
            .foregroundStyle(theme.textPrimary)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Ping.self, inMemory: true)
        .environment(\.theme, .slate)
}
