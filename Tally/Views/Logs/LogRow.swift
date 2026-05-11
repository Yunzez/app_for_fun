import SwiftUI

struct LogRow: View {
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    let log: ActivityLog
    let goalKind: GoalKind
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
                Text(valueText)
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

    private var valueText: String {
        switch goalKind {
        case .count: return "+\(Int(log.value))"
        case .duration: return "+\(Int(log.value / 60)) min"
        }
    }

    private var timeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: log.loggedAt)
    }
}
