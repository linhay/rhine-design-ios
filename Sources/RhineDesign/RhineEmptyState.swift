import UIKit

/// Empty content and no search results only. Loading, permissions and failures are host states.
@MainActor
public final class RhineEmptyState: UIView {
    public enum Kind: Sendable { case empty, search }
    public init(title: String, message: String? = nil, symbol: String? = nil,
                kind: Kind = .empty, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        super.init(frame: .zero)
        var configuration: UIContentUnavailableConfiguration = kind == .search ? .search() : .empty()
        configuration.text = title
        configuration.secondaryText = message
        if let symbol { configuration.image = UIImage(systemName: symbol) }
        let systemContent = configuration.makeContentView()
        let stack = UIStackView(arrangedSubviews: [systemContent])
        stack.axis = .vertical
        stack.spacing = RhineSpacing.group
        if let actionTitle, !actionTitle.isEmpty, let action {
            stack.addArrangedSubview(RhineButton(actionTitle, action: action))
        }
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor), stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor), stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(title:message:symbol:kind:actionTitle:action:)") }
}
