import SwiftUI
import UIKit

/// Semantic colors follow the host's system appearance and accessibility traits.
public enum RhineColor {
    public static var textPrimary: Color { Color(uiColor: .label) }
    public static var textSecondary: Color { Color(uiColor: .secondaryLabel) }
    public static var canvas: Color { Color(uiColor: .systemBackground) }
    public static var group: Color { Color(uiColor: .systemGroupedBackground) }
    public static var separator: Color { Color(uiColor: .separator) }
    public static var error: Color { Color(uiColor: .systemRed) }

    /// Resolves the host's `.tint(...)`; no independent hard-coded brand color.
    public static var accent: TintShapeStyle { .tint }
}
