import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.theme) private var theme

    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder, order: .forward)]
    )
    private var habits: [Habit]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Tokens.Spacing.medium) {
                    if habits.isEmpty {
                        emptyState
                    } else {
                        aggregateHeader
                        ForEach(habits) { habit in
                            HabitStatCard(habit: habit)
                        }
                    }
                }
                .padding(Tokens.Spacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Stats")
        }
    }

    private var emptyState: some View {
        VStack(spacing: Tokens.Spacing.small) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundStyle(theme.textTertiary)
            Text("No habits to track yet.")
                .foregroundStyle(theme.textSecondary)
            Text("Add a habit in the Habits tab to start seeing your progress here.")
                .font(.caption)
                .foregroundStyle(theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }

    private var aggregateHeader: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(todayCompleted)")
                    .font(.system(size: 36, weight: .light, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                    .monospacedDigit()
                Text("of \(todayScheduled) habits today")
                    .foregroundStyle(theme.textSecondary)
                Spacer()
            }
            Text("\(weekCompleted) of \(weekScheduled) scheduled this week")
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Tokens.Spacing.medium)
    }

    // MARK: - Aggregates

    private var todayCompleted: Int {
        habits.filter { habit in
            habit.isScheduledForToday() && habitHasActivityToday(habit)
        }.count
    }

    private var todayScheduled: Int {
        habits.filter { $0.isScheduledForToday() }.count
    }

    private var weekCompleted: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var count = 0
        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            for habit in habits where habit.schedule.isScheduled(on: day, calendar: cal) {
                if habit.entries.contains(where: {
                    cal.isDate($0.date, inSameDayAs: day) && $0.value > 0
                }) {
                    count += 1
                }
            }
        }
        return count
    }

    private var weekScheduled: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var count = 0
        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            for habit in habits where habit.schedule.isScheduled(on: day, calendar: cal) {
                count += 1
            }
        }
        return count
    }

    private func habitHasActivityToday(_ habit: Habit) -> Bool {
        let today = Calendar.current.startOfDay(for: .now)
        return habit.entries.contains {
            Calendar.current.isDate($0.date, inSameDayAs: today) && $0.value > 0
        }
    }
}
