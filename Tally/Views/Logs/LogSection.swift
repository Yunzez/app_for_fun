import SwiftUI
import SwiftData

/// Section inside HabitDetailView that lists today's activity logs and
/// lets the user add new ones. Replaces the old task/inbox concept.
struct LogSection: View {
    @Environment(\.theme) private var theme

    let habit: Habit
    @Query private var allTodayLogs: [ActivityLog]

    @State private var creating: Bool = false
    @State private var editingLog: ActivityLog?

    init(habit: Habit) {
        self.habit = habit
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        // SwiftData can't translate two-level optional chains
        // (`log.entry?.habit?.id`) to SQL — it crashes at fetch with a
        // "Unsupported function expression TERNARY" exception. Fetch by date
        // only, then filter by habit in memory (volume is tiny).
        _allTodayLogs = Query(
            filter: #Predicate<ActivityLog> { log in
                log.loggedAt >= start && log.loggedAt < end
            },
            sort: [SortDescriptor(\ActivityLog.loggedAt, order: .reverse)]
        )
    }

    private var todayLogs: [ActivityLog] {
        allTodayLogs.filter { $0.entry?.habit?.id == habit.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle("Logs today")
                Spacer()
                Button {
                    creating = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .tint(theme.accentPrimary)
            }

            if todayLogs.isEmpty {
                Text("No logs yet. Add one to record what you did.")
                    .foregroundStyle(theme.textSecondary)
                    .font(.caption)
            } else {
                VStack(spacing: 0) {
                    ForEach(todayLogs) { log in
                        LogRow(log: log, habit: habit) {
                            editingLog = log
                        }
                        .padding(.vertical, 6)
                        if log.id != todayLogs.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $creating) {
            LogEditorSheet(habit: habit)
        }
        .sheet(item: $editingLog) { log in
            LogEditorSheet(log: log)
        }
    }
}
