import SwiftUI

extension ThemePalette {
    static let slate = ThemePalette(
        id: "slate",
        displayName: "Slate",
        accentPrimary:       .adaptive(light: 0x3A3F47, dark: 0xC8CCD4),
        accentSecondary:     .adaptive(light: 0x6B7380, dark: 0x8A92A0),
        backgroundPrimary:   .adaptive(light: 0xFFFFFF, dark: 0x15171C),
        backgroundSecondary: .adaptive(light: 0xF6F7F9, dark: 0x1D2027),
        backgroundTertiary:  .adaptive(light: 0xECEEF2, dark: 0x252830),
        textPrimary:         .adaptive(light: 0x1C1F24, dark: 0xE6E8EC),
        textSecondary:       .adaptive(light: 0x555A63, dark: 0xA8ACB6),
        textTertiary:        .adaptive(light: 0x8A909A, dark: 0x6C717C),
        border:              .adaptive(light: 0xE3E6EB, dark: 0x2A2E37),
        success:             .adaptive(light: 0x1F7A3A, dark: 0x6EC890),
        warning:             .adaptive(light: 0xB15A00, dark: 0xE0A35F),
        error:               .adaptive(light: 0xC0392B, dark: 0xE57373),
        habitPalette: [
            .adaptive(light: 0x4A6CF7, dark: 0x8BA4FF),
            .adaptive(light: 0x3F8F5D, dark: 0x6EC890),
            .adaptive(light: 0xE07A5F, dark: 0xF0A48E),
            .adaptive(light: 0x8A78D3, dark: 0xB0A3E5),
            .adaptive(light: 0xC9A979, dark: 0xDFC59B),
            .adaptive(light: 0xD9534F, dark: 0xE57373),
            .adaptive(light: 0x4FB3BF, dark: 0x7CD0DA),
            .adaptive(light: 0x6C7480, dark: 0x9EA5B0)
        ]
    )
}
