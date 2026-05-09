import SwiftUI
import SwiftData

struct InboxView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    @Query(sort: [SortDescriptor(\TodoTask.sortOrder, order: .forward)])
    private var allTasks: [TodoTask]

    private var inboxTasks: [TodoTask] {
        allTasks.filter { $0.habit == nil }
    }

    private var openInboxTasks: [TodoTask] {
        inboxTasks.filter { !$0.isDone }
    }

    private var doneInboxTasks: [TodoTask] {
        inboxTasks.filter { $0.isDone }
    }

    @State private var creating: Bool = false
    @State private var editingTask: TodoTask?

    var body: some View {
        NavigationStack {
            List {
                if inboxTasks.isEmpty {
                    Section {
                        Text("Inbox is empty. Tap + to capture something.")
                            .foregroundStyle(theme.textSecondary)
                    }
                } else {
                    if !openInboxTasks.isEmpty {
                        Section {
                            ForEach(openInboxTasks) { task in
                                TaskRow(task: task) {
                                    editingTask = task
                                }
                            }
                            .onMove(perform: moveOpen)
                        }
                    }
                    if !doneInboxTasks.isEmpty {
                        Section("Done") {
                            ForEach(doneInboxTasks) { task in
                                TaskRow(task: task) {
                                    editingTask = task
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Inbox")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        creating = true
                    } label: {
                        Label("New Task", systemImage: "plus")
                    }
                }
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                #endif
            }
            .sheet(isPresented: $creating) {
                TaskEditorSheet(habit: nil)
            }
            .sheet(item: $editingTask) { task in
                TaskEditorSheet(task: task)
            }
        }
    }

    private func moveOpen(from offsets: IndexSet, to dest: Int) {
        var reorderedOpen = openInboxTasks
        reorderedOpen.move(fromOffsets: offsets, toOffset: dest)
        // Open tasks first, done tasks keep relative order at the end.
        let combined = reorderedOpen + doneInboxTasks
        HabitStore(context: context).reorderTasks(combined)
    }
}
