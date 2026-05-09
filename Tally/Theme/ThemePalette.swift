import SwiftUI

/// Semantic color palette for the entire app.
///
/// Views must read colors **only** from a `ThemePalette` resolved through
/// `@Environment(\.theme)`. Never reference `Color.blue`, hex literals,
/// or asset-catalog color names that describe a hue. See `docs/design.html` §6.
struct ThemePalette: Equatable {
    let id: String
    let displayName: String

    let accentPrimary: Color
    let accentSecondary: Color

    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let backgroundTertiary: Color

    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color

    let border: Color

    let success: Color
    let warning: Color
    let error: Color

    /// Eight ordered accent colors used as the per-habit color picker.
    /// Habits store an index into this array, not raw RGB.
    let habitPalette: [Color]
}
