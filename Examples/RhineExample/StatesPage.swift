import UIKit
import RhineDesign

final class StatesPage: GalleryPage {
    private var selection: RhineChoice!
    private let stage = UIStackView()
    private var state = "empty"
    private var longCopy = false
    override func viewDidLoad() {
        super.viewDidLoad()
        intro("03  /  CONTENT", "没有内容，也有方向", "区分空内容、无匹配和失败。让下一步明确，而不是留下一个空白页面。")
        let controls = card("选择场景")
        selection = RhineChoice("展示状态", options: [
            .init(id: "empty", title: "尚无内容"), .init(id: "search", title: "无匹配结果"),
            .init(id: "loading", title: "正在加载"), .init(id: "failure", title: "加载失败"),
            .init(id: "permission", title: "权限未开启"), .init(id: "content", title: "已有内容")
        ], selectedID: state)
        selection.onChange = { [weak self] value in self?.state = value; self?.render() }
        controls.addArrangedSubview(selection)
        let toggle = RhineToggle("显示长说明", help: "检查窄窗口与辅助字号下的换行和滚动。")
        toggle.onChange = { [weak self] on in self?.longCopy = on; self?.render() }
        controls.addArrangedSubview(toggle)
        stage.axis = .vertical; stage.spacing = 20; stage.accessibilityIdentifier = "state.stage"
        let preview = card("实时预览")
        preview.addArrangedSubview(stage)
        render()
        note("加载、错误和权限策略归宿主管理。此处的“演示授权”仅改变合成状态，不打开设置或请求真实权限。")
    }
    private func change(_ value: String) {
        state = value; selection.selectedID = value; render()
        UIAccessibility.post(notification: .layoutChanged, argument: stage.arrangedSubviews.first)
    }
    private func render() {
        stage.arrangedSubviews.forEach { stage.removeArrangedSubview($0); $0.removeFromSuperview() }
        let extra = longCopy ? " 即使窗口变窄或文字放大，说明和下一步操作也应保持完整可读。This longer synthetic description wraps naturally without truncating essential guidance." : ""
        switch state {
        case "empty":
            stage.addArrangedSubview(RhineEmptyState(title: "收藏从这里开始", message: "留住喜欢的灵感，下一次打开就能看见。" + extra, symbol: "bookmark", actionTitle: "添加示例收藏") { [weak self] in self?.change("content") })
        case "search":
            stage.addArrangedSubview(RhineEmptyState(title: "没有找到“山海”", message: "试试其他关键词，或清除筛选查看全部内容。" + extra, kind: .search, actionTitle: "清除筛选") { [weak self] in self?.change("content") })
        case "loading":
            let progress = UIActivityIndicatorView(style: .medium); progress.startAnimating()
            stage.addArrangedSubview(progress)
            stage.addArrangedSubview(galleryLabel("正在加载示例内容…", style: .headline))
            stage.addArrangedSubview(galleryLabel("状态持续到你选择一个结果。" + extra, secondary: true))
            stage.addArrangedSubview(RhineButton("返回内容", style: .secondary) { [weak self] in self?.change("content") })
            stage.addArrangedSubview(RhineButton("返回错误", style: .plain) { [weak self] in self?.change("failure") })
        case "failure":
            stage.addArrangedSubview(galleryLabel("暂时无法加载", style: .title2))
            let error = galleryLabel("模拟连接中断，没有丢失已有资料。" + extra); error.textColor = RhineColor.error
            stage.addArrangedSubview(error)
            stage.addArrangedSubview(RhineButton("重新加载", symbol: "arrow.clockwise") { [weak self] in self?.change("loading") })
        case "permission":
            stage.addArrangedSubview(galleryLabel("尚未开启访问权限", style: .title2))
            stage.addArrangedSubview(galleryLabel("说明为什么需要权限，并提供用户能完成的路径。这里仅演示，不读取相册或文件。" + extra, secondary: true))
            stage.addArrangedSubview(RhineButton("演示授权后效果", symbol: "lock.open", style: .secondary) { [weak self] in self?.change("content") })
        default:
            stage.addArrangedSubview(galleryLabel("一份新的收藏", style: .title2))
            stage.addArrangedSubview(galleryLabel("河岸漫步\n来自日常的细小灵感，也值得认真保存。" + extra))
            stage.addArrangedSubview(RhineButton("移除示例收藏", symbol: "trash", style: .plain, role: .destructive) { [weak self] in self?.change("empty") })
        }
    }
}
