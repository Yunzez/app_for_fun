import SwiftUI
import SwiftData

/// Section inside HabitDetailView that lists today's completed activity logs
/// (`completedAt` falls on today) for this habit. Lets the user add a new
/// retroactive log. Plans live in Today's Plan section, not here.
struct LogSection: View {
    @Environment(\.theme) private var theme

    let habit: Habit
    @Query private var allRecentLogs: [ActivityLog]

    @State private var creating: Bool = false
    @State private var editingLog: ActivityLog?

    init(habit: Habit) {
        self.habit = habit
        // Bound the fetch to recent logs so we don't pull the entire table;
        // do the today + habit + completed filter in Swift to avoid SwiftData
        // predicate gotchas with two-level optional chains and optional Dates.
        let earliest = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        _allRecentLogs = Query(
            filter: #Predicate<ActivityLog> { log in
                log.createdAt >= earliest
            },
            sort: [SortDescriptor(\ActivityLog.createdAt, order: .reverse)]
        )
    }

    private var todayLogs: [ActivityLog] {
        let cal = Calendar.current
        return allRecentLogs.filter { log in
            guard let completed = log.completedAt else { return false }
            return cal.isDate(completed, inSameDayAs: .now)
                && log.habit?.id == habit.id
        }
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
