import Foundation
import SwiftData
import Observation

/// Manages a single active habit timer across the app. Persists state to
/// `UserDefaults` so the timer survives app termination, then materialises a
/// `TimerSession` and bumps the day's `Entry.value` when stopped.
@Observable
@MainActor
final class TimerService {

    /// Habit currently being timed, or nil when no timer is active.
    private(set) var activeHabitID: UUID?

    /// When the active session started.
    private(set) var startedAt: Date?

    /// Reserved for future pause/resume; currently always 0.
    private(set) var pausedAccumulated: TimeInterval = 0

    init() {
        restore()
    }

    // MARK: - Public API

    var isRunning: Bool { activeHabitID != nil }

    func isActive(for habit: Habit) -> Bool {
        activeHabitID == habit.id
    }

    /// Elapsed seconds for the active session as of `now`.
    func elapsedSeconds(now: Date = .now) -> TimeInterval {
        guard let startedAt else { return 0 }
        return max(0, now.timeIntervalSince(startedAt) - pausedAccumulated)
    }

    /// Start a timer for `habit`. If a different habit's timer is running,
    /// it is stopped first (its session saved). No-op if `habit` is already
    /// the active one.
    func start(habit: Habit, in context: ModelContext) {
        if activeHabitID == habit.id { return }
        if activeHabitID != nil { _ = stop(in: context) }
        activeHabitID = habit.id
        startedAt = .now
        pausedAccumulated = 0
        save()
    }

    /// Stop the active timer, persist a `TimerSession`, and add the elapsed
    /// seconds to today's `Entry.value`. Returns the saved session, or nil
    /// if nothing was running (or the habit had been deleted in the meantime).
    @discardableResult
    func stop(in context: ModelContext) -> TimerSession? {
        guard let activeID = activeHabitID, let startedAt else { return nil }
        let endedAt = Date.now
        let elapsed = max(0, endedAt.timeIntervalSince(startedAt) - pausedAccumulated)

        let session = persistSession(
            habitID: activeID,
            startedAt: startedAt,
            endedAt: endedAt,
            paused: pausedAccumulated,
            elapsed: elapsed,
            context: context
        )

        self.activeHabitID = nil
        self.startedAt = nil
        self.pausedAccumulated = 0
        save()
        return session
    }

    // MARK: - Internals

    private func persistSession(
        habitID: UUID,
        startedAt: Date,
        endedAt: Date,
        paused: TimeInterval,
        elapsed: TimeInterval,
        context: ModelContext
    ) -> TimerSession? {
        let predicate = #Predicate<Habit> { $0.id == habitID }
        var descriptor = FetchDescriptor<Habit>(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let habit = try? context.fetch(descriptor).first else {
            return nil
        }
        let entry = HabitStore(context: context).entry(for: habit)
        entry.value += elapsed
        let session = TimerSession(entry: entry, startedAt: startedAt)
        session.endedAt = endedAt
        session.pausedAccumulated = paused
        context.insert(session)
        return session
    }

    // MARK: - UserDefaults backing

    private enum Keys {
        static let habitID = "tally.timer.habitID"
        static let startedAt = "tally.timer.startedAt"
        static let pausedAccumulated = "tally.timer.pausedAccumulated"
    }

    private func save() {
        let d = UserDefaults.standard
        if let id = activeHabitID {
            d.set(id.uuidString, forKey: Keys.habitID)
        } else {
            d.removeObject(forKey: Keys.habitID)
        }
        if let start = startedAt {
            d.set(start.timeIntervalSince1970, forKey: Keys.startedAt)
        } else {
            d.removeObject(forKey: Keys.startedAt)
        }
        d.set(pausedAccumulated, forKey: Keys.pausedAccumulated)
    }

    private func restore() {
        let d = UserDefaults.standard
        guard
            let idString = d.string(forKey: Keys.habitID),
            let id = UUID(uuidString: idString),
            d.object(forKey: Keys.startedAt) != nil
        else { return }
        activeHabitID = id
        startedAt = Date(timeIntervalSince1970: d.double(forKey: Keys.startedAt))
        pausedAccumulated = d.double(forKey: Keys.pausedAccumulated)
    }
}
