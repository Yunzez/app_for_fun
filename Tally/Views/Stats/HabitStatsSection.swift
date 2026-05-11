import SwiftUI

/// Stats section embedded in `HabitDetailView` (between Tasks and History).
/// Reuses `HabitHeatmap` and `StatsService` so detail-page numbers match the
/// Stats tab cards.
struct HabitStatsSection: View {
    let habit: Habit

    @Environment(\.theme) private var theme

    private var stats: StatsService { StatsService(habit: habit) }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.medium) {
            SectionTitle("Stats")

            HabitHeatmap(habit: habit)

            HStack(spacing: Tokens.Spacing.large) {
                statItem("Current", value: "\(stats.currentStreak())", suffix: streakUnit)
                statItem("Best", value: "\(stats.longestStreak())", suffix: streakUnit)
                statItem("30d", value: "\(Int(stats.hitRate(daysBack: 30) * 100))%", suffix: nil)
                Spacer()
            }
        }
    }

    private var streakUnit: String {
        switch habit.schedule {
        case .flexible: return "×"
        default: return "d"
        }
    }

    private func statItem(_ label: String, value: String, suffix: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(theme.textPrimary)
                    .monospacedDigit()
                if let suffix {
                    Text(suffix)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
    }
}
