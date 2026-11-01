import UIKit

/// A native configured button with one activation gate for touch and accessibility.
@MainActor
public final class RhineButton: UIControl {
    public enum Style: CaseIterable, Sendable { case primary, secondary, plain }
    public enum Role: Sendable { case normal, destructive }
    public var title: String { didSet { updatePresentation() } }
    public var symbol: String? { didSet { updatePresentation() } }
    public var style: Style { didSet { updatePresentation() } }
    public var role: Role { didSet { updatePresentation() } }
    public var isLoading = false { didSet { updatePresentation() } }
    public var loadingText = "正在处理" { didSet { updatePresentation() } }
    public var onActivate: (() -> Void)?
    public override var isEnabled: Bool { didSet { updatePresentation() } }
    private let button = UIButton(type: .system)

    public init(_ title: String, symbol: String? = nil, style: Style = .primary,
                role: Role = .normal, action: (() -> Void)? = nil) {
        self.title = title
        self.symbol = symbol
        self.style = style
        self.role = role
        self.onActivate = action
        super.init(frame: .zero)
        isAccessibilityElement = true
        button.isAccessibilityElement = false
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: RhineTarget.minimum),
            widthAnchor.constraint(greaterThanOrEqualToConstant: RhineTarget.minimum)
        ])
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) {
            (control: RhineButton, _: UITraitCollection) in control.updatePresentation()
        }
        updatePresentation()
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(_:symbol:style:role:action:)") }

    /// Returns false when disabled or busy. The host owns task state and completion.
    @discardableResult public func activate() -> Bool {
        guard isEnabled, !isLoading else { return false }
        onActivate?()
        return true
    }
    @objc private func tapped() { activate() }
    public override func accessibilityActivate() -> Bool { activate() }
    public override var intrinsicContentSize: CGSize { button.intrinsicContentSize }

    private func updatePresentation() {
        var config: UIButton.Configuration
        switch style {
        case .primary: config = .filled()
        case .secondary: config = .tinted()
        case .plain: config = .plain()
        }
        config.title = title
        config.image = symbol.flatMap { UIImage(systemName: $0) }
        config.imagePadding = RhineSpacing.related
        config.titleLineBreakMode = .byWordWrapping
        config.showsActivityIndicator = isLoading
        config.buttonSize = .large
        if role == .destructive { config.baseBackgroundColor = .systemRed; config.baseForegroundColor = style == .primary ? .white : .systemRed }
        let font = RhineTypography.font(.body, compatibleWith: traitCollection)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var result = incoming
            result.font = font
            return result
        }
        button.configuration = config
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.isEnabled = isEnabled && !isLoading
        accessibilityLabel = title
        accessibilityValue = isLoading ? loadingText : nil
        accessibilityTraits = isEnabled && !isLoading ? [.button] : [.button, .notEnabled]
        invalidateIntrinsicContentSize()
    }
}
