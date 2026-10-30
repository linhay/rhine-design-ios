import XCTest
import UIKit

@MainActor
final class GalleryInteractionTests: XCTestCase {
    private func launch(tab: Int = 0, large: Bool = false, category: UIContentSizeCategory? = nil) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        let category = category ?? (large ? .accessibilityExtraExtraExtraLarge : .large)
        app.launchArguments = ["--gallery-tab=\(tab)", "-UIPreferredContentSizeCategoryName", category.rawValue]
        app.launch()
        XCTAssertTrue(app.scrollViews["gallery.scroll"].waitForExistence(timeout: 30))
        return app
    }
    private func reach(_ element: XCUIElement, in app: XCUIApplication) {
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<30 {
            // A moved iPad window may report the scroll and child in different spaces.
            // Trust native hit testing before comparing their frames.
            if element.isHittable { return }
            let viewport = scroll.frame
            var target = element.frame
            let window = app.windows.firstMatch.frame
            let movedWindow = window.minX != 0 || window.minY != 0
            if movedWindow,
               abs(target.midX + window.minX - scroll.frame.midX) < abs(target.midX - scroll.frame.midX) {
                target = target.offsetBy(dx: window.minX, dy: window.minY)
            }
            // A large swipe can pass a target in short iPad windows. Move back toward it.
            if movedWindow && abs(target.midY - viewport.midY) < viewport.height * 1.5 {
                let towardTop = target.midY < viewport.midY
                let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: towardTop ? 0.35 : 0.65))
                let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: towardTop ? 0.65 : 0.35))
                start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
            } else if target.midY < viewport.minY + 16 {
                scroll.swipeDown(velocity: .slow)
            } else if target.midY > viewport.maxY - 16 {
                scroll.swipeUp(velocity: .slow)
            } else {
                scroll.swipeUp(velocity: .slow)
            }
        }
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "unreachable-\(element.identifier)"; hierarchy.lifetime = .keepAlways; add(hierarchy)
        XCTFail("Could not reach \(element.identifier)")
    }
    private func tapKeyboardReturn(in app: XCUIApplication, titles: [String]) {
        let key = app.keyboards.descendants(matching: .any).matching(NSPredicate(format: "identifier IN %@ OR label IN %@", titles, titles)).firstMatch
        XCTAssertTrue(key.waitForExistence(timeout: 5))
        key.tap()
    }
    private func assertSoftwareKeyboard(in app: XCUIApplication, field: XCUIElement) {
        let letter = app.keyboards.keys["q"].firstMatch
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND hittable == true"), object: letter)
        XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 5), .completed)
        XCTAssertTrue(field.isHittable, "The focused field must remain reachable above the software keyboard")
    }
    private func selectTab(_ title: String, in app: XCUIApplication) {
        // Regular-width iPad presents native floating tabs as cells, not a TabBar.
        let tab = app.descendants(matching: .any).matching(identifier: title).firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(data: XCUIScreen.main.screenshot().pngRepresentation, uniformTypeIdentifier: "public.png")
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testGalleryNavigationAndPreview() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["让界面自然生长"].exists)
        capture("gallery-overview")
        app.buttons["预览"].tap()
        XCTAssertTrue(app.staticTexts["换个视角"].waitForExistence(timeout: 5))
        app.segmentedControls.buttons["深色"].tap()
        app.buttons["恢复跟随系统"].tap()
        app.navigationBars.buttons["完成"].tap()
        selectTab("按钮", in: app)
        XCTAssertTrue(app.staticTexts["每个动作，都有回应"].exists)
    }
    func testTaskLoadingFailureAndRetry() {
        let app = launch(tab: 1)
        let start = app.buttons["button.start"]
        reach(start, in: app); start.tap()
        XCTAssertFalse(start.isEnabled)
        XCTAssertEqual(app.staticTexts["button.count"].label, "激活次数：1")
        let fail = app.buttons["模拟失败"]
        reach(fail, in: app); capture("gallery-buttons-busy"); fail.tap()
        XCTAssertTrue(start.isEnabled)
        start.tap()
        XCTAssertEqual(app.staticTexts["button.count"].label, "激活次数：2")
        app.buttons["模拟成功"].tap()
        XCTAssertEqual(app.staticTexts["button.result"].label, "已完成 · 可以再次开始")
        capture("gallery-buttons-success")
    }
    func testFormValidationFailureRetentionAndSuccessfulSave() {
        let app = launch(tab: 2)
        let open = app.buttons["form.open"]; reach(open, in: app); open.tap()
        XCTAssertTrue(app.navigationBars.buttons["form.save"].waitForExistence(timeout: 5))
        app.buttons["清空必填"].tap()
        app.navigationBars.buttons["form.save"].tap()
        XCTAssertTrue(app.staticTexts["错误：请填写显示名称。"].exists)
        app.navigationBars.buttons["取消"].tap()
        XCTAssertTrue(app.alerts["放弃未保存的修改？"].waitForExistence(timeout: 5))
        app.alerts.buttons["继续编辑"].tap()
        // Scroll back to the deterministic sample-fill control after validation focuses a field.
        for _ in 0..<12 {
            if app.buttons["填入有效示例"].isHittable { break }
            app.scrollViews.firstMatch.swipeDown()
        }
        app.buttons["填入有效示例"].tap()
        app.navigationBars.buttons["form.save"].tap()
        XCTAssertFalse(app.navigationBars.buttons["取消"].isEnabled)
        XCTAssertTrue(app.buttons["模拟保存失败"].waitForExistence(timeout: 5))
        app.buttons["模拟保存失败"].tap()
        XCTAssertTrue(app.staticTexts["form.feedback"].label.contains("草稿已保留"))
        XCTAssertEqual(app.textFields["form.field.0"].value as? String, "示例访客")
        capture("gallery-form-failure")
        app.navigationBars.buttons["form.save"].tap()
        app.buttons["模拟保存成功"].tap()
        XCTAssertTrue(app.buttons["form.open"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["form.summary"].label.contains("hello@example.com"))
    }
    func testDiscardDoesNotChangeSavedProfile() {
        let app = launch(tab: 2)
        let before = app.staticTexts["form.summary"].label
        reach(app.buttons["form.open"], in: app); app.buttons["form.open"].tap()
        app.buttons["清空必填"].tap()
        app.navigationBars.buttons["取消"].tap()
        app.alerts.buttons["放弃修改"].tap()
        XCTAssertTrue(app.buttons["form.open"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["form.summary"].label, before)
    }
    func testLargestTextLandscapeDraftContinueAndDiscard() {
        let original = XCUIDevice.shared.orientation
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = original }
        let app = launch(tab: 2, large: true)
        XCTAssertGreaterThan(app.windows.firstMatch.frame.width, app.windows.firstMatch.frame.height)
        let before = app.staticTexts["form.summary"].label
        reach(app.buttons["form.open"], in: app); app.buttons["form.open"].tap()
        reach(app.buttons["清空必填"], in: app); app.buttons["清空必填"].tap()
        app.navigationBars.buttons["取消"].tap()
        let confirmation = app.alerts["放弃未保存的修改？"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        XCTAssertTrue(confirmation.buttons["继续编辑"].isHittable)
        XCTAssertTrue(confirmation.buttons["放弃修改"].isHittable)
        capture("landscape-largest-draft-confirmation")
        confirmation.buttons["继续编辑"].tap()
        XCTAssertTrue(confirmation.waitForNonExistence(timeout: 5))
        XCTAssertEqual(app.textFields["form.field.0"].value as? String, "")
        XCTAssertEqual(app.textFields["form.field.1"].value as? String, "")
        app.navigationBars.buttons["取消"].tap()
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["放弃修改"].tap()
        XCTAssertTrue(app.buttons["form.open"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["form.summary"].label, before)
        capture("landscape-largest-draft-discarded")
    }

    func testEmptyAndSearchActionsRestoreContent() {
        let app = launch(tab: 3)
        let add = app.buttons["添加示例收藏"]
        reach(add, in: app); capture("gallery-empty"); add.tap()
        XCTAssertTrue(app.staticTexts["一份新的收藏"].exists)
        app.buttons["移除示例收藏"].tap()
        XCTAssertTrue(app.staticTexts["收藏从这里开始"].exists)
        for _ in 0..<8 { if app.buttons["展示状态"].isHittable { break }; app.scrollViews.firstMatch.swipeDown() }
        app.buttons["展示状态"].tap()
        app.buttons["无匹配结果"].tap()
        reach(app.buttons["清除筛选"], in: app); app.buttons["清除筛选"].tap()
        XCTAssertTrue(app.staticTexts["一份新的收藏"].exists)
    }
    func testKeyboardToggleAndChoiceSaveRealEdits() {
        let app = launch(tab: 2)
        reach(app.buttons["form.open"], in: app); app.buttons["form.open"].tap()
        let name = app.textFields["form.field.0"]
        reach(name, in: app); name.tap(); name.typeText(" UI")
        let keyboardVisible = app.keyboards.firstMatch.waitForExistence(timeout: 5)
        assertSoftwareKeyboard(in: app, field: name)
        capture("gallery-form-active-keyboard")
        if !keyboardVisible {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "keyboard-missing-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
        }
        XCTAssertTrue(keyboardVisible)
        // Tap the actual software return key, then type through the app to prove focus moved.
        tapKeyboardReturn(in: app, titles: ["Next:", "下一项", "Next", "next"])
        app.typeText("x")
        XCTAssertEqual(app.textFields["form.field.1"].value as? String, "hello@example.comx")
        tapKeyboardReturn(in: app, titles: ["Next:", "下一项", "Next", "next"])
        app.typeText("/demo")
        XCTAssertEqual(app.textFields["form.field.2"].value as? String, "https://example.com/demo")
        tapKeyboardReturn(in: app, titles: ["Next:", "下一项", "Next", "next"])
        app.typeText("demo-only")
        let secure = app.secureTextFields["form.field.3"]
        XCTAssertFalse((secure.value as? String ?? "").isEmpty)
        assertSoftwareKeyboard(in: app, field: secure)
        capture("gallery-form-password-keyboard")
        tapKeyboardReturn(in: app, titles: ["Done", "完成", "done", "Done:"])
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
        let toggle = app.switches["接收演示提醒"]
        reach(toggle, in: app); toggle.tap()
        let frequency = app.buttons["提醒频率"]
        reach(frequency, in: app); frequency.tap(); app.buttons["每日摘要"].tap()
        app.navigationBars.buttons["取消"].tap()
        XCTAssertTrue(app.alerts["放弃未保存的修改？"].waitForExistence(timeout: 5))
        app.alerts.buttons["继续编辑"].tap()
        app.navigationBars.buttons["form.save"].tap()
        app.buttons["模拟保存成功"].tap()
        XCTAssertTrue(app.buttons["form.open"].waitForExistence(timeout: 5))
        let summary = app.staticTexts["form.summary"].label
        XCTAssertTrue(summary.contains(" UI"))
        XCTAssertTrue(summary.contains("关闭"))
        XCTAssertTrue(summary.contains("每日摘要"))
        app.buttons["form.open"].tap()
        let password = app.secureTextFields["form.field.3"]
        reach(password, in: app)
        XCTAssertEqual(password.value as? String, "")
        capture("gallery-form-keyboard-and-selection")
    }
    func testFailureLoadingAndPermissionHaveDistinctRecoveryActions() {
        let app = launch(tab: 3)
        func choose(_ label: String) {
            for _ in 0..<15 {
                if app.buttons["展示状态"].isHittable { break }
                app.scrollViews.firstMatch.swipeDown(velocity: .slow)
            }
            app.buttons["展示状态"].tap(); app.buttons[label].tap()
        }
        choose("加载失败")
        reach(app.buttons["重新加载"], in: app)
        XCTAssertTrue(app.staticTexts["暂时无法加载"].exists)
        app.buttons["重新加载"].tap()
        XCTAssertTrue(app.staticTexts["正在加载示例内容…"].exists)
        reach(app.buttons["返回内容"], in: app); app.buttons["返回内容"].tap()
        XCTAssertTrue(app.staticTexts["一份新的收藏"].exists)
        choose("权限未开启")
        reach(app.buttons["演示授权后效果"], in: app)
        XCTAssertTrue(app.staticTexts["尚未开启访问权限"].exists)
        capture("gallery-permission-recovery")
        app.buttons["演示授权后效果"].tap()
        XCTAssertTrue(app.staticTexts["一份新的收藏"].exists)
    }
    func testLargestTextCanReachLongButtonAndStateAction() {
        let app = launch(tab: 1, large: true)
        let long = app.buttons["保存全部更改并返回这份长标题的示例文档"]
        reach(long, in: app)
        capture("gallery-buttons-accessibility")
        long.tap()
        selectTab("状态", in: app)
        reach(app.buttons["添加示例收藏"], in: app)
        capture("gallery-empty-accessibility")
        app.buttons["添加示例收藏"].tap()
        XCTAssertTrue(app.staticTexts["一份新的收藏"].exists)
    }

    func testLargerTextKeepsLowerFieldAboveSoftwareKeyboard() {
        for category in [UIContentSizeCategory.extraExtraExtraLarge, .accessibilityExtraLarge, .accessibilityExtraExtraExtraLarge] {
            let app = launch(category: category)
            reach(app.buttons["查看基础环境"], in: app)
            app.buttons["查看基础环境"].tap()
            XCTAssertEqual(app.staticTexts["environment.Dynamic Type"].label, category.rawValue)
            // Duo may place native navigation in a side toolbar.
            let toolbarBack = app.buttons["BackButton"]
            if toolbarBack.exists { toolbarBack.tap() }
            else { app.navigationBars.buttons.element(boundBy: 0).tap() }
            selectTab("表单", in: app)
            reach(app.buttons["form.open"], in: app); app.buttons["form.open"].tap()
            let url = app.textFields["form.field.2"]
            reach(url, in: app); url.tap(); app.typeText("/large")
            // A tap chooses a native insertion position; it need not be the end.
            let edited = url.value as? String ?? ""
            XCTAssertTrue(edited.contains("/large"))
            XCTAssertEqual(edited.replacingOccurrences(of: "/large", with: ""), "https://example.com")
            assertSoftwareKeyboard(in: app, field: url)
            XCTAssertTrue(app.navigationBars.buttons["form.save"].isHittable)
            capture("gallery-lower-field-keyboard-\(category.rawValue)")
            app.navigationBars.buttons["取消"].tap()
            app.alerts.buttons["放弃修改"].tap()
            XCTAssertTrue(app.buttons["form.open"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    func testLargestTextActionsAfterRotation() {
        let original = XCUIDevice.shared.orientation
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = original }
        let app = launch(tab: 1, large: true)
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let window = app.windows.firstMatch
            let changed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                let frame = window.frame
                return orientation == .portrait ? frame.height > frame.width : frame.width > frame.height
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 10), .completed)
            let long = app.buttons["保存全部更改并返回这份长标题的示例文档"]
            reach(long, in: app); long.tap()
            capture("gallery-largest-rotation-\(Int(window.frame.width))x\(Int(window.frame.height))")
        }
    }

    func testDarkNarrowPreviewKeepsLargeActionsReachable() {
        let app = launch(tab: 1)
        app.buttons["预览"].tap()
        app.segmentedControls.buttons["深色"].tap()
        let narrow = app.switches["窄内容预览"]
        reach(narrow, in: app); narrow.tap()
        // Apply the largest size after the preview controls have been reached.
        reach(app.buttons["文字大小"], in: app)
        app.buttons["文字大小"].tap(); app.buttons["最大辅助字号"].tap()
        app.navigationBars.buttons["完成"].tap()
        let long = app.buttons["保存全部更改并返回这份长标题的示例文档"]
        reach(long, in: app)
        XCTAssertLessThanOrEqual(long.frame.width, 288.5)
        XCTAssertGreaterThan(long.frame.width, 0)
        long.tap()
        capture("gallery-dark-320pt-largest-button")
        selectTab("状态", in: app)
        let action = app.buttons["添加示例收藏"]
        reach(action, in: app); action.tap()
        XCTAssertTrue(app.staticTexts["一份新的收藏"].exists)
        capture("gallery-dark-320pt-largest-state")
    }
}


/// Opt-in tests mutate a reserved iPad's real system window, never a content preview.
@MainActor
final class GalleryMinimumWindowTests: XCTestCase {
    private func launchMinimum() throws -> XCUIApplication {
        guard ProcessInfo.processInfo.environment["RHINE_WINDOW_RESIZE"] == "1",
              UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Requires a reserved iPad with system windowing enabled")
        }
        continueAfterFailure = false
        executionTimeAllowance = 360
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--foundation-diagnostics"]
        app.launch()
        let size = app.staticTexts["environment.Dynamic Type"]
        XCTAssertTrue(size.waitForExistence(timeout: 20))
        XCTAssertEqual(size.label, UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue)
        XCTAssertEqual(app.staticTexts["environment.Appearance"].label, "Dark")
        XCTAssertEqual(app.staticTexts["environment.Contrast"].label, "Increased")
        XCTAssertEqual(app.staticTexts["environment.Reduce Motion"].label, "On")
        XCTAssertEqual(app.staticTexts["environment.Reduce Transparency"].label, "On")
        capture("minimum-system-readback", app: app, includeHierarchy: true)
        app.terminate()
        app.launchArguments = ["--gallery-tab=2"]
        app.launch()
        XCTAssertTrue(app.scrollViews["gallery.scroll"].waitForExistence(timeout: 20))
        func shrink() {
            let frame = app.windows.firstMatch.frame
            screenPoint(frame.maxX - 10, frame.maxY - 10).press(forDuration: 0.5,
                thenDragTo: screenPoint(frame.minX + 150, frame.minY + 260),
                withVelocity: .slow, thenHoldForDuration: 0.5)
        }
        shrink()
        let minimum = app.windows.firstMatch.frame
        XCTAssertLessThanOrEqual(minimum.width, 400)
        XCTAssertLessThanOrEqual(minimum.height, 500)
        shrink()
        let clamped = app.windows.firstMatch.frame
        XCTAssertEqual(clamped.width, minimum.width, accuracy: 1)
        XCTAssertEqual(clamped.height, minimum.height, accuracy: 1)
        capture("minimum-window-clamped", app: app, includeHierarchy: true)
        return app
    }
    private func screenPoint(_ x: CGFloat, _ y: CGFloat) -> XCUICoordinate {
        XCUIApplication(bundleIdentifier: "com.apple.springboard")
            .coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y))
    }

    // Offscreen descendants in this system window may report window-local
    // coordinates, while their scroll view reports screen coordinates. Normalize
    // only that observed origin mismatch; visible controls stay in screen space.
    private func windowRect(_ element: XCUIElement, app: XCUIApplication) -> CGRect {
        let frame = element.frame
        let window = app.windows.firstMatch.frame
        if window.minX > 0 && frame.minX < window.minX - 1 {
            return frame.offsetBy(dx: window.minX, dy: window.minY)
        }
        return frame
    }

    private func windowDrag(_ scroll: XCUIElement, app: XCUIApplication, upward: Bool, distance: CGFloat) {
        let frame = usableViewport(scroll, app: app)
        let travel = min(frame.height * 0.55, max(24, distance))
        let y = frame.minY + frame.height * (upward ? 0.8 : 0.2)
        // Keep both endpoints clear of the system window’s rounded corners.
        screenPoint(frame.midX, y).press(forDuration: 0.01,
            thenDragTo: screenPoint(frame.midX, y + (upward ? -travel : travel)),
            withVelocity: .slow, thenHoldForDuration: 0.1)
    }

    private func windowReach(_ element: XCUIElement, in scroll: XCUIElement, app: XCUIApplication) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        for _ in 0..<24 {
            let viewport = usableViewport(scroll, app: app)
            let rect = windowRect(element, app: app)
            if element.isHittable && isFullyVisible(rect, in: viewport) { return }
            XCTAssertLessThanOrEqual(rect.height, viewport.height + 1)
            let upward = rect.maxY > viewport.maxY
            windowDrag(scroll, app: app, upward: upward,
                       distance: (upward ? rect.maxY - viewport.maxY : viewport.minY - rect.minY) + 16)
        }
        capture("minimum-window-unreachable", app: app, elements: [scroll, element], includeHierarchy: true)
        XCTFail("Entire control must be visible and hittable within the actual window")
    }

    private func windowTap(_ element: XCUIElement, app: XCUIApplication) {
        let rect = windowRect(element, app: app)
        screenPoint(rect.midX, rect.midY).tap()
    }

    private func windowRead(_ element: XCUIElement, in scroll: XCUIElement, app: XCUIApplication, name: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        for _ in 0..<64 {
            let viewport = usableViewport(scroll, app: app)
            let rect = windowRect(element, app: app)
            if rect.minY >= viewport.minY - 1 && rect.minY < viewport.maxY - 50 { break }
            let upward = rect.minY >= viewport.maxY - 50
            windowDrag(scroll, app: app, upward: upward,
                       distance: abs(rect.minY - viewport.minY) + 16)
        }
        let top = usableViewport(scroll, app: app)
        let rect = windowRect(element, app: app)
        capture(name + "-top-position", app: app, elements: [scroll, element], includeHittability: false)
        XCTAssertGreaterThanOrEqual(rect.minY, top.minY - 1)
        XCTAssertLessThan(rect.minY, top.maxY - 50)
        XCTAssertGreaterThanOrEqual(rect.minX, top.minX - 1)
        XCTAssertLessThanOrEqual(rect.maxX, top.maxX + 1)
        capture(name + "-start", app: app, elements: [scroll, element], includeHittability: false)
        for index in 0..<32 {
            let viewport = usableViewport(scroll, app: app)
            let current = windowRect(element, app: app)
            if current.maxY <= viewport.maxY && current.maxY >= viewport.minY + 40 { break }
            windowDrag(scroll, app: app, upward: current.maxY > viewport.maxY,
                       distance: min(viewport.height * 0.45, abs(current.maxY - viewport.maxY) + 8))
            capture(name + "-slice-\(index)", app: app, elements: [scroll, element], includeHittability: false)
        }
        let bottom = usableViewport(scroll, app: app)
        XCTAssertLessThanOrEqual(windowRect(element, app: app).maxY, bottom.maxY)
        XCTAssertGreaterThanOrEqual(windowRect(element, app: app).maxY, bottom.minY + 40)
        capture(name + "-end", app: app, elements: [scroll, element], includeHittability: false)
    }

    private func capture(_ name: String, app: XCUIApplication, elements: [XCUIElement] = [],
                         includeHierarchy: Bool = false, includeHittability: Bool = true) {
        var details = ["Launch arguments: \(app.launchArguments)", "Window: \(app.windows.firstMatch.frame)"]
        let environment = app.staticTexts["environment.Dynamic Type"]
        details.append(environment.exists ? "Environment: \(environment.label)" : "Main environment hidden by current modal; see launch attachment")
        if app.keyboards.firstMatch.exists { details.append("Keyboard: \(app.keyboards.firstMatch.frame)") }
        details += elements.enumerated().map { index, element in
            element.exists
                ? "\(element.identifier): \(element.frame), hittable=\(includeHittability ? String(element.isHittable) : "not queried for reading-only content"), enabled=\(element.isEnabled)"
                : "Element[\(index)] does not exist in the accessibility hierarchy"
        }
        let geometry = XCTAttachment(string: details.joined(separator: "\n"))
        geometry.name = name + "-geometry"; geometry.lifetime = .keepAlways; add(geometry)
        for (suffix, screenshot) in [("app", app.screenshot()), ("display", XCUIScreen.main.screenshot())] {
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name + "-" + suffix; attachment.lifetime = .keepAlways; add(attachment)
        }
        if includeHierarchy {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = name + "-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
        }
    }

    private func usableViewport(_ scroll: XCUIElement, app: XCUIApplication) -> CGRect {
        var frame = scroll.frame.intersection(app.windows.firstMatch.frame)
        if app.keyboards.firstMatch.exists && app.keyboards.firstMatch.frame.height > 0 {
            frame.size.height = max(0, min(frame.maxY, app.keyboards.firstMatch.frame.minY) - frame.minY)
        }
        return frame
    }

    private func isFullyVisible(_ target: CGRect, in viewport: CGRect) -> Bool {
        target.width > 0 && target.height > 0 &&
        target.minX >= viewport.minX - 1 && target.maxX <= viewport.maxX + 1 &&
        target.minY >= viewport.minY - 1 && target.maxY <= viewport.maxY + 1
    }


    func testMinimumWindowLongErrorReading() throws {
        let app = try launchMinimum()
        let error = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "错误提示可以很长")).firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertTrue(error.label.hasSuffix("窄窗口下也应完整换行。"))
        windowRead(error, in: app.scrollViews["gallery.scroll"].firstMatch, app: app, name: "minimum-gallery-long-error")
    }

    func testMinimumWindowSaveFailureRetentionAndRetry() throws {
        let app = try launchMinimum()
        let scroll = app.scrollViews["gallery.scroll"].firstMatch
        let open = app.buttons["form.open"]
        windowReach(open, in: scroll, app: app); windowTap(open, app: app)
        let save = app.navigationBars.buttons["form.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        let editor = app.scrollViews["gallery.scroll"].firstMatch
        let fill = app.buttons["填入有效示例"]
        windowReach(fill, in: editor, app: app); windowTap(fill, app: app)
        XCTAssertTrue(save.isHittable)
        XCTAssertTrue(isFullyVisible(windowRect(save, app: app), in: app.windows.firstMatch.frame))
        save.tap()
        XCTAssertFalse(save.isEnabled)
        XCTAssertFalse(app.navigationBars.buttons["取消"].isEnabled)
        let failure = app.buttons["模拟保存失败"]
        windowReach(failure, in: editor, app: app)
        capture("minimum-save-failure-action", app: app, elements: [editor, failure])
        windowTap(failure, app: app)
        XCTAssertTrue(app.staticTexts["form.feedback"].label.contains("草稿已保留"))
        XCTAssertEqual(app.textFields["form.field.0"].value as? String, "示例访客")
        XCTAssertEqual(app.textFields["form.field.1"].value as? String, "hello@example.com")
        windowRead(app.staticTexts["form.feedback"], in: editor, app: app, name: "minimum-retained-feedback")
        XCTAssertTrue(save.isEnabled)
        save.tap()
        let success = app.buttons["模拟保存成功"]
        windowReach(success, in: editor, app: app)
        capture("minimum-retry-success-action", app: app, elements: [editor, success])
        windowTap(success, app: app)
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["form.summary"].label.contains("hello@example.com"))
        capture("minimum-retry-saved", app: app, includeHierarchy: true)
    }
}
