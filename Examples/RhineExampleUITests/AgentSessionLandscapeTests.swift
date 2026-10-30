import XCTest
import UIKit

/// Bounded landscape checks. System-size runs set RHINE_AGENT_EXPECT_SIZE to
/// "最大辅助字号" after changing the simulator setting externally; no launch-size
/// override is used in that mode. The default preview is not live-system evidence.
@MainActor
final class AgentSessionLandscapeTests: XCTestCase {
    /// Opt-in because this changes a real system window, not an app preview.
    private func launchMinimumIPadWindow() throws -> XCUIApplication {
        guard ProcessInfo.processInfo.environment["RHINE_WINDOW_RESIZE"] == "1",
              UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Requires an exclusively reserved iPad with system windowing enabled")
        }
        continueAfterFailure = false
        executionTimeAllowance = 240
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--agent-session", "--agent-inspection"]
        app.launch()
        XCTAssertTrue(app.scrollViews["agent.timeline"].waitForExistence(timeout: 20))
        waitForText("最大辅助字号", in: app.staticTexts["agent.environment"])
        capture("minimum-window-launch", app: app)
        func shrink() {
            let frame = app.windows.firstMatch.frame
            screenPoint(frame.maxX - 10, frame.maxY - 10)
                .press(forDuration: 0.5, thenDragTo: screenPoint(frame.minX + 150, frame.minY + 260),
                       withVelocity: .slow, thenHoldForDuration: 0.5)
        }
        shrink()
        let minimum = app.windows.firstMatch.frame
        capture("minimum-window-first-inward-drag", app: app)
        XCTAssertLessThanOrEqual(minimum.width, 400)
        XCTAssertLessThanOrEqual(minimum.height, 500)
        shrink()
        let clamped = app.windows.firstMatch.frame
        capture("minimum-window-second-inward-drag", app: app, includeHierarchy: true)
        XCTAssertEqual(clamped.width, minimum.width, accuracy: 1)
        XCTAssertEqual(clamped.height, minimum.height, accuracy: 1)
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

    func testMinimumIPadWindowLargestTextReading() throws {
        let app = try launchMinimumIPadWindow()
        let timeline = app.scrollViews["agent.timeline"]
        windowRead(app.staticTexts["agent.message.5"], in: timeline, app: app, name: "minimum-long-body")
    }

    func testMinimumIPadWindowLargestTextKeyboardSend() throws {
        let app = try launchMinimumIPadWindow()
        let composer = app.scrollViews["agent.composer"]
        let field = app.textFields["agent.draft"]
        windowReach(field, in: composer, app: app)
        windowTap(field, app: app)
        let letter = app.keyboards.keys["q"].firstMatch
        XCTAssertTrue(letter.waitForExistence(timeout: 5))
        capture("minimum-visible-software-keyboard", app: app, elements: [composer, field, letter], includeHierarchy: true)
        XCTAssertTrue(letter.isHittable)
        windowReach(field, in: composer, app: app)
        letter.tap()
        XCTAssertTrue((field.value as? String)?.lowercased().contains("q") == true)
        let done = app.keyboards.descendants(matching: .any).matching(NSPredicate(
            format: "identifier IN %@ OR label IN %@", ["Done", "完成"], ["Done", "完成"])).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        done.tap()
        let draft = field.value as? String
        XCTAssertFalse(draft?.isEmpty ?? true)
        if !letter.isHittable {
            windowReach(field, in: composer, app: app)
            windowTap(field, app: app)
        }
        let send = app.buttons["agent.send"]
        windowReach(send, in: composer, app: app)
        XCTAssertTrue(letter.isHittable)
        XCTAssertTrue(send.isEnabled)
        capture("minimum-keyboard-send-ready", app: app, elements: [composer, field, send, letter])
        windowTap(send, app: app)
        waitForText("等待接受", in: app.staticTexts["agent.sendStatus"])
        XCTAssertEqual(field.value as? String, draft)
        XCTAssertFalse(send.isEnabled)
        capture("minimum-send-awaiting", app: app, elements: [composer, field, send])
    }

