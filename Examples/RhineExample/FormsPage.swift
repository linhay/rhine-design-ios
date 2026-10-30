import UIKit
import RhineDesign

struct DemoProfile: Equatable {
    var name = "示例访客"
    var email = "hello@example.com"
    var website = "https://example.com"
    var password = ""
    var notifications = true
    var frequency = "weekly"
}

final class FormsPage: GalleryPage {
    private var saved = DemoProfile()
    private let summary = galleryLabel("")
    private var openButton: RhineButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        intro("02  /  INPUT", "安心输入，从容修改", "持久标签、字段说明与错误反馈，帮助你完成一份真实的编辑流程。")
        let profile = card("个人偏好", detail: "本地合成资料，不请求网络，也不写入账号或密码存储。")
        summary.accessibilityIdentifier = "form.summary"
        profile.addArrangedSubview(summary)
        openButton = RhineButton("编辑示例资料", symbol: "square.and.pencil") { [weak self] in self?.edit() }
        openButton.accessibilityIdentifier = "form.open"
        profile.addArrangedSubview(openButton)
        refresh()
        let examples = card("字段状态", detail: "说明紧随字段；错误带文字标识。禁用字段仍保留标签和值。")
        let regular = RhineTextField("项目名称", help: "给项目起一个容易识别的名字。")
        regular.text = "河岸漫步"
        let error = RhineTextField("联系邮箱", purpose: .email, help: "仅作输入用途示例。")
        error.text = "not-an-email"; error.error = "请填写完整的示例邮箱，例如 hello@example.com。错误提示可以很长，窄窗口下也应完整换行。"
        let disabled = RhineTextField("只读示例", help: "当前步骤不可编辑。")
        disabled.text = "Rhine Design"; disabled.isEnabled = false
        let toggle = RhineToggle("接收提醒", help: "开关仅修改当前草稿，不立即保存。")
        toggle.isOn = true
        let choice = RhineChoice("内容语言", options: [.init(id: "zh", title: "简体中文"), .init(id: "en", title: "English")], selectedID: "zh")
        for field in [regular, error, disabled, toggle, choice] { examples.addArrangedSubview(field) }
        note("尝试：编辑 → 清空必填 → 保存 → 修正错误 → 模拟失败 → 重试成功；或修改后取消，选择继续编辑或放弃修改。")
    }
    private func refresh() {
        summary.text = "\(saved.name)\n\(saved.email)\n提醒：\(saved.notifications ? "开启" : "关闭") · \(saved.frequency == "weekly" ? "每周摘要" : "每日摘要")"
    }
    private func edit() {
        let editor = ProfileEditor(profile: saved)
        editor.onSave = { [weak self] value in self?.saved = value; self?.refresh() }
        editor.onClose = { [weak self] in UIAccessibility.post(notification: .screenChanged, argument: self?.openButton) }
        let nav = UINavigationController(rootViewController: editor)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
        nav.presentationController?.delegate = editor
    }
}

