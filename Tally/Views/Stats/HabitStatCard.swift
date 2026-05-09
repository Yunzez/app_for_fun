import SwiftUI

/// Per-habit card shown in the Stats tab. Heatmap, current/best streak, recent
/// hit rate. Tapping the card navigates into the habit's detail view.
struct HabitStatCard: View {
    let habit: Habit

    @Environment(\.theme) private var theme

    private var stats: StatsService { StatsService(habit: habit) }

    private var accent: Color {
        let i = habit.accentSlot
        guard i >= 0, i < theme.habitPalette.count else { return theme.accentPrimary }
        return theme.habitPalette[i]
    }

    var body: some View {
        NavigationLink {
            HabitDetailView(habit: habit)
        } label: {
            VStack(alignment: .leading, spacing: Tokens.Spacing.medium) {
                HStack(spacing: Tokens.Spacing.small) {
                    ZStack {
                        Circle()
                            .fill(accent.opacity(0.18))
                            .frame(width: Tokens.IconSize.medium, height: Tokens.IconSize.medium)
                        Image(systemName: habit.iconName)
                            .foregroundStyle(accent)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(habit.name)
                        .font(.tallyCardTitle)
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                }

                HabitHeatmap(habit: habit)

                HStack(spacing: Tokens.Spacing.large) {
                    statItem("Streak", value: "\(stats.currentStreak())")
                    statItem("Best", value: "\(stats.longestStreak())")
                    statItem("7d hit", value: "\(Int(stats.hitRate(daysBack: 7) * 100))%")
                    Spacer()
                }
            }
            .padding(Tokens.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Tokens.Radius.large)
                    .fill(theme.backgroundSecondary)
            )
        }
        .buttonStyle(.plain)
    }

    private func statItem(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.textPrimary)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
    }
}
