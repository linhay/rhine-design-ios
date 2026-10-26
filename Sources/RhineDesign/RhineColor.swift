import UIKit

/// Semantic colors follow the host's system appearance and accessibility traits.
@MainActor
public enum RhineColor {
    public static var textPrimary: UIColor { .label }
    public static var textSecondary: UIColor { .secondaryLabel }
    public static var canvas: UIColor { .systemBackground }
    public static var group: UIColor { .systemGroupedBackground }
    public static var separator: UIColor { .separator }
    public static var error: UIColor { .systemRed }

    /// Resolve at the point of use; never cache a host's tint globally.
    public static func accent(in view: UIView) -> UIColor { view.tintColor }
}
