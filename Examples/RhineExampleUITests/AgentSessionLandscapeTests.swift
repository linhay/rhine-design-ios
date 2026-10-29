import XCTest
import UIKit

/// Bounded landscape checks. System-size runs set RHINE_AGENT_EXPECT_SIZE to
/// "最大辅助字号" after changing the simulator setting externally; no launch-size
/// override is used in that mode. The default preview is not live-system evidence.
@MainActor
final class AgentSessionLandscapeTests: XCTestCase {
    private func launchLandscape() -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--agent-session"]
        if ProcessInfo.processInfo.environment["RHINE_AGENT_EXPECT_SIZE"] == nil {
            app.launchArguments.append("--agent-large")
        }
        app.launch()
        XCTAssertTrue(app.scrollViews["agent.timeline"].waitForExistence(timeout: 30))
        waitForText("最大辅助字号", in: app.staticTexts["agent.environment"])
        if let expected = ProcessInfo.processInfo.environment["RHINE_AGENT_EXPECT_SIZE"] {
            XCTAssertEqual(expected, "最大辅助字号", "This case specifically requires the largest accessibility size")
            waitForText(expected, in: app.staticTexts["agent.environment"])
        }
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                let frame = app.windows.firstMatch.frame
                return frame.width > frame.height && frame.height > 0
            }, object: app)
        let result = XCTWaiter.wait(for: [landscape], timeout: 10)
        capture("landscape-actual-window", app: app)
        XCTAssertEqual(result, .completed, "A requested device orientation alone does not prove the actual window rotated")
        return app
    }

    private func waitForText(_ text: String, in element: XCUIElement,
                             file: StaticString = #filePath, line: UInt = #line) {
        let expected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label CONTAINS %@", text), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expected], timeout: 5), .completed, file: file, line: line)
    }

    private func capture(_ name: String, app: XCUIApplication, elements: [XCUIElement] = [],
                         includeHierarchy: Bool = false) {
        var details = ["Launch arguments: \(app.launchArguments)", "Window: \(app.windows.firstMatch.frame)"]
        let environment = app.staticTexts["agent.environment"]
        details.append(environment.exists ? "Environment: \(environment.label)" : "Main environment hidden by current modal; see launch attachment")
        if app.keyboards.firstMatch.exists { details.append("Keyboard: \(app.keyboards.firstMatch.frame)") }
        details += elements.enumerated().map { index, element in
            element.exists
                ? "\(element.identifier): \(element.frame), hittable=\(element.isHittable), enabled=\(element.isEnabled)"
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

    private func drag(_ scroll: XCUIElement, upward: Bool, distance: CGFloat? = nil) {
        // Use the scroll margin, away from text-selection and button hit regions.
        let fraction = min(0.6, max(0.04, (distance ?? scroll.frame.height * 0.6) / scroll.frame.height))
        let startY: CGFloat = upward ? 0.8 : 0.2
        let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: startY))
        let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: startY + (upward ? -fraction : fraction)))
        start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }

    private func reachFully(_ element: XCUIElement, in scroll: XCUIElement, app: XCUIApplication,
                            file: StaticString = #filePath, line: UInt = #line) {
        guard element.waitForExistence(timeout: 5) else {
            capture("landscape-control-missing", app: app, elements: [scroll, element], includeHierarchy: true)
            XCTFail("The requested control does not exist in the accessibility hierarchy", file: file, line: line)
            return
        }
        for _ in 0..<22 {
            let viewport = usableViewport(scroll, app: app)
            if element.isHittable && isFullyVisible(element.frame, in: viewport) { return }
            if element.frame.height > viewport.height + 1 || element.frame.width > viewport.width + 1 {
                capture("landscape-control-exceeds-viewport", app: app, elements: [scroll, element])
                XCTFail("The entire control cannot fit in its actual visible scroll viewport", file: file, line: line)
                return
            }
            let upward = element.frame.maxY > viewport.maxY
            let clipped = upward ? element.frame.maxY - viewport.maxY : viewport.minY - element.frame.minY
            // Include enough travel to begin the native pan before correcting clipping.
            drag(scroll, upward: upward, distance: clipped + 20)
        }
        capture("landscape-control-unreachable", app: app, elements: [scroll, element])
        XCTFail("The entire control remains clipped or unreachable", file: file, line: line)
    }

    private func openAuthorization(in app: XCUIApplication) {
        app.buttons["agent.demo"].tap()
        let scroll = app.scrollViews["gallery.scroll"].firstMatch
        let request = app.buttons["action.authorization"]
        reachFully(request, in: scroll, app: app)
        request.tap()
        XCTAssertTrue(app.buttons["auth.allow"].waitForExistence(timeout: 5))
    }

    private func inspectAuthorizationContext(in app: XCUIApplication) {
        let scroll = app.scrollViews["gallery.scroll"].firstMatch
        let context = app.staticTexts.matching(NSPredicate(
            format: "label BEGINSWITH %@", "示例会话 · 示例任务")).firstMatch
        XCTAssertTrue(context.waitForExistence(timeout: 5))
        XCTAssertTrue(context.label.contains("操作：读取合成目录"))
        XCTAssertTrue(context.label.contains("范围：仅这一次读取，不授予后续操作权限。"))
        XCTAssertTrue(context.label.hasSuffix("没有访问真实文件、网络或主机。"))
        // The context may be taller than the landscape window. Read it through
        // overlapping slices, rather than claiming the whole UILabel fits at once.
        for _ in 0..<18 {
            let viewport = usableViewport(scroll, app: app)
            if context.frame.minY >= viewport.minY - 1 && context.frame.minY < viewport.maxY - 80 { break }
            drag(scroll, upward: context.frame.minY >= viewport.maxY - 80)
        }
        let top = usableViewport(scroll, app: app)
        capture("landscape-authorization-context-start", app: app, elements: [scroll, context])
        XCTAssertGreaterThanOrEqual(context.frame.minY, top.minY - 1)
        XCTAssertLessThan(context.frame.minY, top.maxY - 80)
        XCTAssertGreaterThanOrEqual(context.frame.minX, top.minX - 1)
        XCTAssertLessThanOrEqual(context.frame.maxX, top.maxX + 1)
        for index in 0..<18 {
            let viewport = usableViewport(scroll, app: app)
            if context.frame.maxY <= viewport.maxY - 4 && context.frame.maxY >= viewport.minY + 80 { break }
            let upward = context.frame.maxY > viewport.maxY - 4
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: upward ? 0.7 : 0.3))
            let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: upward ? 0.3 : 0.7))
            start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
            capture("landscape-authorization-context-slice-\(index)", app: app, elements: [scroll, context])
        }
        let bottom = usableViewport(scroll, app: app)
        XCTAssertLessThanOrEqual(context.frame.maxY, bottom.maxY)
        XCTAssertGreaterThanOrEqual(context.frame.maxY, bottom.minY + 80,
                                    "Keep the final line visible; merely finding the full AX label is insufficient")
        capture("landscape-authorization-context-end", app: app, elements: [scroll, context])
    }

    func testLargestTextLandscapeKeyboardCanSendCommittedDraft() {
        let original = XCUIDevice.shared.orientation
        defer {
            XCUIApplication().terminate()
            XCUIDevice.shared.orientation = original
        }
        let app = launchLandscape()
        let composer = app.scrollViews["agent.composer"]
        let field = app.textFields["agent.draft"]
        reachFully(field, in: composer, app: app)
        field.tap()
        let letter = app.keyboards.keys["q"].firstMatch
        let keyboard = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"), object: letter)
        XCTAssertEqual(XCTWaiter.wait(for: [keyboard], timeout: 5), .completed)
        capture("landscape-keyboard-shown-before-input-reach", app: app,
                elements: [composer, field, letter], includeHierarchy: true)
        reachFully(field, in: composer, app: app)
        letter.tap()
        XCTAssertTrue((field.value as? String)?.lowercased().contains("q") == true)
        capture("landscape-largest-input-and-keyboard", app: app, elements: [composer, field, letter])
        let done = app.keyboards.descendants(matching: .any).matching(NSPredicate(
            format: "identifier IN %@ OR label IN %@", ["Done", "完成"], ["Done", "完成"])).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        done.tap()
        let draft = field.value as? String
        XCTAssertFalse(draft?.isEmpty ?? true)
        if !letter.isHittable { reachFully(field, in: composer, app: app); field.tap() }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"), object: letter)], timeout: 5), .completed)
        let send = app.buttons["agent.send"]
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND enabled == true"), object: send)], timeout: 5), .completed)
        reachFully(send, in: composer, app: app)
        capture("landscape-send-after-scroll", app: app, elements: [composer, field, send, letter])
        XCTAssertTrue(letter.isHittable, "Reaching send must not dismiss the visible software keyboard")
        XCTAssertTrue(send.isEnabled)
        capture("landscape-largest-send-ready", app: app, elements: [composer, field, send, letter])
        if app.windows.firstMatch.frame.height < 450 {
            let latest = app.buttons["agent.latest"]
            reachFully(latest, in: composer, app: app)
            latest.tap()
            XCTAssertFalse(letter.isHittable, "Latest restores reading space in the compact editor")
            let timeline = app.scrollViews["agent.timeline"]
            XCTAssertGreaterThan(timeline.frame.height, 0)
            let stream = app.staticTexts["agent.stream"]
            XCTAssertLessThanOrEqual(stream.frame.maxY, timeline.frame.maxY + 2)
            XCTAssertGreaterThan(stream.frame.maxY, timeline.frame.minY)
            XCTAssertTrue(app.buttons["agent.demo"].isHittable)
            capture("landscape-latest-restores-reading", app: app, elements: [timeline, stream])
            reachFully(field, in: composer, app: app)
            field.tap()
            XCTAssertTrue(letter.waitForExistence(timeout: 5))
            reachFully(send, in: composer, app: app)
            XCTAssertTrue(letter.isHittable)
            XCTAssertEqual(field.value as? String, draft)
            capture("landscape-send-after-reading", app: app, elements: [composer, send, letter])
        }
        send.tap()
        waitForText("等待接受", in: app.staticTexts["agent.sendStatus"])
        XCTAssertEqual(field.value as? String, draft)
        XCTAssertFalse(send.isEnabled)
        capture("landscape-largest-send-awaiting", app: app, elements: [composer, field, send])
    }

    func testLargestTextLandscapeAuthorizationContextAndDecisionsRemainReachable() {
        let original = XCUIDevice.shared.orientation
        defer {
            XCUIApplication().terminate()
            XCUIDevice.shared.orientation = original
        }
        let app = launchLandscape()
        for (decision, expected) in [("allow", "允许一次"), ("deny", "拒绝")] {
            openAuthorization(in: app)
            inspectAuthorizationContext(in: app)
            let scroll = app.scrollViews["gallery.scroll"].firstMatch
            let button = app.buttons["auth.\(decision)"]
            reachFully(button, in: scroll, app: app)
            XCTAssertTrue(button.isEnabled)
            capture("landscape-authorization-\(decision)-ready", app: app, elements: [scroll, button])
            button.tap()
            waitForText("等待确认", in: app.staticTexts["auth.status"])
            XCTAssertFalse(app.buttons["auth.allow"].isEnabled)
            XCTAssertFalse(app.buttons["auth.deny"].isEnabled)
            let confirm = app.buttons["auth.confirm"]
            reachFully(confirm, in: scroll, app: app)
            confirm.tap()
            waitForText(expected, in: app.staticTexts["agent.authorizationStatus"])
            XCTAssertFalse(app.buttons["auth.allow"].exists)
            XCTAssertGreaterThan(app.windows.firstMatch.frame.width, app.windows.firstMatch.frame.height)
            capture("landscape-authorization-\(decision)-confirmed", app: app)
        }
    }
}
