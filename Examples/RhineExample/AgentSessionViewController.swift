import UIKit
import RhineDesign

/// A bounded, synthetic host recipe. Nothing here is a RhineDesign public API or a transport.
@MainActor
final class AgentSessionViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate {
    private let model = AgentSessionModel()
    private let timeline = UIScrollView()
    private let messages = UIStackView()
    private let composer = UIScrollView()
    private let input = RhineTextField("消息草稿")
    private let send = RhineButton("发送")
    private let latest = RhineButton("查看最新", style: .plain)
    private let connection = galleryLabel("", style: .footnote, secondary: true)
    private let run = galleryLabel("", style: .footnote, secondary: true)
    private let sendStatus = galleryLabel("", style: .footnote, secondary: true)
    private let authorizationStatus = galleryLabel("", style: .footnote, secondary: true)
    private let environment = galleryLabel("", style: .caption1, secondary: true)
    private let stream = galleryLabel("我会先整理合成资料，再给出简短摘要。")
    private var followsBottom = true
    private var lastSize = CGSize.zero
    private var savedAnchor: (UIView, CGFloat)?
    private var adjustingLayout = false
    private var streamCount = 0
    private var acceptedCount = 0
    private var latestContent: UILabel?
    private weak var authorizationPage: GalleryPage?
    private var presentedAuthorizationID: UUID?
    private var authorizationStatusLabel: UILabel?
    private var allowButton: RhineButton?
    private var denyButton: RhineButton?
    private var confirmButton: RhineButton?
    private var authorizationConnectionLabel: UILabel?
    private var reconnectButton: RhineButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Agent 会话"
        view.backgroundColor = RhineColor.canvas
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "演示", primaryAction: UIAction { [weak self] _ in self?.showDemo() })
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "agent.demo"
        timeline.accessibilityIdentifier = "agent.timeline"
        timeline.keyboardDismissMode = .interactive
        timeline.delegate = self
        composer.accessibilityIdentifier = "agent.composer"
        composer.keyboardDismissMode = .none
        messages.axis = .vertical
        messages.spacing = RhineSpacing.group
        for child in [timeline, composer, latest] { child.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(child) }
        pin(messages, in: timeline)
        let composition = UIStackView(arrangedSubviews: [input, send])
        composition.axis = .vertical
        composition.spacing = RhineSpacing.related
        pin(composition, in: composer)
        let preferredHeight = composer.heightAnchor.constraint(equalTo: composition.heightAnchor, constant: 24)
        preferredHeight.priority = .defaultHigh
        let available = UILayoutGuide()
        view.addLayoutGuide(available)
        NSLayoutConstraint.activate([
            available.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            available.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            timeline.topAnchor.constraint(equalTo: available.topAnchor),
            timeline.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            timeline.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            timeline.bottomAnchor.constraint(equalTo: latest.topAnchor),
            latest.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            latest.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            latest.bottomAnchor.constraint(equalTo: composer.topAnchor),
            composer.leadingAnchor.constraint(equalTo: timeline.leadingAnchor),
            composer.trailingAnchor.constraint(equalTo: timeline.trailingAnchor),
            composer.bottomAnchor.constraint(equalTo: available.bottomAnchor),
            composer.heightAnchor.constraint(lessThanOrEqualTo: available.heightAnchor, multiplier: 0.5),
            preferredHeight
        ])
        input.input.accessibilityIdentifier = "agent.draft"
        input.input.returnKeyType = .done
        input.input.delegate = self
        input.input.textContentType = nil
        input.input.addTarget(self, action: #selector(revealInput), for: .editingDidBegin)
        input.onChange = { [weak self] value in self?.model.draft = value; self?.render() }
        send.accessibilityIdentifier = "agent.send"
        send.onActivate = { [weak self] in
            guard let self, self.model.requestSend() != nil else { return }
            self.render()
        }
        latest.accessibilityIdentifier = "agent.latest"
        latest.onActivate = { [weak self] in
            guard let self else { return }
            self.followsBottom = true
            self.scrollToBottom()
            // Explicit navigation may move accessibility focus; streaming never does.
            UIAccessibility.post(notification: .layoutChanged, argument: self.latestContent)
        }
        for (label, id) in [(connection, "connection"), (run, "run"), (sendStatus, "sendStatus"), (authorizationStatus, "authorizationStatus")] {
            label.accessibilityIdentifier = "agent.\(id)"
        }
        let facts = UIStackView(arrangedSubviews: [
            galleryLabel("合成演示 · 未连接服务", style: .headline),
            connection, run, sendStatus, authorizationStatus, environment
        ])
        facts.axis = .vertical; facts.spacing = RhineSpacing.inline
        environment.accessibilityIdentifier = "agent.environment"
        messages.addArrangedSubview(facts)
        for index in 0..<6 {
            addMessage("示例正文 \(index + 1)", text: "这是一段可公开的合成阅读内容。阅读历史时，新的正文片段不会抢走当前位置。Long messages wrap naturally and keep their reading order.", id: "agent.message.\(index)")
        }
        addMessage("推理摘要 · 辅助内容", text: "先核对资料范围，再整理结果。此处仅演示公开合成摘要，不代表任何模型的内部推理。", secondary: true)
        addMessage("工具事件 · 已完成", text: "读取合成目录 · 返回 3 项示例。工具结果与正文分开，状态不只靠颜色。", secondary: true)
        let response = UIStackView(arrangedSubviews: [galleryLabel("助手正文", style: .headline), stream])
        response.axis = .vertical; response.spacing = RhineSpacing.related
        stream.accessibilityIdentifier = "agent.stream"
        messages.addArrangedSubview(response)
        latestContent = stream
        if ProcessInfo.processInfo.arguments.contains("--agent-dark") { overrideUserInterfaceStyle = .dark }
        if ProcessInfo.processInfo.arguments.contains("--agent-large") {
            traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        }
        NotificationCenter.default.addObserver(self, selector: #selector(background), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(foreground), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateEnvironment), name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitUserInterfaceStyle.self]) {
            (controller: AgentSessionViewController, _: UITraitCollection) in
            controller.updateEnvironment()
        }
        updateEnvironment()
        render()
    }

    private func pin(_ stack: UIStackView, in scroll: UIScrollView) {
        scroll.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false
        let width = stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
        width.priority = .defaultHigh
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -12),
            stack.centerXAnchor.constraint(equalTo: scroll.frameLayoutGuide.centerXAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: 720),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            scroll.contentLayoutGuide.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            width
        ])
    }
    private func addMessage(_ title: String, text: String, id: String? = nil, secondary: Bool = false) {
        let body = galleryLabel(text, style: secondary ? .subheadline : .body, secondary: secondary)
        body.accessibilityIdentifier = id
        let row = UIStackView(arrangedSubviews: [galleryLabel(title, style: .headline, secondary: secondary), body])
        row.axis = .vertical; row.spacing = RhineSpacing.related
        messages.addArrangedSubview(row)
        latestContent = body
    }

    private var bottomOffset: CGFloat {
        max(-timeline.adjustedContentInset.top, timeline.contentSize.height - timeline.bounds.height + timeline.adjustedContentInset.bottom)
    }
    private func readingAnchor() -> (UIView, CGFloat)? {
        let y = timeline.contentOffset.y + timeline.adjustedContentInset.top
        guard let row = messages.arrangedSubviews.first(where: { $0.convert($0.bounds, to: timeline).maxY > y }) else { return nil }
        return (row, row.convert(row.bounds, to: timeline).minY - timeline.contentOffset.y)
    }
    private func restore(_ anchor: (UIView, CGFloat)?) {
        guard let (row, distance) = anchor else { return }
        let y = row.convert(row.bounds, to: timeline).minY - distance
        timeline.setContentOffset(CGPoint(x: 0, y: min(bottomOffset, max(-timeline.adjustedContentInset.top, y))), animated: false)
    }
    private func scrollToBottom() {
        timeline.setContentOffset(CGPoint(x: 0, y: bottomOffset), animated: false)
        savedAnchor = readingAnchor()
    }
    private func preservingReading(_ changes: () -> Void) {
        let anchor = readingAnchor()
        let follow = followsBottom && !timeline.isTracking && !timeline.isDecelerating
        adjustingLayout = true
        changes()
        view.layoutIfNeeded()
        if follow { scrollToBottom() } else { restore(anchor) }
        adjustingLayout = false
        savedAnchor = readingAnchor()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !adjustingLayout else { return }
        adjustingLayout = true
        let viewportChanged = timeline.bounds.size != lastSize
        if viewportChanged {
            if followsBottom { scrollToBottom() } else { restore(savedAnchor) }
            lastSize = timeline.bounds.size
        }
        savedAnchor = readingAnchor()
        adjustingLayout = false
        if viewportChanged && input.input.isFirstResponder { revealInput() }
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView === timeline { followsBottom = false }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === timeline && !adjustingLayout { savedAnchor = readingAnchor() }
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { resumeFollowingIfAtBottom(scrollView) }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { resumeFollowingIfAtBottom(scrollView) }
    private func resumeFollowingIfAtBottom(_ scroll: UIScrollView) {
        if scroll === timeline { followsBottom = abs(bottomOffset - timeline.contentOffset.y) < 24 }
    }
    @objc private func revealInput() {
        composer.scrollRectToVisible(input.input.convert(input.input.bounds, to: composer).insetBy(dx: 0, dy: -8), animated: false)
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { textField.resignFirstResponder(); return true }

    private func render() {
        guard isViewLoaded else { return }
        preservingReading {
            connection.text = "连接：\(model.connection == .connected ? "已连接（合成）" : model.connection == .connecting ? "连接中 · 等待同步" : "离线")"
            let runText: String
            switch model.run {
            case .idle: runText = "未运行"
            case .running: runText = "运行中"
            case .stopRequested: runText = model.stopRequestAccepted ? "停止请求已接收 · 等待停止" : "停止请求待确认"
            case .stopped: runText = "任务已停止"
            }
            run.text = "运行：\(runText)"
            let sendText: String
            switch model.send {
            case .idle: sendText = "未发送"
            case .awaitingAcceptance: sendText = "等待接受 · 草稿保留"
            case .unknown: sendText = "结果未知 · 草稿保留，不自动重发"
            case .accepted: sendText = "已接受"
            case .rejected: sendText = "已拒绝 · 草稿保留，可手动重试"
            }
            sendStatus.text = "发送：\(sendText)"
            authorizationStatus.text = "授权：\(authorizationText)"
        }
        if input.text != model.draft && input.input.markedTextRange == nil { input.text = model.draft }
        // This recipe freezes the submitted draft. The model also protects later draft revisions.
        input.isEnabled = model.send != .awaitingAcceptance && model.send != .unknown
        send.isEnabled = model.canSend && input.input.markedTextRange == nil
        send.accessibilityHint = sendStatus.text
        authorizationStatusLabel?.text = authorizationText
        let pending = model.authorization?.status == .pending
        allowButton?.isEnabled = pending && model.connection == .connected
        denyButton?.isEnabled = pending && model.connection == .connected
        confirmButton?.isEnabled = model.authorization?.status == .decisionPending
        authorizationConnectionLabel?.text = connection.text
        reconnectButton?.isEnabled = model.connection != .connected && !model.isInBackground
        reconcileAuthorization()
    }
    private var authorizationText: String {
        guard let request = model.authorization else { return "无待处理请求" }
        switch request.status {
        case .pending: return "等待选择"
        case .decisionPending: return "选择已提交 · 等待确认"
        case .allowedOnce: return "已确认允许一次"
        case .denied: return "已确认拒绝"
        case .withdrawn: return "请求已撤回"
        }
    }
    @objc private func background() { model.enterBackground(); render() }
    @objc private func updateEnvironment() {
        let style = traitCollection.userInterfaceStyle == .dark ? "深色" : "浅色"
        let size = traitCollection.preferredContentSizeCategory == .accessibilityExtraExtraExtraLarge ? "最大辅助字号" : "系统字号"
        preservingReading {
            environment.text = "\(style) · \(size) · 减少动态：\(UIAccessibility.isReduceMotionEnabled ? "开启" : "关闭")"
        }
    }
    @objc private func foreground() {
        guard model.isInBackground else { return }
        model.enterForeground(); render()
    }
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); reconcileAuthorization() }
    deinit { NotificationCenter.default.removeObserver(self) }

    private func showDemo() {
        let page = GalleryPage()
        page.title = "合成演示控制"
        page.loadViewIfNeeded()
        page.intro("SYNTHETIC", "手动推进事件", "没有网络请求。每一步只改变这个页面的合成宿主状态。")
        func action(_ title: String, _ id: String, _ work: @escaping @MainActor () -> Void) {
            let button = RhineButton(title, style: .secondary) { [weak self, weak page] in
                page?.dismiss(animated: false) { work(); self?.render() }
            }
            button.accessibilityIdentifier = "action.\(id)"
            page.content.addArrangedSubview(button)
        }
        action("追加流式片段", "stream") { [weak self] in
            guard let self else { return }
            self.preservingReading {
                self.streamCount += 1
                self.stream.text = (self.stream.text ?? "") + "\n片段 \(self.streamCount)：正文逐步到达，阅读位置保持连续。"
            }
        }
        action("模拟离线", "disconnect") { [weak self] in self?.model.disconnect() }
        action("开始重连", "reconnect") { [weak self] in self?.model.enterBackground(); self?.model.enterForeground() }
        action("同步连接完成", "connected") { [weak self] in self?.model.completeReconnect() }
        action("宿主确认发送接受", "accept") { [weak self] in self?.resolveSend(accepted: true) }
        action("宿主确认发送拒绝", "reject") { [weak self] in self?.resolveSend(accepted: false) }
        action("开始运行", "start") { [weak self] in _ = self?.model.startRun() }
        action("请求停止", "stop") { [weak self] in _ = self?.model.requestStop() }
        action("宿主接收停止请求", "stopAccepted") { [weak self] in
            guard let self, let id = self.model.runID else { return }
            self.model.acknowledgeStopRequest(id: id)
        }
        action("宿主确认已停止", "stopped") { [weak self] in
            guard let self, let id = self.model.runID else { return }
            self.model.finishRun(id: id)
        }
        action("收到一次性授权", "authorization") { [weak self] in self?.receiveAuthorization() }
        action("其他弹窗遮挡", "blocker") { [weak self] in self?.showBlocker() }
        page.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完成", primaryAction: UIAction { [weak self, weak page] _ in
            page?.dismiss(animated: false) { self?.reconcileAuthorization() }
        })
        present(UINavigationController(rootViewController: page), animated: false)
    }
    private func resolveSend(accepted: Bool) {
        guard let id = model.submission?.id else { return }
        if let text = model.resolveSend(id: id, accepted: accepted) {
            preservingReading {
                acceptedCount += 1
                addMessage("你 · 已接受", text: text, id: "agent.accepted.\(acceptedCount)")
            }
        }
    }
    private func receiveAuthorization() {
        _ = model.receiveAuthorization(id: UUID(), context: "示例会话 · 示例任务\n操作：读取合成目录\n范围：仅这一次读取，不授予后续操作权限。\n没有访问真实文件、网络或主机。")
    }
    private func showBlocker() {
        let page = GalleryPage()
        page.title = "其他弹窗"
        page.loadViewIfNeeded()
        page.intro("SYNTHETIC", "暂时遮挡授权", "请求保存在宿主模型中。关闭后重新核对，已撤回的请求不会出现。")
        let state = galleryLabel(authorizationText)
        state.accessibilityIdentifier = "blocker.status"
        page.content.addArrangedSubview(state)
        let receive = RhineButton("遮挡期间收到请求", style: .secondary) { [weak self, weak state] in
            self?.receiveAuthorization(); self?.render(); state?.text = self?.authorizationText
        }
        receive.accessibilityIdentifier = "blocker.receive"
        let withdraw = RhineButton("遮挡期间撤回", style: .secondary) { [weak self, weak state] in
            guard let self, let id = self.model.authorization?.id else { return }
            self.model.withdrawAuthorization(id: id); self.render(); state?.text = self.authorizationText
        }
        withdraw.accessibilityIdentifier = "blocker.withdraw"
        let done = RhineButton("关闭其他弹窗") { [weak self, weak page] in
            page?.dismiss(animated: false) { self?.reconcileAuthorization() }
        }
        done.accessibilityIdentifier = "blocker.done"
        [receive, withdraw, done].forEach { page.content.addArrangedSubview($0) }
        let navigation = UINavigationController(rootViewController: page)
        navigation.isModalInPresentation = true
        present(navigation, animated: false)
    }
    private func reconcileAuthorization() {
        guard viewIfLoaded?.window != nil else { return }
        let request = model.authorization
        let active = request?.status == .pending || request?.status == .decisionPending
        if let page = authorizationPage,
           !active || presentedAuthorizationID != request?.id {
            page.dismiss(animated: false) { [weak self] in
                guard let self else { return }
                self.authorizationPage = nil
                self.presentedAuthorizationID = nil
                UIAccessibility.post(notification: .screenChanged, argument: self.authorizationStatus)
                self.reconcileAuthorization()
            }
            return
        }
        guard active, let request, !model.isInBackground, presentedViewController == nil,
              navigationController?.topViewController === self else { return }
        let page = GalleryPage()
        page.title = "一次性授权"
        page.loadViewIfNeeded()
        page.intro("SYNTHETIC", "核对这次操作", request.context)
        let status = galleryLabel(authorizationText)
        status.accessibilityIdentifier = "auth.status"
        page.content.addArrangedSubview(status)
        authorizationStatusLabel = status
        let connectionStatus = galleryLabel(connection.text ?? "", style: .footnote, secondary: true)
        connectionStatus.accessibilityIdentifier = "auth.connection"
        page.content.addArrangedSubview(connectionStatus)
        authorizationConnectionLabel = connectionStatus
        let allow = RhineButton("允许一次") { [weak self] in
            _ = self?.model.decideAuthorization(id: request.id, decision: .allowOnce); self?.render()
        }
        let deny = RhineButton("拒绝", style: .secondary) { [weak self] in
            _ = self?.model.decideAuthorization(id: request.id, decision: .deny); self?.render()
        }
        let confirm = RhineButton("模拟宿主确认", style: .plain) { [weak self] in
            guard let self, let decisionID = self.model.authorization?.decisionID else { return }
            _ = self.model.resolveAuthorization(id: request.id, decisionID: decisionID, accepted: true)
            self.render()
        }
        let withdraw = RhineButton("模拟请求撤回", style: .plain) { [weak self] in
            _ = self?.model.withdrawAuthorization(id: request.id); self?.render()
        }
        let reconnect = RhineButton("模拟连接同步完成", style: .plain) { [weak self] in
            self?.model.completeReconnect(); self?.render()
        }
        reconnectButton = reconnect
        reconnect.isEnabled = model.connection != .connected && !model.isInBackground
        for (button, id) in [(allow, "allow"), (deny, "deny"), (confirm, "confirm"), (withdraw, "withdraw"), (reconnect, "reconnect")] {
            button.accessibilityIdentifier = "auth.\(id)"; page.content.addArrangedSubview(button)
        }
        allowButton = allow; denyButton = deny; confirmButton = confirm
        allow.isEnabled = request.status == .pending && model.connection == .connected
        deny.isEnabled = allow.isEnabled
        confirm.isEnabled = request.status == .decisionPending
        authorizationPage = page
        presentedAuthorizationID = request.id
        let navigation = UINavigationController(rootViewController: page)
        navigation.isModalInPresentation = true
        present(navigation, animated: false)
    }
}
