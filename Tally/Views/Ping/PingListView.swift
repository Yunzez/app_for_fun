import SwiftUI
import SwiftData

struct PingListView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @Query(sort: \Ping.createdAt, order: .reverse) private var pings: [Ping]

    var body: some View {
        NavigationStack {
            List {
                if pings.isEmpty {
                    Section {
                        Text("No pings yet. Tap + to add one, then look for it on your other device.")
                            .foregroundStyle(theme.textSecondary)
                            .listRowBackground(theme.backgroundSecondary)
                    }
                } else {
                    ForEach(pings) { ping in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ping.label)
                                .foregroundStyle(theme.textPrimary)
                            Text(ping.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                        .listRowBackground(theme.backgroundSecondary)
                    }
                    .onDelete(perform: delete)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.backgroundPrimary)
            .navigationTitle("Sync Smoke Test")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addPing()
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .tint(theme.accentPrimary)
                }
            }
        }
    }

    private func addPing() {
        let ping = Ping(label: "Ping #\(pings.count + 1)")
        context.insert(ping)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(pings[index])
        }
    }
}
