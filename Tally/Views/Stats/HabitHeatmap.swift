import SwiftUI

/// GitHub-style heatmap: 7 rows (weekdays) × N columns (weeks).
/// Each cell colored by `entry.value / habit.goalTarget` in the habit's accent.
struct HabitHeatmap: View {
    let habit: Habit
    var weeks: Int = 12
    var cellSize: CGFloat = 12
    var spacing: CGFloat = 2

    @Environment(\.theme) private var theme
    @AppStorage("tally.weekStart") private var weekStartSetting: Int = 0

    private var calendar: Calendar {
        var cal = Calendar.current
        if weekStartSetting > 0 { cal.firstWeekday = weekStartSetting }
        return cal
    }

    private var accent: Color {
        let i = habit.accentSlot
        guard i >= 0, i < theme.habitPalette.count else { return theme.accentPrimary }
        return theme.habitPalette[i]
    }

    var body: some View {
        let days = computeDays()
        let rows = Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: 7)

        LazyHGrid(rows: rows, spacing: spacing) {
            ForEach(days, id: \.self) { day in
                cell(for: day)
            }
        }
        .frame(height: cellSize * 7 + spacing * 6)
    }

    private func cell(for day: Date) -> some View {
        let entry = habit.entries.first { calendar.isDate($0.date, inSameDayAs: day) }
        let value = entry?.value ?? 0
        let progress = habit.goalTarget > 0 ? value / habit.goalTarget : 0
        let scheduled = habit.schedule.isScheduled(on: day, calendar: calendar)
        let isFuture = day > calendar.startOfDay(for: .now)

        return RoundedRectangle(cornerRadius: 2)
            .fill(cellColor(progress: progress, scheduled: scheduled, isFuture: isFuture, hasActivity: value > 0))
            .frame(width: cellSize, height: cellSize)
    }

    private func cellColor(progress: Double, scheduled: Bool, isFuture: Bool, hasActivity: Bool) -> Color {
        if isFuture { return theme.backgroundTertiary.opacity(0.4) }
        if !scheduled { return theme.backgroundTertiary.opacity(0.5) }
        if !hasActivity { return theme.backgroundTertiary }
        let intensity = max(0.3, min(1.0, progress))
        return accent.opacity(intensity)
    }

    /// Build the day list ordered column-by-column for `LazyHGrid` consumption.
    /// Column 0 = oldest week, column N-1 = current week.
    private func computeDays() -> [Date] {
        let today = calendar.startOfDay(for: .now)
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start,
              let earliestWeekStart = calendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: thisWeekStart)
        else { return [] }

        var result: [Date] = []
        for w in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: w, to: earliestWeekStart) else { continue }
            for d in 0..<7 {
                guard let day = calendar.date(byAdding: .day, value: d, to: weekStart) else { continue }
                result.append(day)
            }
        }
        return result
    }
}
