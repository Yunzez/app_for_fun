import SwiftUI

struct HabitTaskSection: View {
    let habit: Habit

    @Environment(\.theme) private var theme

    @State private var creating: Bool = false
    @State private var editingTask: TodoTask?

    private var tasks: [TodoTask] {
        habit.tasks.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var openTasks: [TodoTask] {
        tasks.filter { !$0.isDone }
    }

    private var doneTasks: [TodoTask] {
        tasks.filter { $0.isDone }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle("Tasks")
                Spacer()
                Button {
                    creating = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .tint(theme.accentPrimary)
            }

            if tasks.isEmpty {
                Text("No tasks. Add one to break this habit into steps.")
                    .foregroundStyle(theme.textSecondary)
                    .font(.caption)
            } else {
                if !openTasks.isEmpty {
                    taskGroup(openTasks)
                }
                if !doneTasks.isEmpty {
                    Text("Done")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textTertiary)
                        .textCase(.uppercase)
                        .padding(.top, openTasks.isEmpty ? 0 : 8)
                    taskGroup(doneTasks)
                }
            }
        }
        .sheet(isPresented: $creating) {
            TaskEditorSheet(habit: habit)
        }
        .sheet(item: $editingTask) { task in
            TaskEditorSheet(task: task)
        }
    }

    private func taskGroup(_ items: [TodoTask]) -> some View {
        VStack(spacing: 0) {
            ForEach(items) { task in
                TaskRow(task: task) {
                    editingTask = task
                }
                .padding(.vertical, 6)
                if task.id != items.last?.id {
                    Divider()
                }
            }
        }
    }
}
