import SwiftUI
import SwiftData

struct TaskEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    enum Mode {
        case create(habit: Habit?)
        case edit(TodoTask)
    }

    let mode: Mode

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = .now
    @State private var didLoad: Bool = false
    @FocusState private var titleFocused: Bool

    init(habit: Habit?) {
        self.mode = .create(habit: habit)
    }

    init(task: TodoTask) {
        self.mode = .edit(task)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("What needs doing?", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .foregroundStyle(.primary)
                            .focused($titleFocused)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("Optional", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .foregroundStyle(.primary)
                            .lineLimit(2...5)
                    }

                    Toggle("Due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker(
                            "Due",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(navTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(buttonLabel) { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 360)
        #endif
        .onAppear {
            if !didLoad {
                load()
                didLoad = true
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(200))
            if case .create = mode {
                titleFocused = true
            }
        }
    }

    private var navTitle: String {
        switch mode {
        case .create: "New Task"
        case .edit: "Edit Task"
        }
    }

    private var buttonLabel: String {
        switch mode {
        case .create: "Create"
        case .edit: "Save"
        }
    }

    private func load() {
        switch mode {
        case .create:
            title = ""
            notes = ""
            hasDueDate = false
            dueDate = .now
        case .edit(let task):
            title = task.title
            notes = task.notes ?? ""
            hasDueDate = task.dueDate != nil
            dueDate = task.dueDate ?? .now
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let due = hasDueDate ? dueDate : nil

        switch mode {
        case .create(let habit):
            let task = HabitStore(context: context).createTask(in: habit, title: trimmed)
            task.notes = cleanNotes.isEmpty ? nil : cleanNotes
            task.dueDate = due
        case .edit(let task):
            task.title = trimmed
            task.notes = cleanNotes.isEmpty ? nil : cleanNotes
            task.dueDate = due
        }
        dismiss()
    }
}