    func testMinimumIPadWindowLargestTextAuthorization() throws {
        let app = try launchMinimumIPadWindow()
        for (decision, expected) in [("allow", "允许一次"), ("deny", "拒绝")] {
            app.buttons["agent.demo"].tap()
            let scroll = app.scrollViews["gallery.scroll"].firstMatch
            let request = app.buttons["action.authorization"]
            windowReach(request, in: scroll, app: app)
            windowTap(request, app: app)
            let context = app.staticTexts.matching(NSPredicate(
                format: "label BEGINSWITH %@", "示例会话 · 示例任务")).firstMatch
            XCTAssertTrue(context.waitForExistence(timeout: 5))
            XCTAssertTrue(context.label.contains("操作：读取合成目录"))
            XCTAssertTrue(context.label.contains("范围：仅这一次读取，不授予后续操作权限。"))
            XCTAssertTrue(context.label.hasSuffix("没有访问真实文件、网络或主机。"))
            windowRead(context, in: scroll, app: app, name: "minimum-authorization-context-" + decision)
            let button = app.buttons["auth.\(decision)"]
            windowReach(button, in: scroll, app: app)
            capture("minimum-authorization-" + decision + "-ready", app: app, elements: [scroll, button])
            windowTap(button, app: app)
            waitForText("等待确认", in: app.staticTexts["auth.status"])
            XCTAssertFalse(app.buttons["auth.allow"].isEnabled)
            XCTAssertFalse(app.buttons["auth.deny"].isEnabled)
            let confirm = app.buttons["auth.confirm"]
            windowReach(confirm, in: scroll, app: app)
            windowTap(confirm, app: app)
            waitForText(expected, in: app.staticTexts["agent.authorizationStatus"])
            capture("minimum-authorization-" + decision + "-confirmed", app: app)
        }
    }

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
                         includeHierarchy: Bool = false, includeHittability: Bool = true) {
        var details = ["Launch arguments: \(app.launchArguments)", "Window: \(app.windows.firstMatch.frame)"]
        let environment = app.staticTexts["agent.environment"]
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

    private func launchCompactRecipeFromGallery() throws -> XCUIApplication {
        continueAfterFailure = false
        executionTimeAllowance = 180
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("Compact navigation cases target the phone's short landscape keyboard viewport")
        }
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        // Normal navigation entry: the standalone --agent-session root has no Back.
        if ProcessInfo.processInfo.environment["RHINE_AGENT_EXPECT_SIZE"] == nil {
            app.launchArguments = ["--agent-large"]
        }
        app.launch()
        XCTAssertTrue(app.scrollViews["gallery.scroll"].waitForExistence(timeout: 30))
        openRecipeFromGallery(app)
        waitForText("最大辅助字号", in: app.staticTexts["agent.environment"])
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                app.windows.firstMatch.frame.width > app.windows.firstMatch.frame.height
            }, object: app)], timeout: 10), .completed)
        let field = app.textFields["agent.draft"]
        reachFully(field, in: app.scrollViews["agent.composer"], app: app)
        field.tap()
        let letter = app.keyboards.keys["q"].firstMatch
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"), object: letter)], timeout: 5), .completed)
        // Enter through the visible software keyboard, then commit the IME.
        // typeText can leave this simulator's keyboard offscreen while the
        // text field still owns focus, which is not a compact-editing premise.
        letter.tap()
        let done = app.keyboards.descendants(matching: .any).matching(NSPredicate(
            format: "identifier IN %@ OR label IN %@", ["Done", "完成"], ["Done", "完成"])).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        done.tap()
        if !letter.isHittable { field.tap() }
        let composer = app.scrollViews["agent.composer"]
        let compact = XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                letter.isHittable && abs(composer.frame.minY - app.windows.firstMatch.frame.minY) <= 1 &&
                composer.frame.height > 0 && composer.frame.height < 200
            }, object: app)], timeout: 5)
        print("RHINE_NAV_START window=\(app.windows.firstMatch.frame) composer=\(composer.frame) field=\(field.frame)")
        capture("navigation-compact-start", app: app,
                elements: [composer, field, letter, app.buttons["agent.demo"]], includeHierarchy: true)
        XCTAssertEqual(compact, .completed, "Require the visible software keyboard and actual compact viewport")
        XCTAssertLessThan(app.windows.firstMatch.frame.height, 450)
        XCTAssertEqual(field.value as? String, "q")
        return app
    }

    private func openRecipeFromGallery(_ app: XCUIApplication) {
        let entry = app.buttons["Agent 会话 · 合成配方"]
        reachFully(entry, in: app.scrollViews["gallery.scroll"].firstMatch, app: app)
        entry.tap()
        XCTAssertTrue(app.scrollViews["agent.timeline"].waitForExistence(timeout: 5))
        assertRecipeNavigation(app)
    }

    private func assertRecipeNavigation(_ app: XCUIApplication,
                                        file: StaticString = #filePath, line: UInt = #line) {
        let demo = app.buttons["agent.demo"]
        let back = app.navigationBars.buttons["总览"]
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"), object: demo)], timeout: 5), .completed,
                       file: file, line: line)
        XCTAssertTrue(back.isHittable, "The original Gallery Back action must return", file: file, line: line)
        XCTAssertTrue(isFullyVisible(back.frame, in: app.windows.firstMatch.frame), file: file, line: line)
    }

    private func finishNativeEditing(_ app: XCUIApplication) {
        let key = app.keyboards.descendants(matching: .any).matching(NSPredicate(
            format: "identifier IN %@ OR label IN %@", ["Done", "完成"], ["Done", "完成"])).firstMatch
        // With a Chinese IME, the first Done can commit composition; the next
        // actual native Done ends editing. No programmatic resign or send tap.
        for _ in 0..<2 {
            if !app.keyboards.firstMatch.exists { break }
            XCTAssertTrue(key.waitForExistence(timeout: 5))
            key.tap()
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in !app.keyboards.firstMatch.exists }, object: app)], timeout: 5), .completed)
    }

    func testCompactDoneRestoresNavigationAndDraft() throws {
        defer { XCUIApplication().terminate(); XCUIDevice.shared.orientation = .portrait }
        let app = try launchCompactRecipeFromGallery()
        finishNativeEditing(app)
        assertRecipeNavigation(app)
        XCTAssertEqual(app.textFields["agent.draft"].value as? String, "q")
        waitForText("未发送", in: app.staticTexts["agent.sendStatus"])
        capture("navigation-done-restored", app: app, elements: [app.textFields["agent.draft"]], includeHierarchy: true)
        app.navigationBars.buttons["总览"].tap()
        XCTAssertTrue(app.scrollViews["gallery.scroll"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["总览"].exists)
    }

    func testCompactRotationRestoresNavigationAndDraft() throws {
        defer { XCUIApplication().terminate(); XCUIDevice.shared.orientation = .portrait }
        let app = try launchCompactRecipeFromGallery()
        XCUIDevice.shared.orientation = .portrait
        capture("navigation-after-rotation", app: app, elements: [app.textFields["agent.draft"]])
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                app.windows.firstMatch.frame.height > app.windows.firstMatch.frame.width
            }, object: app)], timeout: 10), .completed)
        assertRecipeNavigation(app)
        XCTAssertEqual(app.textFields["agent.draft"].value as? String, "q")
        XCTAssertTrue(app.keyboards.keys["q"].firstMatch.isHittable)
        waitForText("未发送", in: app.staticTexts["agent.sendStatus"])
        capture("navigation-rotation-restored", app: app, elements: [app.textFields["agent.draft"]], includeHierarchy: true)
        finishNativeEditing(app)
        app.navigationBars.buttons["总览"].tap()
        XCTAssertTrue(app.scrollViews["gallery.scroll"].waitForExistence(timeout: 5))
    }

    func testCompactExitAndNewRecipeRestoreNavigation() throws {
        defer { XCUIApplication().terminate(); XCUIDevice.shared.orientation = .portrait }
        let app = try launchCompactRecipeFromGallery()
        // Use the recipe's visible exit route. A hidden navigation bar does not
        // promise an edge-pop gesture; latest restores reading and native Back.
        let latest = app.buttons["agent.latest"]
        reachFully(latest, in: app.scrollViews["agent.composer"], app: app)
        latest.tap()
        assertRecipeNavigation(app)
        XCTAssertEqual(app.textFields["agent.draft"].value as? String, "q")
        waitForText("未发送", in: app.staticTexts["agent.sendStatus"])
        capture("navigation-before-native-back", app: app, elements: [app.textFields["agent.draft"]])
        app.navigationBars.buttons["总览"].tap()
        XCTAssertTrue(app.scrollViews["gallery.scroll"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["总览"].exists)
        XCTAssertTrue(app.buttons["预览"].isHittable)
        capture("navigation-compact-exit-gallery", app: app, includeHierarchy: true)
        XCUIDevice.shared.orientation = .portrait
        openRecipeFromGallery(app)
        // A popped recipe is destroyed. A new recipe deliberately owns a new
        // synthetic model; persistence across instances is the consumer's policy.
        XCTAssertNotEqual(app.textFields["agent.draft"].value as? String, "q")
        waitForText("未发送", in: app.staticTexts["agent.sendStatus"])
        capture("navigation-new-recipe", app: app, elements: [app.textFields["agent.draft"]], includeHierarchy: true)
        app.navigationBars.buttons["总览"].tap()
        XCTAssertTrue(app.scrollViews["gallery.scroll"].waitForExistence(timeout: 5))
    }
}
