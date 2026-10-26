import CoreGraphics

/// Composition spacing only. System Form, List and control insets remain native.
public enum RhineSpacing {
    public static let inline: CGFloat = 4
    public static let related: CGFloat = 8
    public static let group: CGFloat = 16
    public static let page: CGFloat = 20
}

public enum RhineTarget {
    /// Minimum custom interaction size, never a fixed row height.
    public static let minimum: CGFloat = 44
}
