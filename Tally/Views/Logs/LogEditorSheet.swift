import SwiftUI
import SwiftData

/// Sheet for adding or editing an `ActivityLog`. On create, a non-zero `value`
/// credits today's `Entry.value` once. On edit, value changes do NOT propagate
/// (loose attribution).
struct LogEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    enum Mode {
        case create(habit: Habit)
        case edit(log: ActivityLog)
    }

    let mode: Mode

    @State private var title: String = ""
    @State private var valueDraft: Double = 0
    @State private var didLoad: Bool = false
    @FocusState private var titleFocused: Bool

    init(habit: Habit) {
        self.mode = .create(habit: habit)
    }

    init(log: ActivityLog) {
        self.mode = .edit(log: log)
    }

    private var habit: Habit? {
        switch mode {
        case .create(let habit): return habit
        case .edit(let log): return log.entry?.habit
        }
    }

    private var goalKind: GoalKind {
        habit?.goalKind ?? .count
    }

    private var unit: String {
        habit?.unit ?? ""
    }

    private var isCreate: Bool {
        if case .create = mode { return true } else { return false }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleField
                    valueField
                    footerNote
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(isCreate ? "New Log" : "Edit Log")
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
        .frame(minWidth: 420, minHeight: 320)
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
            Text("What did you do?")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            TextField("e.g., Bench press 3×8", text: $title)
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(.primary)
                .focused($titleFocused)
        }
    }

    @ViewBuilder
    private var valueField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(valueLabel)
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            HStack {
                switch goalKind {
                case .count:
                    TextField("0", value: countBinding, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 140)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.primary)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    if !unit.isEmpty {
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

    @ViewBuilder
    private var footerNote: some View {
        if isCreate {
            if valueDraft > 0 {
                Text("Adds \(formattedValue) to today's total.")
                    .font(.caption)
                    .foregroundStyle(theme.textTertiary)
            } else {
                Text("Leave at — for a label-only log that doesn't change today's total.")
                    .font(.caption)
                    .foregroundStyle(theme.textTertiary)
            }
        } else {
            Text("Editing this log doesn't change today's total. Adjust the habit directly if needed.")
                .font(.caption)
                .foregroundStyle(theme.textTertiary)
        }
    }

    private var valueLabel: String {
        switch goalKind {
        case .count: return unit.isEmpty ? "Count" : unit.capitalized
        case .duration: return "Duration"
        }
    }

    private var formattedValue: String {
        habit?.formatValue(valueDraft) ?? "\(Int(valueDraft))"
    }

    private func load() {
        if case .edit(let log) = mode {
            title = log.title
            valueDraft = log.value
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        switch mode {
        case .create(let habit):
            HabitStore(context: context).addLog(to: habit, title: trimmed, value: valueDraft)
        case .edit(let log):
            HabitStore(context: context).updateLog(log, title: trimmed, value: valueDraft)
        }
        dismiss()
    }
}
