import SwiftUI

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: ThemePalette = .slate
}

extension EnvironmentValues {
    var theme: ThemePalette {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
