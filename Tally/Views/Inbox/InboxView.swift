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

    @State private var creating: Bool = false
    @State private var editingTask: TodoTask?

    var body: some View {
        NavigationStack {
            List {
                if inboxTasks.isEmpty {
                    Section {
                        Text("Inbox is empty. Tap + to capture something.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(inboxTasks) { task in
                        TaskRow(task: task) {
                            editingTask = task
                        }
                    }
                    .onMove(perform: move)
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

    private func move(from offsets: IndexSet, to dest: Int) {
        var reordered = inboxTasks
        reordered.move(fromOffsets: offsets, toOffset: dest)
        HabitStore(context: context).reorderTasks(reordered)
    }
}
