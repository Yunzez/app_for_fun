import Foundation

/// Pure derived stats over a single habit. No SwiftData state of its own —
/// reads `habit.entries` and the schedule, computes everything else.
///
/// Streak rule for v1.0 (per user direction): a scheduled period counts toward
/// the streak if there was *any* activity (entry value > 0) during it. Goal
/// completion is not required. The "today/this week in progress" period
/// doesn't break the streak if it has no activity yet — it just doesn't count.
@MainActor
struct StatsService {
    let habit: Habit
    var calendar: Calendar = .current

    // MARK: - Streaks

    func currentStreak(asOf today: Date = .now) -> Int {
        switch habit.schedule {
        case .flexible:
            return weeklyStreakBack(asOf: today)
        default:
            return dailyStreakBack(asOf: today)
        }
    }

    func longestStreak() -> Int {
        switch habit.schedule {
        case .flexible:
            return longestWeeklyStreak()
        default:
            return longestDailyStreak()
        }
    }

    // MARK: - Hit rate

    /// Fraction of scheduled days in the last `daysBack` days (including today)
    /// that had any activity. 0...1.
    func hitRate(daysBack: Int, asOf today: Date = .now) -> Double {
        let day0 = calendar.startOfDay(for: today)
        var scheduled = 0
        var hit = 0
        for offset in 0..<daysBack {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: day0) else { continue }
            if isScheduled(on: day) {
                scheduled += 1
                if hasActivity(on: day) { hit += 1 }
            }
        }
        return scheduled == 0 ? 0 : Double(hit) / Double(scheduled)
    }

    // MARK: - Day-based streaks (daily / weekly / monthly schedules)

    private func dailyStreakBack(asOf today: Date) -> Int {
        var count = 0
        var day = calendar.startOfDay(for: today)
        let earliest = earliestEntryDay() ?? day

        while day >= earliest {
            if isScheduled(on: day) {
                if hasActivity(on: day) {
                    count += 1
                } else if calendar.isDateInToday(day) {
                    // Today not yet active — don't count, don't break.
                } else {
                    // Past scheduled day with no activity → streak broken.
                    break
                }
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    private func longestDailyStreak() -> Int {
        guard let earliest = earliestEntryDay() else { return 0 }
        let today = calendar.startOfDay(for: .now)
        var longest = 0
        var current = 0
        var day = earliest
        while day <= today {
            if isScheduled(on: day) {
                if hasActivity(on: day) {
                    current += 1
                    longest = max(longest, current)
                } else if !calendar.isDateInToday(day) {
                    current = 0
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return longest
    }

    // MARK: - Week-based streaks (flexible schedule)

    private func weeklyStreakBack(asOf today: Date) -> Int {
        guard let currentWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return 0 }
        guard let earliestWeek = earliestEntryWeekStart() else { return 0 }

        var count = 0
        var weekStart = currentWeek
        while weekStart >= earliestWeek {
            if hasActivityInWeek(starting: weekStart) {
                count += 1
            } else if weekStart == currentWeek {
                // Current week with no activity yet — don't count, don't break.
            } else {
                break
            }
            guard let prev = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) else { break }
            weekStart = prev
        }
        return count
    }

    private func longestWeeklyStreak() -> Int {
        guard let earliestWeek = earliestEntryWeekStart() else { return 0 }
        guard let currentWeek = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else { return 0 }

        var longest = 0
        var current = 0
        var weekStart = earliestWeek
        while weekStart <= currentWeek {
            if hasActivityInWeek(starting: weekStart) {
                current += 1
                longest = max(longest, current)
            } else if weekStart != currentWeek {
                current = 0
            }
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { break }
            weekStart = next
        }
        return longest
    }

    // MARK: - Helpers

    private func isScheduled(on day: Date) -> Bool {
        habit.schedule.isScheduled(on: day, calendar: calendar)
    }

    private func hasActivity(on day: Date) -> Bool {
        habit.entries.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: day) && entry.value > 0
        }
    }

    private func hasActivityInWeek(starting weekStart: Date) -> Bool {
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { return false }
        return habit.entries.contains { entry in
            entry.date >= weekStart && entry.date < weekEnd && entry.value > 0
        }
    }

    private func earliestEntryDay() -> Date? {
        habit.entries.map(\.date).min().map { calendar.startOfDay(for: $0) }
    }

    private func earliestEntryWeekStart() -> Date? {
        guard let earliest = habit.entries.map(\.date).min() else { return nil }
        return calendar.dateInterval(of: .weekOfYear, for: earliest)?.start
    }
}
