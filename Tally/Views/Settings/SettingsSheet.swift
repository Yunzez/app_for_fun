import SwiftUI

/// Minimal settings surface for M4. M7 promotes this to a proper Settings tab
/// with theme picker, HealthKit permissions, etc.
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    @AppStorage("tally.weekStart") private var weekStartDay: Int = 0

    private let weekStartOptions: [(label: String, value: Int)] = [
        ("System default", 0),
        ("Sunday", 1),
        ("Monday", 2),
        ("Saturday", 7)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.Spacing.bigSection) {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.medium) {
                        SectionTitle("Calendar")
                        VStack(alignment: .leading, spacing: Tokens.Spacing.small) {
                            Text("Week starts on")
                                .font(.tallyLabel)
                                .foregroundStyle(theme.textSecondary)
                            Picker("Week starts on", selection: $weekStartDay) {
                                ForEach(weekStartOptions, id: \.value) { option in
                                    Text(option.label).tag(option.value)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        Text("Affects heatmap columns and weekly totals.")
                            .font(.caption)
                            .foregroundStyle(theme.textTertiary)
                    }
                }
                .padding(Tokens.Spacing.section)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 260)
        #endif
    }
}
