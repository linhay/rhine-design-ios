import UIKit
import RhineDesign

final class ButtonsPage: GalleryPage {
    private let result = galleryLabel("等待操作", style: .subheadline, secondary: true)
    private let count = galleryLabel("激活次数：0", style: .footnote, secondary: true)
    private var calls = 0
    private var task: RhineButton!
    private var complete: RhineButton!
    private var fail: RhineButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        intro("01  /  ACTIONS", "每个动作，都有回应", "主次层级、禁用与忙碌，在同一套原生按钮里清楚表达。")
        let taskCard = card("可控任务", detail: "开始后手动选择成功或失败。忙碌期间重复激活不会增加调用次数。")
        result.accessibilityIdentifier = "button.result"
        count.accessibilityIdentifier = "button.count"
        task = RhineButton("开始模拟任务", symbol: "arrow.up.circle") { [weak self] in
            guard let self else { return }
            self.task.isLoading = true
            self.calls += 1
            self.count.text = "激活次数：\(self.calls)"
            self.result.text = "正在处理 · 等待你选择结果"
            self.complete.isEnabled = true; self.fail.isEnabled = true
        }
        task.accessibilityIdentifier = "button.start"
        complete = RhineButton("模拟成功", symbol: "checkmark.circle", style: .secondary) { [weak self] in self?.finish(success: true) }
        fail = RhineButton("模拟失败", symbol: "exclamationmark.circle", style: .secondary) { [weak self] in self?.finish(success: false) }
        complete.isEnabled = false; fail.isEnabled = false
        for item in [task!, result, count, complete!, fail!] { taskCard.addArrangedSubview(item) }
        let hierarchy = card("视觉层级", detail: "一个页面优先突出一个主动作；破坏性意图独立于视觉层级。")
        for (title, style, symbol) in [("主要动作", RhineButton.Style.primary, "plus"), ("次要动作", .secondary, "square.and.arrow.down"), ("轻量动作", .plain, "arrow.right")] {
            hierarchy.addArrangedSubview(RhineButton(title, symbol: symbol, style: style) { [weak self] in self?.result.text = "已激活：\(title)" })
        }
        hierarchy.addArrangedSubview(RhineButton("删除演示内容", symbol: "trash", style: .secondary, role: .destructive) { [weak self] in self?.result.text = "已删除演示内容 · 仅本地状态" })
        let states = card("静态状态", detail: "禁用表示当前不可执行；忙碌表示已开始处理。动作名称始终保留。")
        let disabled = RhineButton("暂不可用", symbol: "lock"); disabled.isEnabled = false
        let busy = RhineButton("保存更改", symbol: "checkmark"); busy.isLoading = true; busy.loadingText = "正在保存"
        states.addArrangedSubview(disabled); states.addArrangedSubview(busy)
        let long = card("长文与字号", detail: "按钮可纵向增高，不把完整动作名称截断成省略号。")
        long.addArrangedSubview(RhineButton("保存全部更改并返回这份长标题的示例文档", style: .secondary) { [weak self] in self?.result.text = "长文按钮已激活" })
        note("点击与辅助技术激活共享同一门禁。任务、错误恢复和完成时机由示例宿主管理。")
    }
    private func finish(success: Bool) {
        guard task.isLoading else { return }
        task.isLoading = false
        result.text = success ? "已完成 · 可以再次开始" : "任务失败 · 草稿未丢失，可以重试"
        result.textColor = success ? RhineColor.textPrimary : RhineColor.error
        complete.isEnabled = false; fail.isEnabled = false
        UIAccessibility.post(notification: .announcement, argument: result.text)
    }
}
