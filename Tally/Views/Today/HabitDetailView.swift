import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(TimerService.self) private var timer
    @Environment(\.theme) private var theme

    let habit: Habit

    @State private var noteDraft: String = ""
    @State private var didLoadNote: Bool = false
    @State private var editPresented: Bool = false
    @State private var deleteConfirmation: Bool = false

    private var todayEntry: Entry? {
        habit.entries.first { Calendar.current.isDate($0.date, inSameDayAs: .now) }
    }

    private var accent: Color {
        let i = habit.accentSlot
        guard i >= 0, i < theme.habitPalette.count else { return theme.accentPrimary }
        return theme.habitPalette[i]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                TallyDivider()
                progressSection
                TallyDivider()
                HabitTaskSection(habit: habit)
                TallyDivider()
                HabitStatsSection(habit: habit)
                TallyDivider()
                notesSection
                TallyDivider()
                historySection
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(habit.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 600)
        #endif
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    editPresented = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Menu {
                    Button {
                        HabitStore(context: context).archive(habit)
                        dismiss()
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    Button(role: .destructive) {
                        deleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $editPresented) {
            HabitFormView(habit: habit)
        }
        .alert("Delete this habit?", isPresented: $deleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                HabitStore(context: context).delete(habit)
                dismiss()
            }
        } message: {
            Text("All entries, sessions, and tasks will be removed. This can't be undone.")
        }
        .onAppear {
            if !didLoadNote {
                noteDraft = todayEntry?.note ?? ""
                didLoadNote = true
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: Tokens.IconSize.large, height: Tokens.IconSize.large)
                Image(systemName: habit.iconName)
                    .foregroundStyle(accent)
                    .font(.system(size: 26, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name).font(.title2.weight(.semibold))
                Text(scheduleText).foregroundStyle(theme.textSecondary).font(.caption)
            }
            Spacer()
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Today")
            switch habit.goalKind {
            case .count:
                CountController(habit: habit)
            case .duration:
                DurationController(habit: habit)
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Notes")
            TextField(
                "Anything to remember about today?",
                text: $noteDraft,
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .foregroundStyle(.primary)
            .lineLimit(2...6)
            .onChange(of: noteDraft) { _, newValue in
                HabitStore(context: context).setNote(habit, to: newValue)
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("History")
            let recent = habit.entries
                .sorted { $0.date > $1.date }
                .prefix(30)
            if recent.isEmpty {
                Text("No history yet.").foregroundStyle(theme.textSecondary)
            } else {
                ForEach(Array(recent), id: \.id) { entry in
                    HistoryRow(habit: habit, entry: entry)
                }
            }
        }
    }

    private var scheduleText: String {
        switch habit.schedule {
        case .daily: return "Daily"
        case .weekly(let days): return "\(days.count)×/week"
        case .monthly(let days): return "\(days.count)×/month"
        case .flexible(let n): return "\(n)×/week, flexible"
        }
    }
}

// MARK: - Controllers

private struct CountController: View {
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme

    let habit: Habit

    private var todayEntry: Entry? {
        habit.entries.first { Calendar.current.isDate($0.date, inSameDayAs: .now) }
    }

    private var currentValue: Int { Int(todayEntry?.value ?? 0) }
    private var targetValue: Int { Int(habit.goalTarget) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline) {
                Text("\(currentValue)")
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .monospacedDigit()
                Text("/ \(targetValue)")
                    .font(.title3)
                    .foregroundStyle(theme.textSecondary)
                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    HabitStore(context: context).adjust(habit, by: -1)
                } label: {
                    Label("Remove", systemImage: "minus.circle.fill")
                        .font(.title3)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(currentValue <= 0)

                Button {
                    HabitStore(context: context).adjust(habit, by: 1)
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.title3)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accentPrimary)
            }
        }
    }
}

private struct DurationController: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerService.self) private var timer
    @Environment(\.theme) private var theme

    let habit: Habit

    private var todayEntry: Entry? {
        habit.entries.first { Calendar.current.isDate($0.date, inSameDayAs: .now) }
    }

    private var bankedSeconds: TimeInterval { todayEntry?.value ?? 0 }
    private var targetSeconds: TimeInterval { habit.goalTarget }
    private var isActive: Bool { timer.isActive(for: habit) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TimelineView(.periodic(from: .now, by: 1)) { tcontext in
                let live = isActive ? timer.elapsedSeconds(now: tcontext.date) : 0
                Text(formatHMS(bankedSeconds + live))
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Text("Target: \(formatGoal(targetSeconds))")
                    .foregroundStyle(theme.textSecondary)
                Spacer()
            }

            Button {
                if isActive {
                    timer.stop(in: context)
                } else {
                    timer.start(habit: habit, in: context)
                }
            } label: {
                Label(
                    isActive ? "Stop" : "Start",
                    systemImage: isActive ? "stop.circle.fill" : "play.circle.fill"
                )
                .font(.title3)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(isActive ? theme.error : theme.accentPrimary)
        }
    }

    private func formatHMS(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    private func formatGoal(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        if mins < 60 { return "\(mins) min" }
        let h = mins / 60, r = mins % 60
        return r == 0 ? "\(h) hr" : "\(h) hr \(r) min"
    }
}

// MARK: - History

private struct HistoryRow: View {
    @Environment(\.theme) private var theme

    let habit: Habit
    let entry: Entry

    @State private var editorPresented: Bool = false

    private var displayValue: String {
        switch habit.goalKind {
        case .count: return "\(Int(entry.value))"
        case .duration:
            let mins = Int(entry.value / 60)
            return "\(mins) min"
        }
    }

    private var dateLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(entry.date) { return "Today" }
        if cal.isDateInYesterday(entry.date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: entry.date)
    }

    var body: some View {
        Button {
            editorPresented = true
        } label: {
            HStack {
                Text(dateLabel).foregroundStyle(.primary)
                Spacer()
                Text(displayValue).foregroundStyle(theme.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(theme.textTertiary)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $editorPresented) {
            EntryEditorSheet(habit: habit, entry: entry)
        }
    }
}

private struct EntryEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    let habit: Habit
    let entry: Entry

    @State private var draft: Double = 0
    @State private var didLoad: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(entryDateLabel)
                        .font(.headline)
                        .foregroundStyle(theme.textSecondary)

                    switch habit.goalKind {
                    case .count:
                        Stepper(value: $draft, in: 0...999, step: 1) {
                            HStack {
                                Text("Count")
                                Spacer()
                                Text("\(Int(draft))").foregroundStyle(theme.textSecondary)
                            }
                        }
                    case .duration:
                        Stepper(value: $draft, in: 0...36000, step: 60) {
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text("\(Int(draft / 60)) min").foregroundStyle(theme.textSecondary)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Edit Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        entry.value = max(0, draft)
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 220)
        #endif
        .onAppear {
            if !didLoad {
                draft = entry.value
                didLoad = true
            }
        }
    }

    private var entryDateLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(entry.date) { return "Today" }
        if cal.isDateInYesterday(entry.date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateStyle = .full
        return f.string(from: entry.date)
    }
}
