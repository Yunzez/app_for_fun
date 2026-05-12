import SwiftUI

/// A single row in the Plan section. Tapping the row body edits; tapping
/// the empty circle marks it done (opens the completion sheet, where the
/// user picks a habit to attribute to and confirms the value).
struct PlanRow: View {
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    let plan: ActivityLog
    let onEdit: () -> Void
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: "circle")
                    .foregroundStyle(theme.textTertiary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(plan.title)
                    .foregroundStyle(theme.textPrimary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }

            Spacer(minLength: 8)
        }
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                HabitStore(context: context).delete(plan)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var subtitle: String {
        var parts: [String] = []
        if let habit = plan.habit {
            parts.append(habit.name)
        }
        if plan.value > 0 {
            if let habit = plan.habit {
                parts.append(habit.formatValue(plan.value))
            } else {
                parts.append("\(Int(plan.value))")
            }
        }
        return parts.joined(separator: " · ")
    }
}
