import UIKit

/// Native text styles; no fixed line heights or Dynamic Type upper bound.
@MainActor
public enum RhineTypography {
    public enum Role: Sendable, CaseIterable {
        case title, body, label, supporting
    }

    /// Enable `adjustsFontForContentSizeCategory` on the consuming text control.
    public static func font(_ role: Role, compatibleWith traits: UITraitCollection? = nil) -> UIFont {
        let style: UIFont.TextStyle
        switch role {
        case .title: style = .headline
        case .body, .label: style = .body
        case .supporting: style = .footnote
        }
        return UIFont.preferredFont(forTextStyle: style, compatibleWith: traits)
    }
}
