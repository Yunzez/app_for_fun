import Foundation

/// Pure derived stats over a single habit. No SwiftData state of its own —
/// reads `habit.entries` and the schedule, computes everything else.
///
/// Streak rules:
///   - atLeast: scheduled past day counts toward streak if value > 0.
///     Otherwise breaks. Today (in-progress) doesn't count, doesn't break.
///   - atMost: scheduled past day counts if 0 < value ≤ target. Over-target
///     OR no engagement breaks. Today (in-progress) doesn't count, doesn't
///     break — judgement deferred until day rollover.
///   - flexible(everyDays:): walks active entries directly. Streak intact
///     while gaps between consecutive active entries (and the gap from the
///     most recent to today) stay ≤ `everyDays`.
@MainActor
struct StatsService {
    let habit: Habit
    var calendar: Calendar = .current

    // MARK: - Streaks

    func currentStreak(asOf today: Date = .now) -> Int {
        switch habit.schedule {
        case .flexible(let everyDays):
            return cooldownStreakBack(asOf: today, everyDays: everyDays)
        default:
            return dailyStreakBack(asOf: today)
        }
    }

    func longestStreak() -> Int {
        switch habit.schedule {
        case .flexible(let everyDays):
            return longestCooldownStreak(everyDays: everyDays)
        default:
            return longestDailyStreak()
        }
    }

    // MARK: - Hit rate

    /// Fraction of scheduled days in the last `daysBack` days (including today)
    /// that "succeeded" by the habit's direction rule. 0...1.
    func hitRate(daysBack: Int, asOf today: Date = .now) -> Double {
        let day0 = calendar.startOfDay(for: today)
        var scheduled = 0
        var hit = 0
        for offset in 0..<daysBack {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: day0) else { continue }
            if isScheduled(on: day) {
                scheduled += 1
                if successOn(day) { hit += 1 }
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
                if successOn(day) {
                    count += 1
                } else if calendar.isDateInToday(day) {
                    // Today in progress — don't count, don't break.
                } else {
                    // Past scheduled day failed → streak broken.
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
                if successOn(day) {
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

    // MARK: - Cooldown streaks (flexible "every N days")

    private func cooldownStreakBack(asOf today: Date, everyDays: Int) -> Int {
        let activeDays = sortedSuccessDaysDescending()
        guard let mostRecent = activeDays.first else { return 0 }

        let today0 = calendar.startOfDay(for: today)
        let sinceLast = calendar.dateComponents([.day], from: mostRecent, to: today0).day ?? 0
        if sinceLast > everyDays { return 0 }

        var count = 1
        var prev = mostRecent
        for day in activeDays.dropFirst() {
            let gap = calendar.dateComponents([.day], from: day, to: prev).day ?? 0
            if gap <= everyDays {
                count += 1
                prev = day
            } else {
                break
            }
        }
        return count
    }

    private func longestCooldownStreak(everyDays: Int) -> Int {
        let activeDays = sortedSuccessDaysDescending().reversed()  // ascending
        var longest = 0
        var current = 0
        var prev: Date?
        for day in activeDays {
            if let p = prev {
                let gap = calendar.dateComponents([.day], from: p, to: day).day ?? 0
                if gap <= everyDays {
                    current += 1
                } else {
                    current = 1
                }
            } else {
                current = 1
            }
            longest = max(longest, current)
            prev = day
        }
        return longest
    }

    // MARK: - Helpers

    private func isScheduled(on day: Date) -> Bool {
        habit.schedule.isScheduled(on: day, calendar: calendar)
    }

    /// Did the habit succeed on `day` per its direction rule?
    /// atLeast: value > 0. atMost: 0 < value ≤ target.
    private func successOn(_ day: Date) -> Bool {
        let entry = habit.entries.first { calendar.isDate($0.date, inSameDayAs: day) }
        let value = entry?.value ?? 0
        return habit.successForStreak(value)
    }

    private func sortedSuccessDaysDescending() -> [Date] {
        habit.entries
            .filter { habit.successForStreak($0.value) }
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)
    }

    private func earliestEntryDay() -> Date? {
        habit.entries.map(\.date).min().map { calendar.startOfDay(for: $0) }
    }
}
