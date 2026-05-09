import SwiftUI

struct HabitTaskSection: View {
    let habit: Habit

    @Environment(\.theme) private var theme

    @State private var creating: Bool = false
    @State private var editingTask: TodoTask?

    private var tasks: [TodoTask] {
        habit.tasks.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tasks").font(.title3.weight(.semibold))
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
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                VStack(spacing: 0) {
                    ForEach(tasks) { task in
                        TaskRow(task: task) {
                            editingTask = task
                        }
                        .padding(.vertical, 6)
                        if task.id != tasks.last?.id {
                            Divider()
                        }
                    }
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
}
