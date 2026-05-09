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

    /// Goal-met flag. M3 will also require all attached tasks be done
    /// (per design.html §4.8); for now this is goal-only.
    private var isComplete: Bool {
        bankedValue >= habit.goalTarget
    }

    private var accent: Color {
        let i = habit.accentSlot
        guard i >= 0, i < theme.habitPalette.count else { return theme.accentPrimary }
        return theme.habitPalette[i]
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                ProgressRing(progress: progress, accent: accent)
                    .frame(width: 40, height: 40)
                Image(systemName: habit.iconName)
                    .foregroundStyle(accent)
                    .font(.system(size: 14, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(habit.name).font(.body)
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
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Spacer()
        }
        .padding(.vertical, 4)
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
