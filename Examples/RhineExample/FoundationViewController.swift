import UIKit
import RhineDesign

final class FoundationViewController: UIViewController {
    private let content = UIStackView()
    private var environmentValues: [String: UILabel] = [:]
    private var textRoles: [(UILabel, RhineTypography.Role)] = []
    private let accentLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Rhine Foundation"
        view.backgroundColor = RhineColor.canvas

        let scroll = UIScrollView()
        scroll.accessibilityIdentifier = "foundation.scroll"
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        content.axis = .vertical
        content.spacing = RhineSpacing.group
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        let width = content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor,
                                                   constant: -2 * RhineSpacing.page)
        width.priority = .defaultHigh
        // A real constrained content container for narrow-layout validation.
        // This changes layout only; system appearance and accessibility traits remain inherited.
        let maximumContentWidth: CGFloat = ProcessInfo.processInfo.arguments.contains("--preview-narrow-content") ? 320 : 720
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: RhineSpacing.page),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -RhineSpacing.page),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: scroll.contentLayoutGuide.leadingAnchor, constant: RhineSpacing.page),
            content.trailingAnchor.constraint(lessThanOrEqualTo: scroll.contentLayoutGuide.trailingAnchor, constant: -RhineSpacing.page),
            content.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
            scroll.contentLayoutGuide.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            content.widthAnchor.constraint(lessThanOrEqualToConstant: maximumContentWidth),
            width
        ])

        content.addArrangedSubview(label("Independent UIKit foundations", role: .title))
        content.addArrangedSubview(label("Synthetic content only. This UIKit app consumes the public RhineDesign package; first-batch components are tracked separately."))

        let environment = section("System environment")
        for key in ["Appearance", "Contrast", "Dynamic Type", "Reduce Motion", "Reduce Transparency"] {
            environment.addArrangedSubview(label(key, role: .label))
            let value = label("", role: .supporting, color: RhineColor.textSecondary)
            value.accessibilityIdentifier = "environment.\(key)"
            environmentValues[key] = value
            environment.addArrangedSubview(value)
        }

        let colors = section("Semantic colors")
        colors.addArrangedSubview(label("Primary text"))
        colors.addArrangedSubview(label("Secondary text", color: RhineColor.textSecondary))
        configure(accentLabel, text: "Host accent", role: .body)
        colors.addArrangedSubview(accentLabel)
        colors.addArrangedSubview(label("Error: synthetic example; no operation failed.", color: RhineColor.error))
        let separator = UIView()
        separator.backgroundColor = RhineColor.separator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        colors.addArrangedSubview(separator)
        for (name, color) in [("Canvas surface", RhineColor.canvas), ("Grouped surface", RhineColor.group)] {
            let row = label(name)
            row.backgroundColor = color
            colors.addArrangedSubview(row)
        }

        let typography = section("Typography")
        typography.addArrangedSubview(label("Title · 系统标题", role: .title))
        typography.addArrangedSubview(label("Body · 示例内容在较大辅助字号下自然换行，保留完整信息和可滚动的阅读路径。 Long synthetic content wraps without reducing the text size."))
        typography.addArrangedSubview(label("Label · 持久标签", role: .label))
        typography.addArrangedSubview(label("Supporting · 合成说明", role: .supporting))
        content.addArrangedSubview(label("No custom animation is added. System accessibility preferences above are read live.", role: .supporting, color: RhineColor.textSecondary))

        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self,
                                 UITraitPreferredContentSizeCategory.self]) {
            (controller: FoundationViewController, _: UITraitCollection) in
            controller.refreshEnvironment()
        }
        for notification in [UIAccessibility.reduceMotionStatusDidChangeNotification,
                             UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                             UIApplication.didBecomeActiveNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(refreshEnvironment),
                                                   name: notification, object: nil)
        }
        refreshEnvironment()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshEnvironment()
    }

    @objc private func refreshEnvironment() {
        environmentValues["Appearance"]?.text = traitCollection.userInterfaceStyle == .dark ? "Dark" : "Light"
        environmentValues["Contrast"]?.text = traitCollection.accessibilityContrast == .high ? "Increased" : "Standard"
        environmentValues["Dynamic Type"]?.text = traitCollection.preferredContentSizeCategory.rawValue
        environmentValues["Reduce Motion"]?.text = UIAccessibility.isReduceMotionEnabled ? "On" : "Off"
        environmentValues["Reduce Transparency"]?.text = UIAccessibility.isReduceTransparencyEnabled ? "On" : "Off"
        accentLabel.textColor = RhineColor.accent(in: accentLabel)
        for (label, role) in textRoles {
            label.font = RhineTypography.font(role, compatibleWith: traitCollection)
        }
    }

    private func label(_ text: String, role: RhineTypography.Role = .body,
                       color: UIColor = RhineColor.textPrimary) -> UILabel {
        let label = UILabel()
        configure(label, text: text, role: role)
        label.textColor = color
        return label
    }

    private func configure(_ label: UILabel, text: String, role: RhineTypography.Role) {
        label.text = text
        label.font = RhineTypography.font(role, compatibleWith: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        textRoles.append((label, role))
    }

    private func section(_ title: String) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = RhineSpacing.related
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: RhineSpacing.group,
                                                                 leading: RhineSpacing.group,
                                                                 bottom: RhineSpacing.group,
                                                                 trailing: RhineSpacing.group)
        stack.backgroundColor = RhineColor.group
        stack.addArrangedSubview(label(title, role: .title))
        content.addArrangedSubview(stack)
        return stack
    }
}
