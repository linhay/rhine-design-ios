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
