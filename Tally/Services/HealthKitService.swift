import Foundation
import HealthKit
import SwiftData
import Observation

/// Read-only HealthKit integration. Fetches today's value for each habit's
/// `HealthBinding` and writes it to the day's `Entry`.
///
/// Disabled by default. To enable:
///   1. Add `NSHealthShareUsageDescription` to `Info.plist` (already done).
///   2. Add the `com.apple.developer.healthkit` entitlement to
///      `Tally.entitlements` and register the HealthKit capability in the
///      Apple Developer portal against your real bundle id.
///   3. Set `useHealthKit = true` below.
///
/// On macOS, `HKHealthStore.isHealthDataAvailable()` returns false (no health
/// data is recorded on Mac), so the service is a no-op there.
@Observable
@MainActor
final class HealthKitService {
    /// Master switch. Flip after configuring entitlements + Apple Developer
    /// portal capability for HealthKit.
    static let useHealthKit: Bool = false

    private let store = HKHealthStore()
    var isAuthorized: Bool = false
    var lastErrorMessage: String?

    init() {}

    /// Called once per app launch. Requests authorization, then runs an initial sync.
    func startIfEnabled(context: ModelContext) async {
        guard Self.useHealthKit, HKHealthStore.isHealthDataAvailable() else { return }
        do {
            try await requestAuthorization()
            await syncAllHabits(context: context)
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    /// Called when the app returns to foreground. No-op until startIfEnabled
    /// has succeeded.
    func syncOnForeground(context: ModelContext) async {
        guard Self.useHealthKit, isAuthorized else { return }
        await syncAllHabits(context: context)
    }

    // MARK: - Authorization

    private func requestAuthorization() async throws {
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKWorkoutType.workoutType(),
            HKCategoryType(.sleepAnalysis),
            HKCategoryType(.mindfulSession)
        ]
        try await store.requestAuthorization(toShare: [], read: typesToRead)
        isAuthorized = true
    }

    // MARK: - Sync

    private func syncAllHabits(context: ModelContext) async {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived }
        )
        guard let habits = try? context.fetch(descriptor) else { return }

        for habit in habits {
            guard let binding = habit.healthBinding else { continue }
            do {
                let value = try await fetchTodayValue(for: binding)
                let storeFacade = HabitStore(context: context)
                let entry = storeFacade.entry(for: habit)
                // Manual entries with a value win — never overwrite them.
                if entry.source == .manual && entry.value > 0 { continue }
                entry.value = value
                entry.source = .healthkit
            } catch {
                lastErrorMessage = "Sync failed for \(habit.name): \(error)"
            }
        }
        try? context.save()
    }

    // MARK: - Per-binding fetches

    private func fetchTodayValue(for binding: HealthBinding) async throws -> Double {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: .now)
        guard let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) else { return 0 }
        let predicate = HKQuery.predicateForSamples(
            withStart: dayStart, end: dayEnd, options: .strictStartDate
        )

        switch binding {
        case .steps:
            return try await sumQuantity(.stepCount, unit: .count(), predicate: predicate)
        case .activeEnergy:
            return try await sumQuantity(.activeEnergyBurned, unit: .kilocalorie(), predicate: predicate)
        case .workoutDuration:
            return try await sumWorkoutDuration(predicate: predicate)
        case .sleepHours:
            return try await sumSleepHours(predicate: predicate)
        case .mindfulMinutes:
            return try await sumMindfulMinutes(predicate: predicate)
        }
    }

    private func sumQuantity(
        _ id: HKQuantityTypeIdentifier,
        unit: HKUnit,
        predicate: NSPredicate
    ) async throws -> Double {
        let qtype = HKQuantityType(id)
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(
                quantityType: qtype,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }

    private func sumWorkoutDuration(predicate: NSPredicate) async throws -> Double {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                let workouts = samples as? [HKWorkout] ?? []
                let totalSeconds = workouts.reduce(0.0) { $0 + $1.duration }
                cont.resume(returning: totalSeconds)
            }
            store.execute(query)
        }
    }

    private func sumSleepHours(predicate: NSPredicate) async throws -> Double {
        let cType = HKCategoryType(.sleepAnalysis)
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
            let query = HKSampleQuery(
                sampleType: cType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                let categories = samples as? [HKCategorySample] ?? []
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                ]
                let totalSeconds = categories
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                cont.resume(returning: totalSeconds / 3600)
            }
            store.execute(query)
        }
    }

    private func sumMindfulMinutes(predicate: NSPredicate) async throws -> Double {
        let cType = HKCategoryType(.mindfulSession)
        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
            let query = HKSampleQuery(
                sampleType: cType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                let categories = samples as? [HKCategorySample] ?? []
                let totalSeconds = categories.reduce(0.0) {
                    $0 + $1.endDate.timeIntervalSince($1.startDate)
                }
                cont.resume(returning: totalSeconds / 60)
            }
            store.execute(query)
        }
    }
}
