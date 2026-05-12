import SwiftUI
import SwiftData

/// Sheet for creating or editing a plan (pre-completion). Optional habit
/// pre-attachment; loose by default.
struct PlanEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    enum Mode {
        case create
        case edit(ActivityLog)
    }

    let mode: Mode

    @Query(
        filter: #Predicate<Habit> { !$0.isArchived },
        sort: [SortDescriptor(\Habit.sortOrder, order: .forward)]
    )
    private var habits: [Habit]

    @State private var title: String = ""
    @State private var valueDraft: Double = 0
    @State private var selectedHabitID: UUID? = nil
    @State private var didLoad: Bool = false
    @FocusState private var titleFocused: Bool

    init() { self.mode = .create }
    init(plan: ActivityLog) { self.mode = .edit(plan) }

    private var isCreate: Bool {
        if case .create = mode { return true } else { return false }
    }

    private var selectedHabit: Habit? {
        guard let id = selectedHabitID else { return nil }
        return habits.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleField
                    habitPicker
                    valueField
                    Text("Plans live in the Plan section until you tick them done. The value is credited to the habit's entry on completion.")
                        .font(.caption)
                        .foregroundStyle(theme.textTertiary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(isCreate ? "New Plan" : "Edit Plan")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isCreate ? "Add" : "Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 380)
        #endif
        .onAppear {
            if !didLoad {
                load()
                didLoad = true
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(200))
            if isCreate { titleFocused = true }
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What are you planning to do?")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            TextField("e.g. Chipotle bowl, Read chapter 4", text: $title)
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(.primary)
                .focused($titleFocused)
        }
    }

    private var habitPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Habit (optional)")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            Picker("Habit", selection: $selectedHabitID) {
                Text("Pick later").tag(nil as UUID?)
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
            return "Estimated \(habit.unit) (optional)"
        }
        return "Estimated value (optional)"
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

    private func load() {
        if case .edit(let plan) = mode {
            title = plan.title
            valueDraft = plan.value
            selectedHabitID = plan.habit?.id
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        switch mode {
        case .create:
            HabitStore(context: context).addPlan(
                title: trimmed,
                value: valueDraft,
                habit: selectedHabit
            )
        case .edit(let plan):
            HabitStore(context: context).updateLog(plan, title: trimmed, value: valueDraft)
            plan.habit = selectedHabit
        }
        dismiss()
    }
}