final class ProfileEditor: GalleryPage, UITextFieldDelegate, UIAdaptivePresentationControllerDelegate {
    var onSave: ((DemoProfile) -> Void)?
    var onClose: (() -> Void)?
    private let original: DemoProfile
    private let name = RhineTextField("显示名称", help: "必填。只使用合成资料。")
    private let email = RhineTextField("联系邮箱", purpose: .email, help: "必填。例如 hello@example.com；不会发送邮件。")
    private let website = RhineTextField("主页链接", purpose: .url, help: "选填。使用 https:// 开头的示例地址。")
    private let password = RhineTextField("演示口令", purpose: .password, help: "选填。安全输入，不保存到设备；请勿输入真实密码。")
    private let notifications = RhineToggle("接收演示提醒")
    private let frequency = RhineChoice("提醒频率", options: [.init(id: "weekly", title: "每周摘要"), .init(id: "daily", title: "每日摘要")], selectedID: "weekly")
    private let feedback = galleryLabel("尚未提交", style: .footnote, secondary: true)
    private var submitted = false
    private var saving = false
    private var lockedDraft: DemoProfile?
    private var resultControls: UIStackView!
    private var fillButton: RhineButton!
    private var clearButton: RhineButton!
    private var saveButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!
    private var fields: [RhineTextField] { [name, email, website, password] }
    init(profile: DemoProfile) { original = profile; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("Use init(profile:)") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "编辑资料"
        cancelButton = UIBarButtonItem(title: "取消", primaryAction: UIAction { [weak self] _ in self?.cancel() })
        saveButton = UIBarButtonItem(title: "保存", primaryAction: UIAction { [weak self] _ in self?.save() })
        saveButton.accessibilityIdentifier = "form.save"
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        let demo = card("演示操作", detail: "输入与校验由这个示例管理。保存后手动选择成功或失败。")
        feedback.accessibilityIdentifier = "form.feedback"
        demo.addArrangedSubview(feedback)
        fillButton = RhineButton("填入有效示例", style: .secondary) { [weak self] in self?.populate(DemoProfile()); self?.updateDirty() }
        clearButton = RhineButton("清空必填", style: .plain) { [weak self] in self?.name.text = ""; self?.email.text = ""; self?.updateDirty() }
        demo.addArrangedSubview(fillButton); demo.addArrangedSubview(clearButton)
        resultControls = UIStackView(arrangedSubviews: [
            RhineButton("模拟保存成功", symbol: "checkmark") { [weak self] in self?.finish(success: true) },
            RhineButton("模拟保存失败", style: .secondary) { [weak self] in self?.finish(success: false) }
        ])
        resultControls.axis = .vertical; resultControls.spacing = 12; resultControls.isHidden = true
        demo.addArrangedSubview(resultControls)
        let inputs = card("基本信息")
        for (index, field) in fields.enumerated() {
            field.input.accessibilityIdentifier = "form.field.\(index)"
            field.input.delegate = self
            field.input.returnKeyType = index == fields.count - 1 ? .done : .next
            field.onChange = { [weak self] _ in self?.updateDirty() }
            inputs.addArrangedSubview(field)
        }
        let preferences = card("通知偏好")
        preferences.addArrangedSubview(notifications); preferences.addArrangedSubview(frequency)
        notifications.onChange = { [weak self] _ in self?.updateDirty() }
        frequency.onChange = { [weak self] _ in self?.updateDirty() }
        populate(original)
        note("保存失败保留全部草稿。提交中禁止修改和关闭；有未保存内容时通过“取消”明确选择去留。")
    }
    private var draft: DemoProfile {
        DemoProfile(name: name.text, email: email.text, website: website.text, password: password.text,
                    notifications: notifications.isOn, frequency: frequency.selectedID)
    }
    private func populate(_ profile: DemoProfile) {
        name.text = profile.name; email.text = profile.email; website.text = profile.website; password.text = profile.password
        notifications.isOn = profile.notifications; frequency.selectedID = profile.frequency
        fields.forEach { $0.error = nil }
    }
    private func updateDirty() { navigationController?.isModalInPresentation = saving || draft != original }
    private func validate(_ field: RhineTextField) -> Bool {
        let value = field.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if field === name {
            field.error = value.isEmpty ? "请填写显示名称。" : nil
        } else if field === email {
            let parts = value.split(separator: "@", omittingEmptySubsequences: false)
            let valid = parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".") && !value.contains(where: { $0.isWhitespace })
            field.error = valid ? nil : "请填写示例邮箱，例如 hello@example.com。"
        } else if field === website {
            let url = URL(string: value)
            field.error = value.isEmpty || (url?.scheme == "https" && url?.host?.isEmpty == false) ? nil : "示例链接需要 https:// 和完整主机名。"
        }
        return field.error == nil
    }
    private func save() {
        guard !saving else { return }
        submitted = true
        let invalid = fields.filter { !validate($0) }
        guard let first = invalid.first else {
            view.endEditing(true)
            lockedDraft = draft
            setSaving(true)
            feedback.text = "正在保存 · 选择一个模拟结果"
            feedback.textColor = RhineColor.textSecondary
            scroll.setContentOffset(CGPoint(x: 0, y: -scroll.adjustedContentInset.top), animated: false)
            return
        }
        feedback.text = "请修正 \(invalid.count) 个字段，输入已保留。"
        feedback.textColor = RhineColor.error
        first.input.becomeFirstResponder()
        reveal(first)
        UIAccessibility.post(notification: .layoutChanged, argument: first.input)
    }
    private func setSaving(_ value: Bool) {
        saving = value
        fields.forEach { $0.isEnabled = !value }
        notifications.isEnabled = !value; frequency.isEnabled = !value
        fillButton.isEnabled = !value; clearButton.isEnabled = !value
        cancelButton.isEnabled = !value; saveButton.isEnabled = !value
        resultControls.isHidden = !value
        updateDirty()
    }
    private func finish(success: Bool) {
        guard saving, var accepted = lockedDraft else { return }
        lockedDraft = nil
        setSaving(false)
        if success {
            accepted.password = "" // No credential persistence, even in the in-memory saved preview.
            onSave?(accepted)
            close()
        } else {
            feedback.text = "保存失败：模拟连接中断。草稿已保留，请重试。"
            feedback.textColor = RhineColor.error
            UIAccessibility.post(notification: .announcement, argument: feedback.text)
        }
    }
    private func cancel() {
        guard !saving else { return }
        guard draft != original else { close(); return }
        let alert = UIAlertController(title: "放弃未保存的修改？", message: "继续编辑会保留草稿；放弃后恢复原来的资料。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "继续编辑", style: .cancel))
        alert.addAction(UIAlertAction(title: "放弃修改", style: .destructive) { [weak self] _ in self?.close() })
        present(alert, animated: true)
    }
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { onClose?() }
    private func close() {
        let completion = onClose
        dismiss(animated: !UIAccessibility.isReduceMotionEnabled, completion: completion)
    }
    private func reveal(_ field: RhineTextField) {
        view.layoutIfNeeded()
        scroll.scrollRectToVisible(field.convert(field.bounds, to: scroll).insetBy(dx: 0, dy: -16), animated: false)
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let field = fields.first(where: { $0.input === textField }) { reveal(field) }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if submitted, !saving, let field = fields.first(where: { $0.input === textField }) { _ = validate(field) }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let index = fields.firstIndex(where: { $0.input === textField }) else { return true }
        if index + 1 < fields.count { fields[index + 1].input.becomeFirstResponder() }
        else { textField.resignFirstResponder() }
        return false
    }
}
