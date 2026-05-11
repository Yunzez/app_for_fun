import SwiftUI

struct LogRow: View {
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    let log: ActivityLog
    let habit: Habit
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(log.title)
                    .foregroundStyle(theme.textPrimary)
                Text(timeLabel)
                    .font(.caption)
                    .foregroundStyle(theme.textTertiary)
            }
            Spacer(minLength: 8)
            if log.value > 0 {
                Text("+\(habit.formatValue(log.value))")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .contextMenu {
            Button(role: .destructive) {
                HabitStore(context: context).delete(log)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var timeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: log.loggedAt)
    }
}
