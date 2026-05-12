import SwiftUI
import SwiftData

/// The "Tasks" tab — lists incomplete plans (ActivityLogs with
/// `completedAt == nil`). User taps the circle to mark one done and attribute
/// it to a habit. Habits live in their own tab.
struct TodayView: View {
    @Environment(\.theme) private var theme

    @Query(sort: [SortDescriptor(\ActivityLog.createdAt, order: .reverse)])
    private var allLogs: [ActivityLog]

    @State private var planCreating: Bool = false
    @State private var planEditing: ActivityLog?
    @State private var planCompleting: ActivityLog?

    private var plans: [ActivityLog] {
        allLogs.filter { $0.completedAt == nil }
    }

    var body: some View {
        NavigationStack {
            List {
                if plans.isEmpty {
                    Section {
                        Text("No tasks yet. Tap + to capture something you want to do.")
                            .foregroundStyle(theme.textSecondary)
                    }
                } else {
                    ForEach(plans) { plan in
                        PlanRow(
                            plan: plan,
                            onEdit: { planEditing = plan },
                            onComplete: { planCompleting = plan }
                        )
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        planCreating = true
                    } label: {
                        Label("New Task", systemImage: "plus")
                    }
                    .tint(theme.accentPrimary)
                }
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
}
