import UIKit
import RhineDesign

final class OverviewPage: GalleryPage {
    override func viewDidLoad() {
        super.viewDidLoad()
        intro("RHINE DESIGN  /  UIKIT", "让界面自然生长", "颜色、文字与交互，遵循系统，也照顾每一种阅读方式。")
        let welcome = card("组件手册", detail: "从底部标签进入完整演示。每个动作都可以实际操作，所有内容均为本地合成数据。")
        for (text, symbol, index) in [("按钮 · 层级与反馈", "hand.tap", 1), ("表单 · 输入与草稿", "square.and.pencil", 2), ("状态 · 空内容与恢复", "tray", 3)] {
            welcome.addArrangedSubview(RhineButton(text, symbol: symbol, style: .secondary) { [weak self] in self?.tabBarController?.selectedIndex = index })
        }
        let typography = card("文字", detail: "系统字体随 Dynamic Type 调整。长文自然换行，不压缩字号。")
        typography.addArrangedSubview(galleryLabel("把重要的事，说清楚。", style: .title1))
        typography.addArrangedSubview(galleryLabel("标题 · 清晰的阅读层级", style: .headline))
        typography.addArrangedSubview(galleryLabel("正文 · 山间的风穿过树梢，沿着河岸慢慢行走。Long content stays readable across narrow windows and larger text sizes."))
        typography.addArrangedSubview(galleryLabel("辅助说明 · 让每一步都知道将发生什么。", style: .footnote, secondary: true))
        let colors = card("语义颜色", detail: "在右上角切换浅色和深色，观察系统语义色的变化。")
        for (name, description, color) in [("主要文字", "RhineColor.textPrimary", RhineColor.textPrimary), ("次要文字", "RhineColor.textSecondary", RhineColor.textSecondary), ("强调色", "继承宿主 tint", view.tintColor!), ("错误", "文字与颜色共同表达", RhineColor.error), ("背景", "RhineColor.canvas", RhineColor.canvas), ("分组", "RhineColor.group", RhineColor.group)] {
            let dot = UIView(); dot.backgroundColor = color; dot.layer.cornerRadius = 10
            dot.widthAnchor.constraint(equalToConstant: 40).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 40).isActive = true
            dot.layer.borderWidth = 0.5; dot.layer.borderColor = UIColor.gray.withAlphaComponent(0.25).cgColor
            let labels = UIStackView(arrangedSubviews: [galleryLabel(name), galleryLabel(description, style: .caption1, secondary: true)])
            labels.axis = .vertical; labels.spacing = 4
            let row = UIStackView(arrangedSubviews: [dot, labels]); row.spacing = 16; row.alignment = .center
            colors.addArrangedSubview(row)
        }
        let spacing = card("间距与触控", detail: "组合间距遵循语义；交互区域至少 44pt，内容可随文字增高。")
        for (name, value) in [("紧邻", RhineSpacing.inline), ("相关", RhineSpacing.related), ("分组", RhineSpacing.group), ("页面", RhineSpacing.page)] {
            let line = UIView(); line.backgroundColor = .tintColor; line.layer.cornerRadius = 3
            line.heightAnchor.constraint(equalToConstant: 6).isActive = true
            line.widthAnchor.constraint(equalToConstant: value * 4).isActive = true
            let row = UIStackView(arrangedSubviews: [galleryLabel("\(name)  \(Int(value))pt", style: .subheadline), line, UIView()]); row.spacing = 16; row.alignment = .center
            spacing.addArrangedSubview(row)
        }
        let environment = card("系统适配", detail: "查看实时外观、字号与辅助功能状态，或使用右上角的预览控制。")
        environment.addArrangedSubview(RhineButton("查看基础环境", symbol: "accessibility", style: .plain) { [weak self] in self?.navigationController?.pushViewController(FoundationViewController(), animated: true) })
        note("Rhine Design · UIKit 展示候选\n独立 iOS 设计体系 · 尚未发布")
    }
}
