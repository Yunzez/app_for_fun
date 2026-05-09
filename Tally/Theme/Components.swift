import SwiftUI

/// Themed 1pt rule. Use instead of `Divider()` so the line color comes from
/// the active theme rather than the system default.
struct TallyDivider: View {
    @Environment(\.theme) private var theme

    var body: some View {
        Rectangle()
            .fill(theme.border)
            .frame(height: Tokens.Stroke.thin)
    }
}

/// Standard section header used across detail / form / list views.
struct SectionTitle: View {
    @Environment(\.theme) private var theme
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.tallySectionHeader)
            .foregroundStyle(theme.textPrimary)
    }
}
