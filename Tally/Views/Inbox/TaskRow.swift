import SwiftUI
import SwiftData

struct TaskRow: View {
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder, order: .forward)]
    )
    private var allHabits: [Habit]

    let task: TodoTask
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                HabitStore(context: context).toggleDone(task)
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isDone ? theme.success : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.isDone, color: theme.textSecondary)
                    .foregroundStyle(task.isDone ? theme.textSecondary : theme.textPrimary)
                if let due = task.dueDate {
                    Text(dueDateLabel(due))
                        .font(.caption)
                        .foregroundStyle(isOverdue(due) ? theme.error : theme.textSecondary)
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .contextMenu {
            Menu("Move to") {
                if task.habit != nil {
                    Button {
                        HabitStore(context: context).move(task, toHabit: nil)
                    } label: {
                        Label("Inbox", systemImage: "tray")
                    }
                }
                ForEach(allHabits.filter { $0.id != task.habit?.id }) { habit in
                    Button {
                        HabitStore(context: context).move(task, toHabit: habit)
                    } label: {
                        Label(habit.name, systemImage: habit.iconName)
                    }
                }
            }
            Button(role: .destructive) {
                HabitStore(context: context).delete(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func dueDateLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Due today" }
        if cal.isDateInYesterday(date) { return "Due yesterday" }
        if cal.isDateInTomorrow(date) { return "Due tomorrow" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "Due \(f.string(from: date))"
    }

    private func isOverdue(_ date: Date) -> Bool {
        guard !task.isDone else { return false }
        return Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: .now)
    }
}
