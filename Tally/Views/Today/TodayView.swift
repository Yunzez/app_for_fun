import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerService.self) private var timer
    @Environment(\.theme) private var theme

    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder, order: .forward)]
    )
    private var allHabits: [Habit]

    @State private var showCreateForm: Bool = false
    @State private var showSettings: Bool = false

    private var todaysHabits: [Habit] {
        allHabits.filter { $0.schedule.isScheduled(on: .now) }
    }

    var body: some View {
        NavigationStack {
            List {
                if todaysHabits.isEmpty {
                    Section {
                        Text(allHabits.isEmpty
                            ? "No habits yet. Add one in the Habits tab."
                            : "Nothing scheduled for today.")
                        .foregroundStyle(theme.textSecondary)
                    }
                } else {
                    ForEach(todaysHabits) { habit in
                        NavigationLink {
                            HabitDetailView(habit: habit)
                        } label: {
                            TodayHabitRow(habit: habit)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                quickLog(habit)
                            } label: {
                                quickLabel(habit)
                            }
                            .tint(theme.accentPrimary)
                        }
                    }
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateForm = true
                    } label: {
                        Label("New Habit", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateForm) {
                HabitFormView(habit: nil)
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheet()
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
}
