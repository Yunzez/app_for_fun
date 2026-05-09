import SwiftUI

/// Layout and typography tokens shared across the app.
/// Use these instead of magic numbers so spacing and sizing stay consistent.
enum Tokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let section: CGFloat = 20
        static let bigSection: CGFloat = 24
    }

    enum IconSize {
        static let small: CGFloat = 28
        static let medium: CGFloat = 40
        static let large: CGFloat = 60
    }

    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
    }

    enum Stroke {
        static let thin: CGFloat = 1
        static let progress: CGFloat = 3
    }
}

extension Font {
    static let tallySectionHeader: Font = .title3.weight(.semibold)
    static let tallyCardTitle: Font = .headline
    static let tallyLabel: Font = .subheadline
}
