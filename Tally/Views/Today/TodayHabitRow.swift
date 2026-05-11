import SwiftUI
import SwiftData

struct TodayHabitRow: View {
    @Environment(TimerService.self) private var timer
    @Environment(\.theme) private var theme

    let habit: Habit
    @Query private var todayEntries: [Entry]

    init(habit: Habit) {
        self.habit = habit
        let habitID = habit.id
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        _todayEntries = Query(filter: #Predicate<Entry> { e in
            e.date >= start && e.date < end && e.habit?.id == habitID
        })
    }

    private var todayEntry: Entry? { todayEntries.first }

    private var bankedValue: Double {
        todayEntry?.value ?? 0
    }

    private var progress: Double {
        guard habit.goalTarget > 0 else { return 0 }
        return min(1, bankedValue / habit.goalTarget)
    }

    private var isComplete: Bool {
        bankedValue >= habit.goalTarget
    }

    private var accent: Color {
        let i = habit.accentSlot
        guard i >= 0, i < theme.habitPalette.count else { return theme.accentPrimary }
        return theme.habitPalette[i]
    }

    var body: some View {
        HStack(spacing: Tokens.Spacing.medium) {
            ZStack {
                ProgressRing(progress: progress, accent: accent)
                    .frame(width: Tokens.IconSize.medium, height: Tokens.IconSize.medium)
                Image(systemName: habit.iconName)
                    .foregroundStyle(accent)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(habit.name)
                        .font(.body)
                        .foregroundStyle(theme.textPrimary)
                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(theme.success)
                            .font(.caption)
                    }
                    if timer.isActive(for: habit) {
                        Image(systemName: "timer")
                            .foregroundStyle(theme.accentPrimary)
                            .font(.caption)
                    }
                }
                Text(progressText)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, Tokens.Spacing.xs)
    }

    private var progressText: String {
        habit.formatProgress(bankedValue)
    }
}
