import SwiftUI
import SwiftData

struct HabitListView: View {
    var dismissable: Bool = false

    @Environment(\.modelContext) private var context
    @Environment(TimerService.self) private var timer
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder, order: .forward)]
    )
    private var habits: [Habit]

    @State private var formMode: FormMode? = nil
    @State private var showSettings: Bool = false

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

    private struct Section_: Identifiable {
        let id: String
        let title: String
        let habits: [Habit]
    }

    /// Habits bucketed by schedule kind, in cadence order: Daily, Weekly,
    /// Monthly, Flexible. Empty buckets are dropped.
    private var sections: [Section_] {
        var daily: [Habit] = []
        var weekly: [Habit] = []
        var monthly: [Habit] = []
        var flexible: [Habit] = []
        for habit in habits {
            switch habit.schedule {
            case .daily: daily.append(habit)
            case .weekly: weekly.append(habit)
            case .monthly: monthly.append(habit)
            case .flexible: flexible.append(habit)
            }
        }
        var result: [Section_] = []
        if !daily.isEmpty { result.append(.init(id: "daily", title: "Daily", habits: daily)) }
        if !weekly.isEmpty { result.append(.init(id: "weekly", title: "Weekly", habits: weekly)) }
        if !monthly.isEmpty { result.append(.init(id: "monthly", title: "Monthly", habits: monthly)) }
        if !flexible.isEmpty { result.append(.init(id: "flexible", title: "Flexible", habits: flexible)) }
        return result
    }

    var body: some View {
        NavigationStack {
            List {
                if habits.isEmpty {
                    SwiftUI.Section {
                        Text("No habits yet. Tap + to add your first one.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(sections) { section in
                        SwiftUI.Section {
                            ForEach(section.habits) { habit in
                                row(for: habit)
                            }
                        } header: {
                            Text(section.title)
                        }
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                if dismissable {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
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
            }
            .sheet(item: $formMode) { mode in
                switch mode {
                case .create:
                    HabitFormView(habit: nil)
                case .edit(let habit):
                    HabitFormView(habit: habit)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheet()
            }
        }
    }

    @ViewBuilder
    private func row(for habit: Habit) -> some View {
        NavigationLink {
            HabitDetailView(habit: habit)
        } label: {
            TodayHabitRow(habit: habit)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                quickLog(habit)
            } label: {
                quickLabel(habit)
            }
            .tint(theme.accentPrimary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                archive(habit)
            } label: {
                Label("Archive", systemImage: "archivebox")
            }
            .tint(theme.accentSecondary)
        }
        .contextMenu {
            Button {
                formMode = .edit(habit)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
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
    }

    private func quickLog(_ habit: Habit) {
        switch habit.goalKind {
        case .count:
            HabitStore(context: context).adjust(habit, by: 1)
        case .duration:
            if timer.isActive(for: habit) {
                timer.stop(in: context)
            } else {
                timer.start(habit: habit, in: context)
            }
        }
    }

    @ViewBuilder
    private func quickLabel(_ habit: Habit) -> some View {
        switch habit.goalKind {
        case .count:
            Label("+1", systemImage: "plus")
        case .duration:
            if timer.isActive(for: habit) {
                Label("Stop", systemImage: "stop.fill")
            } else {
                Label("Start", systemImage: "play.fill")
            }
        }
    }

    private func archive(_ habit: Habit) {
        HabitStore(context: context).archive(habit)
    }

    private func delete(_ habit: Habit) {
        HabitStore(context: context).delete(habit)
    }
}
