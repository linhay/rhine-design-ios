import UIKit
import RhineDesign

@MainActor
func galleryLabel(_ text: String, style: UIFont.TextStyle = .body, secondary: Bool = false) -> UILabel {
    let view = UILabel()
    view.text = text
    view.numberOfLines = 0
    view.font = .preferredFont(forTextStyle: style)
    view.adjustsFontForContentSizeCategory = true
    view.textColor = secondary ? RhineColor.textSecondary : RhineColor.textPrimary
    view.setContentCompressionResistancePriority(.required, for: .vertical)
    return view
}

@MainActor
class GalleryPage: UIViewController {
    let scroll = UIScrollView()
    let content = UIStackView()
    var narrowConstraint: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .interactive
        scroll.accessibilityIdentifier = "gallery.scroll"
        view.addSubview(scroll)
        content.axis = .vertical
        content.spacing = 24
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        let preferred = content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
        preferred.priority = .defaultHigh
        narrowConstraint = content.widthAnchor.constraint(lessThanOrEqualToConstant: 720)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            scroll.contentLayoutGuide.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
            content.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(lessThanOrEqualTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
            preferred, narrowConstraint
        ])
    }
    func intro(_ eyebrow: String, _ title: String, _ detail: String) {
        let stack = UIStackView(arrangedSubviews: [galleryLabel(eyebrow, style: .caption1, secondary: true),
                                                   galleryLabel(title, style: .largeTitle),
                                                   galleryLabel(detail, secondary: true)])
        stack.axis = .vertical
        stack.spacing = 10
        content.addArrangedSubview(stack)
    }
    @discardableResult func card(_ title: String, detail: String? = nil) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = .init(top: 20, leading: 16, bottom: 20, trailing: 16)
        stack.backgroundColor = .secondarySystemGroupedBackground
        stack.layer.cornerRadius = 20
        stack.layer.cornerCurve = .continuous
        stack.addArrangedSubview(galleryLabel(title, style: .headline))
        if let detail { stack.addArrangedSubview(galleryLabel(detail, style: .footnote, secondary: true)) }
        content.addArrangedSubview(stack)
        return stack
    }
    func note(_ text: String) { content.addArrangedSubview(galleryLabel(text, style: .footnote, secondary: true)) }
}

@MainActor
final class GalleryController: UITabBarController {
    private var appearance = 0
    private var size = 0
    private var narrow = false
    private let categories: [UIContentSizeCategory] = [.large, .extraExtraExtraLarge, .accessibilityExtraExtraExtraLarge]
    override func viewDidLoad() {
        super.viewDidLoad()
        let pages: [(GalleryPage, String, String)] = [
            (OverviewPage(), "总览", "square.grid.2x2"),
            (ButtonsPage(), "按钮", "hand.tap"),
            (FormsPage(), "表单", "rectangle.and.pencil.and.ellipsis"),
            (StatesPage(), "状态", "tray")
        ]
        viewControllers = pages.enumerated().map { index, entry in
            let navigation = UINavigationController(rootViewController: entry.0)
            entry.0.title = entry.1
            entry.0.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "预览", image: UIImage(systemName: "slider.horizontal.3"), target: self, action: #selector(showPreview))
            navigation.tabBarItem = UITabBarItem(title: entry.1, image: UIImage(systemName: entry.2), tag: index)
            navigation.tabBarItem.accessibilityIdentifier = "tab.\(index)"
            return navigation
        }
        if let arg = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--gallery-tab=") }),
           let index = Int(arg.split(separator: "=").last ?? ""), (0..<4).contains(index) { selectedIndex = index }
    }
    @objc private func showPreview() {
        let page = GalleryPage()
        page.title = "外观预览"
        page.loadViewIfNeeded()
        page.intro("PREVIEW", "换个视角", "预览仅作用于这个 App；跟随系统时读取真实设置。")
        let card = page.card("外观与排版")
        let appearanceControl = UISegmentedControl(items: ["系统", "浅色", "深色"])
        appearanceControl.selectedSegmentIndex = appearance
        appearanceControl.accessibilityLabel = "预览外观"
        appearanceControl.addAction(UIAction { [weak self, weak appearanceControl] _ in
            guard let self, let appearanceControl else { return }
            self.appearance = appearanceControl.selectedSegmentIndex
            self.applyPreview()
        }, for: .valueChanged)
        card.addArrangedSubview(appearanceControl)
        let choice = RhineChoice("文字大小", options: [.init(id: "0", title: "跟随系统"), .init(id: "1", title: "标准字号"), .init(id: "2", title: "特大字号"), .init(id: "3", title: "最大辅助字号")], selectedID: String(size))
        choice.onChange = { [weak self] value in self?.size = Int(value) ?? 0; self?.applyPreview() }
        card.addArrangedSubview(choice)
        let toggle = RhineToggle("窄内容预览", help: "将内容限制为 320pt；不模拟设备或改变真实窗口。")
        toggle.isOn = narrow
        toggle.onChange = { [weak self] on in self?.narrow = on; self?.applyPreview() }
        card.addArrangedSubview(toggle)
        let reset = RhineButton("恢复跟随系统", style: .secondary) { [weak self, weak appearanceControl, weak choice, weak toggle] in
            self?.appearance = 0; self?.size = 0; self?.narrow = false
            appearanceControl?.selectedSegmentIndex = 0; choice?.selectedID = "0"; toggle?.isOn = false
            self?.applyPreview()
        }
        card.addArrangedSubview(reset)
        page.note("减少动态与提高对比度遵循系统辅助功能设置。App 不添加装饰性动画；模拟操作由你手动完成。")
        page.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完成", primaryAction: UIAction { [weak page] _ in page?.dismiss(animated: true) })
        let nav = UINavigationController(rootViewController: page)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
    private func applyPreview() {
        overrideUserInterfaceStyle = appearance == 0 ? .unspecified : appearance == 1 ? .light : .dark
        presentedViewController?.overrideUserInterfaceStyle = overrideUserInterfaceStyle
        if size == 0 {
            traitOverrides.remove(UITraitPreferredContentSizeCategory.self)
            presentedViewController?.traitOverrides.remove(UITraitPreferredContentSizeCategory.self)
        } else {
            traitOverrides.preferredContentSizeCategory = categories[size - 1]
            presentedViewController?.traitOverrides.preferredContentSizeCategory = categories[size - 1]
        }
        for case let nav as UINavigationController in viewControllers ?? [] {
            if let page = nav.viewControllers.first as? GalleryPage {
                page.loadViewIfNeeded()
                page.narrowConstraint.constant = narrow ? 320 : 720
                page.navigationItem.prompt = appearance == 0 && size == 0 && !narrow ? nil : "预览模式 · 可恢复跟随系统"
            }
        }
    }
}
