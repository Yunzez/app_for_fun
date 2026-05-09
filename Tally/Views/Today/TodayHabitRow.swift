import SwiftUI

struct TodayHabitRow: View {
    @Environment(TimerService.self) private var timer
    @Environment(\.theme) private var theme

    let habit: Habit

    private var todayEntry: Entry? {
        habit.entries.first { Calendar.current.isDate($0.date, inSameDayAs: .now) }
    }

    private var bankedValue: Double {
        todayEntry?.value ?? 0
    }

    private var progress: Double {
        guard habit.goalTarget > 0 else { return 0 }
        return min(1, bankedValue / habit.goalTarget)
    }

    private var openTasksCount: Int {
        habit.tasks.filter { !$0.isDone }.count
    }

    /// A habit is complete when its goal is met *and* no attached tasks are
    /// still open (design.html §4.8).
    private var isComplete: Bool {
        bankedValue >= habit.goalTarget && openTasksCount == 0
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
                HStack(spacing: 4) {
                    Text(progressText)
                    if openTasksCount > 0 {
                        Text("· \(openTasksCount) open task\(openTasksCount == 1 ? "" : "s")")
                    }
                }
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, Tokens.Spacing.xs)
    }

    private var progressText: String {
        switch habit.goalKind {
        case .count:
            return "\(Int(bankedValue)) / \(Int(habit.goalTarget))"
        case .duration:
            let valMin = Int(bankedValue / 60)
            let tgtMin = Int(habit.goalTarget / 60)
            return "\(valMin) / \(tgtMin) min"
        }
    }
}
