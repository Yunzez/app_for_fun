import SwiftUI

/// Tap-to-edit sheet for today's `Entry` value. Lets the user type a value
/// directly (useful for catch-up entries: "I studied 1 hour and forgot to
/// time it"). Creates today's entry on Save if it doesn't exist.
struct EditValueSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    let habit: Habit
    let initialValue: Double

    @State private var draft: Double
    @FocusState private var fieldFocused: Bool

    init(habit: Habit, initialValue: Double) {
        self.habit = habit
        self.initialValue = initialValue
        _draft = State(initialValue: initialValue)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Set today's total for \(habit.name).")
                        .foregroundStyle(theme.textSecondary)

                    switch habit.goalKind {
                    case .count: countField
                    case .duration: durationField
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Edit Today")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 240)
        #endif
        .task {
            try? await Task.sleep(for: .milliseconds(200))
            fieldFocused = true
        }
    }

    @ViewBuilder
    private var countField: some View {
        HStack(spacing: 12) {
            TextField("0", value: countBinding, format: .number)
                .font(.system(size: 36, weight: .light, design: .rounded))
                .monospacedDigit()
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(.primary)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .focused($fieldFocused)
            if !habit.unit.isEmpty {
                Text(habit.unit)
                    .font(.title3)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    private var countBinding: Binding<Int> {
        Binding(
            get: { Int(draft) },
            set: { draft = Double(max(0, $0)) }
        )
    }

    @ViewBuilder
    private var durationField: some View {
        HStack(spacing: 12) {
            TextField("0", value: durationBinding, format: .number)
                .font(.system(size: 36, weight: .light, design: .rounded))
                .monospacedDigit()
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(.primary)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .focused($fieldFocused)
            Text("min")
                .font(.title3)
                .foregroundStyle(theme.textSecondary)
        }
    }

    private var durationBinding: Binding<Int> {
        Binding(
            get: { Int(draft / 60) },
            set: { draft = Double(max(0, $0)) * 60 }
        )
    }

    private func save() {
        HabitStore(context: context).setValue(habit, to: max(0, draft))
        dismiss()
    }
}
