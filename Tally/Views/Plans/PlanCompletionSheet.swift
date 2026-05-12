import SwiftUI
import SwiftData

/// Marks a plan done and attributes it to a habit. Pre-fills habit + value
/// from the plan if set; user can change either. On Done, credits the
/// chosen habit's entry by `value` and sets `plan.completedAt = .now`.
struct PlanCompletionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    let plan: ActivityLog

    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder, order: .forward)]
    )
    private var habits: [Habit]

    @State private var selectedHabitID: UUID? = nil
    @State private var valueDraft: Double = 0
    @State private var didLoad: Bool = false

    private var selectedHabit: Habit? {
        guard let id = selectedHabitID else { return nil }
        return habits.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Marking done")
                            .font(.subheadline)
                            .foregroundStyle(theme.textSecondary)
                        Text(plan.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(theme.textPrimary)
                    }

                    habitPicker
                    valueField

                    if let habit = selectedHabit, valueDraft > 0 {
                        Text("Adds \(habit.formatValue(valueDraft)) to today's total for \(habit.name).")
                            .font(.caption)
                            .foregroundStyle(theme.textTertiary)
                    } else if selectedHabit != nil {
                        Text("Records completion without changing today's total.")
                            .font(.caption)
                            .foregroundStyle(theme.textTertiary)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Complete")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save() }
                        .disabled(selectedHabit == nil)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 360)
        #endif
        .onAppear {
            if !didLoad {
                selectedHabitID = plan.habit?.id
                valueDraft = plan.value
                didLoad = true
            }
        }
    }

    private var habitPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Attribute to")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            Picker("Habit", selection: $selectedHabitID) {
                Text("Select a habit").tag(nil as UUID?)
                ForEach(habits) { habit in
                    Text(habit.name).tag(habit.id as UUID?)
                }
            }
            .pickerStyle(.menu)
        }
    }

    @ViewBuilder
    private var valueField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(valueLabel)
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            HStack {
                switch effectiveGoalKind {
                case .count:
                    TextField("0", value: countBinding, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 140)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.primary)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    if let unit = effectiveUnit, !unit.isEmpty {
                        Text(unit).foregroundStyle(theme.textSecondary)
                    }
                case .duration:
                    TextField("0", value: durationBinding, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 140)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.primary)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    Text("min").foregroundStyle(theme.textSecondary)
                }
                Spacer()
            }
        }
    }

    private var effectiveGoalKind: GoalKind {
        selectedHabit?.goalKind ?? .count
    }

    private var effectiveUnit: String? {
        selectedHabit?.unit
    }

    private var valueLabel: String {
        if let habit = selectedHabit, !habit.unit.isEmpty {
            return "\(habit.unit.capitalized) to credit (optional)"
        }
        return "Value to credit (optional)"
    }

    private var countBinding: Binding<Int> {
        Binding(
            get: { Int(valueDraft) },
            set: { valueDraft = Double(max(0, $0)) }
        )
    }

    private var durationBinding: Binding<Int> {
        Binding(
            get: { Int(valueDraft / 60) },
            set: { valueDraft = Double(max(0, $0)) * 60 }
        )
    }

    private func save() {
        guard let habit = selectedHabit else { return }
        HabitStore(context: context).complete(plan, habit: habit, value: valueDraft)
        dismiss()
    }
}
