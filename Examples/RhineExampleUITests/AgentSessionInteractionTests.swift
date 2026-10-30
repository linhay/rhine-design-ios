import XCTest
import UIKit

/// Exercises the real UIKit recipe with synthetic host events, not a network service.
@MainActor
final class AgentSessionInteractionTests: XCTestCase {
    private func launch(dark: Bool = false, large: Bool = false, longHistory: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--agent-session", "-UIPreferredContentSizeCategoryName",
                               UIContentSizeCategory.large.rawValue]
        if dark { app.launchArguments.append("--agent-dark") }
        if large { app.launchArguments.append("--agent-large") }
        if longHistory { app.launchArguments.append("--agent-long-history") }
        app.launch()
        XCTAssertTrue(app.scrollViews["agent.timeline"].waitForExistence(timeout: 30))
        let actual = app.staticTexts["agent.environment"].label
        let evidence = XCTAttachment(string: "\(actual)\nWindow: \(app.windows.firstMatch.frame)\nTimeline: \(app.scrollViews["agent.timeline"].frame)")
        evidence.name = "agent-actual-environment"
        evidence.lifetime = .keepAlways
        add(evidence)
        if let expected = ProcessInfo.processInfo.environment["RHINE_AGENT_EXPECT_MOTION"] {
            XCTAssertTrue(actual.contains("减少动态：\(expected)"), "Read actual UIKit preference before exercising the same path")
        }
        return app
    }

    private func waitForText(_ text: String, in element: XCUIElement,
                             file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label CONTAINS %@", text),
            object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed,
                       file: file, line: line)
    }

    private func reach(_ element: XCUIElement, in scroll: XCUIElement,
                       file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), file: file, line: line)
        for _ in 0..<18 {
            if element.isHittable { return }
            if element.frame.midY < scroll.frame.midY {
                scroll.swipeDown(velocity: .slow)
            } else {
                scroll.swipeUp(velocity: .slow)
            }
        }
        XCTFail("Element remains unreachable: \(element.identifier)", file: file, line: line)
    }

    private func demo(_ action: String, in app: XCUIApplication,
                      file: StaticString = #filePath, line: UInt = #line) {
        let entry = app.buttons["agent.demo"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5), file: file, line: line)
        entry.tap()
        let button = app.buttons["action.\(action)"]
        reach(button, in: app.scrollViews["gallery.scroll"].firstMatch, file: file, line: line)
        button.tap()
    }

    private func tapModal(_ identifier: String, in app: XCUIApplication,
                          file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[identifier]
        reach(button, in: app.scrollViews["gallery.scroll"].firstMatch, file: file, line: line)
        button.tap()
    }

    private func capture(_ name: String, app: XCUIApplication) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }

    private func finishTyping(in app: XCUIApplication) {
        // Sending a newline via typeText previously stalled native keyboard tests.
        // Activate the actual software keyboard action instead.
        let key = app.keyboards.descendants(matching: .any).matching(
            NSPredicate(format: "identifier IN %@ OR label IN %@",
                        ["Done", "完成"], ["Done", "完成"])).firstMatch
        XCTAssertTrue(key.waitForExistence(timeout: 5))
        key.tap()
    }

    func testUnknownSendRetainsDraftThroughReconnectAndRejectsLateAcceptance() {
        let app = launch()
        let field = app.textFields["agent.draft"]
        reach(field, in: app.scrollViews["agent.composer"])
        field.tap()
        field.typeText("Synthetic draft")
        let submittedDraft = field.value as? String
        finishTyping(in: app)
        let send = app.buttons["agent.send"]
        reach(send, in: app.scrollViews["agent.composer"])
        send.tap()
        waitForText("等待接受", in: app.staticTexts["agent.sendStatus"])
        XCTAssertFalse(send.isEnabled)
        XCTAssertEqual(field.value as? String, submittedDraft)

        demo("disconnect", in: app)
        waitForText("结果未知", in: app.staticTexts["agent.sendStatus"])
        XCTAssertEqual(field.value as? String, submittedDraft)
        demo("reconnect", in: app)
        waitForText("连接中", in: app.staticTexts["agent.connection"])
        demo("connected", in: app)
        XCTAssertFalse(send.isEnabled, "A connection alone must not resubmit unknown work")
        XCTAssertEqual(field.value as? String, submittedDraft)
        demo("accept", in: app)
        waitForText("已接受", in: app.staticTexts["agent.sendStatus"])
        XCTAssertEqual(field.value as? String, "")

        reach(field, in: app.scrollViews["agent.composer"])
        field.tap()
        field.typeText("New draft")
        finishTyping(in: app)
        let newerDraft = field.value as? String
        demo("accept", in: app)
        XCTAssertEqual(field.value as? String, newerDraft,
                       "A duplicate acceptance must not consume a later draft")
        capture("agent-send-confirmed-new-draft-retained", app: app)
    }

    func testStreamingFollowsBottomAndPreservesHistoricalReadingPosition() {
        let app = launch(longHistory: true)
        let timeline = app.scrollViews["agent.timeline"]
        let stream = app.staticTexts["agent.stream"]
        let original = stream.label
        demo("stream", in: app)
        XCTAssertNotEqual(stream.label, original)
        XCTAssertLessThanOrEqual(stream.frame.maxY, timeline.frame.maxY + 2,
                                 "The current stream should remain at the followed bottom")

        timeline.swipeDown(velocity: .slow)
        timeline.swipeDown(velocity: .slow)
        XCTAssertGreaterThan(stream.frame.maxY, timeline.frame.maxY + 24,
                             "History assertions require the reader to have actually left the bottom follow region")
        let candidates = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "agent.message."))
        let anchor = candidates.allElementsBoundByIndex.first {
            $0.isHittable && $0.frame.minY >= timeline.frame.minY &&
            $0.frame.minY < timeline.frame.maxY - 20
        }
        XCTAssertNotNil(anchor, "A visible historical message is required for this test")
        guard let anchor else { return }
        let relativeY = anchor.frame.minY - timeline.frame.minY
        func recordPosition(_ name: String) {
            let evidence = XCTAttachment(string: "Anchor: \(anchor.identifier) \(anchor.frame)\nViewport: \(timeline.frame)\nStream: \(stream.frame)")
            evidence.name = name
            evidence.lifetime = .keepAlways
            add(evidence)
            capture(name, app: app)
        }
        recordPosition("history-before-stream")
        let historyStream = stream.label
        demo("stream", in: app)
        recordPosition("history-after-first-stream")
        demo("stream", in: app)
        recordPosition("history-after-second-stream")
        XCTAssertNotEqual(stream.label, historyStream)
        XCTAssertEqual(anchor.frame.minY - timeline.frame.minY, relativeY, accuracy: 2,
                       "Streaming below history must preserve the actual reading anchor")
        capture("agent-stream-history-anchor", app: app)
        let latest = app.buttons["agent.latest"]
        XCTAssertTrue(latest.isHittable)
        latest.tap()
        XCTAssertLessThanOrEqual(stream.frame.maxY, timeline.frame.maxY + 2)
        XCTAssertGreaterThan(stream.frame.maxY, timeline.frame.minY)
        capture("agent-stream-return-to-latest", app: app)
    }

    func testAuthorizationAllowsAndDeniesOnlyAfterHostConfirmation() {
        let app = launch()
        demo("authorization", in: app)
        XCUIDevice.shared.press(.home)
        app.activate()
        waitForText("连接中", in: app.staticTexts["auth.connection"])
        XCTAssertFalse(app.buttons["auth.allow"].isEnabled)
        tapModal("auth.reconnect", in: app)
        tapModal("auth.allow", in: app)
        waitForText("等待确认", in: app.staticTexts["auth.status"])
        XCTAssertFalse(app.buttons["auth.allow"].isEnabled)
        XCTAssertFalse(app.buttons["auth.deny"].isEnabled)
        tapModal("auth.confirm", in: app)
        waitForText("允许一次", in: app.staticTexts["agent.authorizationStatus"])
        XCTAssertFalse(app.buttons["auth.allow"].exists)

        demo("authorization", in: app)
        tapModal("auth.deny", in: app)
        waitForText("等待确认", in: app.staticTexts["auth.status"])
        tapModal("auth.confirm", in: app)
        waitForText("拒绝", in: app.staticTexts["agent.authorizationStatus"])
        XCTAssertFalse(app.buttons["auth.deny"].exists)
        capture("agent-authorization-confirmed-denial", app: app)
    }

    func testAuthorizationSurvivesModalObstructionAndWithdrawalCannotReappear() {
        let app = launch()
        demo("blocker", in: app)
        tapModal("blocker.receive", in: app)
        XCTAssertFalse(app.buttons["auth.allow"].exists,
                       "An unrelated modal must not be replaced by the authorization UI")
        tapModal("blocker.done", in: app)
        XCTAssertTrue(app.buttons["auth.allow"].waitForExistence(timeout: 5))
        tapModal("auth.withdraw", in: app)
        waitForText("已撤回", in: app.staticTexts["agent.authorizationStatus"])
        XCTAssertFalse(app.buttons["auth.allow"].exists)

        demo("blocker", in: app)
        tapModal("blocker.receive", in: app)
        tapModal("blocker.withdraw", in: app)
        tapModal("blocker.done", in: app)
        waitForText("已撤回", in: app.staticTexts["agent.authorizationStatus"])
        XCTAssertFalse(app.buttons["auth.allow"].exists,
                       "A withdrawn request must not reappear after another modal closes")
        capture("agent-authorization-withdrawn-while-obstructed", app: app)
    }

    func testBackgroundReconnectDoesNotStopRunOrAcknowledgeStop() {
        let app = launch()
        demo("start", in: app)
        waitForText("运行中", in: app.staticTexts["agent.run"])
        XCUIDevice.shared.press(.home)
        app.activate()
        waitForText("连接中", in: app.staticTexts["agent.connection"])
        waitForText("运行中", in: app.staticTexts["agent.run"])
        demo("connected", in: app)
        demo("stop", in: app)
        waitForText("待确认", in: app.staticTexts["agent.run"])
        demo("stopAccepted", in: app)
        waitForText("停止请求已接收", in: app.staticTexts["agent.run"])
        XCTAssertFalse(app.staticTexts["agent.run"].label.contains("已停止"))
        demo("stopped", in: app)
        waitForText("已停止", in: app.staticTexts["agent.run"])
        capture("agent-stop-confirmed", app: app)
    }

    func testLargestTextDarkKeyboardAndSendRemainReachable() {
        let app = launch(dark: true, large: true)
        waitForText("深色 · 最大辅助字号", in: app.staticTexts["agent.environment"])
        let composer = app.scrollViews["agent.composer"]
        let field = app.textFields["agent.draft"]
        reach(field, in: composer)
        field.tap()
        let letter = app.keyboards.keys["q"].firstMatch
        let keyboard = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"), object: letter)
        XCTAssertEqual(XCTWaiter.wait(for: [keyboard], timeout: 5), .completed)
        XCTAssertTrue(field.isHittable, "The focused input must be reachable above the keyboard")
        letter.tap()
        XCTAssertTrue((field.value as? String)?.lowercased().contains("q") == true)
        capture("agent-largest-dark-software-keyboard", app: app)
        // A Chinese keyboard can leave "q" as marked text. Commit it through the
        // native Done action before reopening the keyboard to exercise sending.
        finishTyping(in: app)
        let draft = field.value as? String
        XCTAssertFalse(draft?.isEmpty ?? true)
        // Some IMEs consume the first Done to confirm the candidate and keep
        // the keyboard open. Others close it; both paths must remain sendable.
        if !letter.isHittable {
            reach(field, in: composer)
            field.tap()
        }
        let reopened = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"), object: letter)
        XCTAssertEqual(XCTWaiter.wait(for: [reopened], timeout: 5), .completed)
        let send = app.buttons["agent.send"]
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND enabled == true"), object: send)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
        // isHittable alone permits a partially clipped button. Scroll until its
        // complete frame is inside the composer and above the actual keyboard.
        for _ in 0..<10 {
            let visible = composer.frame
            let target = send.frame
            if target.minY >= visible.minY - 1 && target.maxY <= visible.maxY + 1 &&
                target.maxY <= app.keyboards.firstMatch.frame.minY + 1 { break }
            let towardTop = target.minY < visible.minY
            let start = composer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: towardTop ? 0.3 : 0.7))
            let end = composer.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: towardTop ? 0.7 : 0.3))
            start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTAssertGreaterThanOrEqual(send.frame.minX, composer.frame.minX - 1)
        XCTAssertLessThanOrEqual(send.frame.maxX, composer.frame.maxX + 1)
        XCTAssertGreaterThanOrEqual(send.frame.minY, composer.frame.minY - 1)
        XCTAssertLessThanOrEqual(send.frame.maxY, composer.frame.maxY + 1)
        XCTAssertLessThanOrEqual(send.frame.maxY, app.keyboards.firstMatch.frame.minY + 1)
        XCTAssertTrue(send.isHittable, "The send action must be reachable while the keyboard is open")
        XCTAssertTrue(letter.isHittable, "Scrolling to send must preserve the visible software keyboard")
        XCTAssertTrue(send.isEnabled, "A completed draft must be sendable before this action")
        capture("agent-largest-dark-send-ready-above-keyboard", app: app)
        send.tap()
        waitForText("等待接受", in: app.staticTexts["agent.sendStatus"])
        XCTAssertEqual(field.value as? String, draft)
        XCTAssertFalse(send.isEnabled)
        capture("agent-largest-dark-send-awaiting-confirmation", app: app)
    }
}
