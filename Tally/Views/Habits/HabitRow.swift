import SwiftUI

struct HabitRow: View {
    @Environment(\.theme) private var theme
    let habit: Habit

    private var accent: Color {
        let i = habit.accentSlot
        guard i >= 0, i < theme.habitPalette.count else { return theme.accentPrimary }
        return theme.habitPalette[i]
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: Tokens.IconSize.medium, height: Tokens.IconSize.medium)
                Image(systemName: habit.iconName)
                    .foregroundStyle(accent)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.body)
                Text(subtitle)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        let goal: String = {
            switch habit.goalKind {
            case .count:
                let t = Int(habit.goalTarget)
                return habit.unit.isEmpty ? "\(t)×" : "\(t) \(habit.unit)"
            case .duration:
                let mins = Int(habit.goalTarget / 60)
                if mins < 60 { return "\(mins) min" }
                let h = mins / 60, r = mins % 60
                return r == 0 ? "\(h) hr" : "\(h) hr \(r) min"
            }
        }()
        let sched: String = {
            switch habit.schedule {
            case .daily: return "daily"
            case .weekly(let days): return "\(days.count)×/week"
            case .monthly(let days): return "\(days.count)×/month"
            case .flexible(let n): return "\(n)×/week, flexible"
            }
        }()
        return "\(goal) · \(sched)"
    }
}
