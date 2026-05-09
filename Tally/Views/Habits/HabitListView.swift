import SwiftUI
import SwiftData

struct HabitListView: View {
    var dismissable: Bool = false

    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder, order: .forward)]
    )
    private var habits: [Habit]

    @State private var formMode: FormMode? = nil

    enum FormMode: Identifiable {
        case create
        case edit(Habit)

        var id: String {
            switch self {
            case .create: "create"
            case .edit(let habit): habit.id.uuidString
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if habits.isEmpty {
                    Section {
                        Text("No habits yet. Tap + to add your first one.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(habits) { habit in
                        HabitRow(habit: habit)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                formMode = .edit(habit)
                            }
                            .contextMenu {
                                Button {
                                    archive(habit)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                Button(role: .destructive) {
                                    delete(habit)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    archive(habit)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(theme.accentSecondary)
                            }
                    }
                    .onMove(perform: move)
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                if dismissable {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        formMode = .create
                    } label: {
                        Label("Add habit", systemImage: "plus")
                    }
                    .tint(theme.accentPrimary)
                }
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .tint(theme.accentPrimary)
                }
                #endif
            }
            .sheet(item: $formMode) { mode in
                switch mode {
                case .create:
                    HabitFormView(habit: nil)
                case .edit(let habit):
                    HabitFormView(habit: habit)
                }
            }
        }
    }

    private func archive(_ habit: Habit) {
        HabitStore(context: context).archive(habit)
    }

    private func delete(_ habit: Habit) {
        HabitStore(context: context).delete(habit)
    }

    private func move(from offsets: IndexSet, to destination: Int) {
        var reordered = habits
        reordered.move(fromOffsets: offsets, toOffset: destination)
        HabitStore(context: context).reorder(reordered)
    }
}
