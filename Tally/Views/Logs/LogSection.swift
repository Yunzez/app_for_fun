import SwiftUI
import SwiftData

/// Section inside HabitDetailView that lists today's activity logs and
/// lets the user add new ones. Replaces the old task/inbox concept.
struct LogSection: View {
    @Environment(\.theme) private var theme

    let habit: Habit
    @Query private var todayLogs: [ActivityLog]

    @State private var creating: Bool = false
    @State private var editingLog: ActivityLog?

    init(habit: Habit) {
        self.habit = habit
        let habitID = habit.id
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        _todayLogs = Query(
            filter: #Predicate<ActivityLog> { log in
                log.loggedAt >= start
                && log.loggedAt < end
                && log.entry?.habit?.id == habitID
            },
            sort: [SortDescriptor(\ActivityLog.loggedAt, order: .reverse)]
        )
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
                        LogRow(log: log, goalKind: habit.goalKind) {
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
