import UIKit

@MainActor
private func fieldLabel(_ text: String, style: UIFont.TextStyle = .body) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: style)
    label.adjustsFontForContentSizeCategory = true
    label.numberOfLines = 0
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    return label
}

@MainActor
private final class FieldLayout: UIStackView {
    let caption: UILabel
    let message = fieldLabel("", style: .footnote)
    let help: String?
    init(title: String, help: String?, control: UIView) {
        caption = fieldLabel(title)
        self.help = help
        super.init(frame: .zero)
        axis = .vertical
        spacing = RhineSpacing.related
        addArrangedSubview(caption)
        addArrangedSubview(control)
        addArrangedSubview(message)
        show(error: nil)
    }
    required init(coder: NSCoder) { fatalError("Use init(title:help:control:)") }
    func show(error: String?) {
        message.text = error.map { "错误：\($0)" } ?? help
        message.textColor = error == nil ? RhineColor.textSecondary : RhineColor.error
        message.isHidden = message.text?.isEmpty != false
    }
    func pin(to view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor), trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topAnchor.constraint(equalTo: view.topAnchor), bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

/// Label, native input and supporting/error text. Validation and focus belong to the host.
@MainActor
public final class RhineTextField: UIView {
    public enum Purpose: Sendable { case text, email, url, password }
    public let input = UITextField()
    public var text: String { get { input.text ?? "" } set { input.text = newValue } }
    public var onChange: ((String) -> Void)?
    public var error: String? { didSet { layout.show(error: error); input.accessibilityHint = error ?? layout.help } }
    public var isEnabled: Bool = true { didSet { input.isEnabled = isEnabled } }
    private let layout: FieldLayout
    public init(_ title: String, purpose: Purpose = .text, help: String? = nil) {
        layout = FieldLayout(title: title, help: help, control: input)
        super.init(frame: .zero)
        input.borderStyle = .roundedRect
        input.font = RhineTypography.font(.body)
        input.adjustsFontForContentSizeCategory = true
        input.accessibilityLabel = title
        input.accessibilityHint = help
        input.heightAnchor.constraint(greaterThanOrEqualToConstant: RhineTarget.minimum).isActive = true
        input.autocorrectionType = .no
        switch purpose {
        case .text: input.textContentType = .nickname
        case .email: input.keyboardType = .emailAddress; input.autocapitalizationType = .none; input.textContentType = .emailAddress
        case .url: input.keyboardType = .URL; input.autocapitalizationType = .none; input.textContentType = .URL
        case .password: input.isSecureTextEntry = true; input.autocapitalizationType = .none
        }
        input.addTarget(self, action: #selector(changed), for: .editingChanged)
        layout.pin(to: self)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(_:purpose:help:)") }
    @objc private func changed() { onChange?(text) }
}

@MainActor
public final class RhineToggle: UIView {
    public let control = UISwitch()
    public var isOn: Bool { get { control.isOn } set { control.isOn = newValue } }
    public var onChange: ((Bool) -> Void)?
    public var isEnabled = true { didSet { control.isEnabled = isEnabled } }
    public var error: String? { didSet { layout.show(error: error); control.accessibilityHint = error ?? layout.help } }
    private let layout: FieldLayout
    public init(_ title: String, help: String? = nil) {
        let holder = UIStackView(arrangedSubviews: [control, UIView()])
        holder.alignment = .center
        holder.heightAnchor.constraint(greaterThanOrEqualToConstant: RhineTarget.minimum).isActive = true
        layout = FieldLayout(title: title, help: help, control: holder)
        super.init(frame: .zero)
        control.accessibilityLabel = title
        control.accessibilityHint = help
        control.addTarget(self, action: #selector(changed), for: .valueChanged)
        layout.pin(to: self)
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(_:help:)") }
    @objc private func changed() { onChange?(isOn) }
}

@MainActor
public final class RhineChoice: UIView {
    public struct Option: Sendable, Equatable {
        public let id: String
        public let title: String
        public init(id: String, title: String) { self.id = id; self.title = title }
    }
    public let control = UIButton(type: .system)
    public let options: [Option]
    public var selectedID: String { didSet { update() } }
    public var onChange: ((String) -> Void)?
    public var isEnabled = true { didSet { control.isEnabled = isEnabled } }
    public var error: String? { didSet { layout.show(error: error); control.accessibilityHint = error ?? layout.help } }
    private let layout: FieldLayout
    public init(_ title: String, options: [Option], selectedID: String, help: String? = nil) {
        precondition(!options.isEmpty && Set(options.map(\.id)).count == options.count)
        precondition(options.contains { $0.id == selectedID })
        self.options = options
        self.selectedID = selectedID
        layout = FieldLayout(title: title, help: help, control: control)
        super.init(frame: .zero)
        control.accessibilityLabel = title
        control.accessibilityHint = help
        control.heightAnchor.constraint(greaterThanOrEqualToConstant: RhineTarget.minimum).isActive = true
        control.showsMenuAsPrimaryAction = true
        layout.pin(to: self)
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) {
            (control: RhineChoice, _: UITraitCollection) in control.update()
        }
        update()
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(_:options:selectedID:help:)") }
    private func update() {
        precondition(options.contains { $0.id == selectedID }, "Selection must refer to an existing option")
        var config = UIButton.Configuration.tinted()
        config.title = options.first { $0.id == selectedID }?.title
        config.image = UIImage(systemName: "chevron.up.chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = RhineSpacing.related
        config.titleLineBreakMode = .byWordWrapping
        config.buttonSize = .large
        let font = RhineTypography.font(.body, compatibleWith: traitCollection)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var result = incoming
            result.font = font
            return result
        }
        control.configuration = config
        control.titleLabel?.adjustsFontForContentSizeCategory = true
        control.accessibilityValue = config.title
        control.menu = UIMenu(children: options.map { option in
            UIAction(title: option.title, state: option.id == selectedID ? .on : .off) { [weak self] _ in
                guard let self, self.isEnabled else { return }
                self.selectedID = option.id
                self.onChange?(option.id)
            }
        })
    }
}
