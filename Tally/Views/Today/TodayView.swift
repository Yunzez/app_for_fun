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

    @Query(sort: [SortDescriptor(\ActivityLog.createdAt, order: .reverse)])
    private var allLogs: [ActivityLog]

    @State private var showCreateForm: Bool = false
    @State private var showSettings: Bool = false
    @State private var planCreating: Bool = false
    @State private var planEditing: ActivityLog?
    @State private var planCompleting: ActivityLog?

    private var todaysHabits: [Habit] {
        allHabits.filter { $0.isScheduledForToday() }
    }

    private var plans: [ActivityLog] {
        allLogs.filter { $0.completedAt == nil }
    }

    var body: some View {
        NavigationStack {
            List {
                planSection
                todaySection
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
            .sheet(isPresented: $planCreating) {
                PlanEditorSheet()
            }
            .sheet(item: $planEditing) { plan in
                PlanEditorSheet(plan: plan)
            }
            .sheet(item: $planCompleting) { plan in
                PlanCompletionSheet(plan: plan)
            }
        }
    }

    @ViewBuilder
    private var planSection: some View {
        Section {
            if plans.isEmpty {
                Text("No plans. Tap + to capture something you want to do.")
                    .foregroundStyle(theme.textSecondary)
                    .font(.caption)
            } else {
                ForEach(plans) { plan in
                    PlanRow(
                        plan: plan,
                        onEdit: { planEditing = plan },
                        onComplete: { planCompleting = plan }
                    )
                }
            }
        } header: {
            HStack {
                Text("Plan")
                Spacer()
                Button {
                    planCreating = true
                } label: {
                    Label("Add Plan", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.accentPrimary)
            }
        }
    }

    @ViewBuilder
    private var todaySection: some View {
        Section {
            if todaysHabits.isEmpty {
                Text(allHabits.isEmpty
                    ? "No habits yet. Add one with the + above."
                    : "Nothing scheduled for today.")
                .foregroundStyle(theme.textSecondary)
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
        } header: {
            Text("Today")
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
