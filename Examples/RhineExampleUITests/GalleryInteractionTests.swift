import XCTest

@MainActor
final class GalleryInteractionTests: XCTestCase {
    private func launch(tab: Int = 0, large: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--gallery-tab=\(tab)", "-UIPreferredContentSizeCategoryName", large ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        app.launch()
        XCTAssertTrue(app.scrollViews["gallery.scroll"].waitForExistence(timeout: 30))
        return app
    }
    private func reach(_ element: XCUIElement, in app: XCUIApplication) {
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<30 {
            let viewport = scroll.frame
            let target = element.frame
            // A large swipe can pass a target in short iPad windows. Move back toward it.
            if target.midY < viewport.minY + 16 {
                scroll.swipeDown(velocity: .slow)
            } else if target.midY > viewport.maxY - 16 {
                scroll.swipeUp(velocity: .slow)
            } else if element.isHittable {
                return
            } else {
                scroll.swipeUp(velocity: .slow)
            }
        }
        XCTFail("Could not reach \(element.identifier)")
    }
    private func selectTab(_ title: String, in app: XCUIApplication) {
        // Regular-width iPad presents native floating tabs as cells, not a TabBar.
        let tab = app.descendants(matching: .any).matching(identifier: title).firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
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
        capture("gallery-form-active-keyboard")
        if !keyboardVisible {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "keyboard-missing-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
        }
        XCTAssertTrue(keyboardVisible)
        // Native return-key routing must move focus through the form.
        name.typeText("\n")
        app.textFields["form.field.1"].typeText("\n")
        app.textFields["form.field.2"].typeText("\n")
        app.secureTextFields["form.field.3"].typeText("demo-only\n")
        XCTAssertFalse(app.keyboards.firstMatch.exists)
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
}
