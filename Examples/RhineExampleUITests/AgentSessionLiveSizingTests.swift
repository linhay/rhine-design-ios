import XCTest
import UIKit

/// A host-side runner changes the actual simulator setting after each marker.
/// No launch size argument or application trait override is used in these tests.
@MainActor
final class AgentSessionLiveSizingTests: XCTestCase {
    private func launch() throws -> XCUIApplication {
        guard ProcessInfo.processInfo.environment["RHINE_LIVE_SIZE_DRIVER"] == "1" else {
            throw XCTSkip("Run with the host-side system content_size driver.")
        }
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--agent-session", "--agent-long-history", "--agent-inspection"]
        app.launch()
        XCTAssertTrue(app.staticTexts["agent.environment"].waitForExistence(timeout: 30))
        return app
    }

    private func probe(_ app: XCUIApplication) -> [String: Any] {
        let value = app.staticTexts["agent.environment"].value as? String ?? ""
        guard let data = value.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Native inspection is unavailable: \(value)")
            return [:]
        }
        return result
    }
    private func number(_ data: [String: Any], _ key: String) -> Double {
        guard let value = (data[key] as? NSNumber)?.doubleValue, value.isFinite else {
            XCTFail("Missing or invalid native metric: \(key)")
            return -.infinity
        }
        return value
    }
    private func record(_ app: XCUIApplication, _ name: String) {
        let keyboard = app.keyboards.firstMatch
        let keyboardDescription = keyboard.exists ? "\(keyboard.frame)" : "not shown"
        let data = XCTAttachment(string: """
        \(app.staticTexts["agent.environment"].value ?? "")
        window=\(app.windows.firstMatch.frame)
        viewport=\(app.scrollViews["agent.timeline"].frame)
        composer=\(app.scrollViews["agent.composer"].frame)
        input=\(app.textFields["agent.draft"].frame)
        send=\(app.buttons["agent.send"].frame)
        keyboard=\(keyboardDescription)
        """)
        data.name = name + "-geometry"; data.lifetime = .keepAlways; add(data)
        for (suffix, shot) in [("app", app.screenshot()), ("display", XCUIScreen.main.screenshot())] {
            let image = XCTAttachment(screenshot: shot)
            image.name = name + "-" + suffix; image.lifetime = .keepAlways; add(image)
        }
    }
    private func request(_ app: XCUIApplication, _ step: String, maximum: Bool) {
        let setting = maximum ? "accessibility-extra-extra-extra-large" : "large"
        let expected = maximum ? UIContentSizeCategory.accessibilityExtraExtraExtraLarge : .large
        if probe(app)["category"] as? String != expected.rawValue {
            FileHandle.standardOutput.write(Data("RHINE_LIVE_SIZE|\(step)|\(setting)\n".utf8))
        }
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS %@", expected.rawValue),
                                             object: app.staticTexts["agent.environment"])
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 45), .completed)
        // UIKit may distribute font invalidations after the parent's trait callback.
        // Wait for real font metrics and position to settle, without imposing a layout.
        var previous = ""
        var stable = 0
        var settled = false
        for _ in 0..<20 {
            let data = probe(app)
            let font = number(data, "streamFont")
            let signature = "\(data["category"] ?? "")|\(data["anchorID"] ?? "")|\(number(data, "anchorTop"))|\(number(data, "offset"))|\(number(data, "bottom"))|\(number(data, "viewportHeight"))|\(font)|\(number(data, "inputFont"))|\(number(data, "inputLineHeight"))"
            stable = signature == previous ? stable + 1 : 0
            previous = signature
            if stable >= 2 && data["category"] as? String == expected.rawValue
                && (maximum ? font > 40 : font > 0 && font < 30) {
                settled = true
                break
            }
            Thread.sleep(forTimeInterval: 0.15)
        }
        record(app, step)
        XCTAssertTrue(settled, "Native font and geometry did not settle within the bounded wait")
        let actual = probe(app)
        XCTAssertEqual(actual["category"] as? String, expected.rawValue)
        if maximum { XCTAssertGreaterThan(number(actual, "streamFont"), 40) }
        else { XCTAssertLessThan(number(actual, "streamFont"), 30) }
    }
    private func assertBottom(_ app: XCUIApplication, pid: Double) {
        let data = probe(app)
        XCTAssertEqual(number(data, "pid"), pid, "The app must not relaunch during a system size transition")
        XCTAssertEqual(number(data, "bottom") - number(data, "offset"), 0, accuracy: 2)
        let stream = app.staticTexts["agent.stream"], scroll = app.scrollViews["agent.timeline"]
        XCTAssertLessThanOrEqual(stream.frame.maxY, scroll.frame.maxY + 2)
        XCTAssertGreaterThan(stream.frame.maxY, scroll.frame.minY)
    }

    func testLiveSystemSizePreservesBottomAndHistory() throws {
        let app = try launch()
        request(app, "reading-baseline", maximum: false)
        let pid = number(probe(app), "pid")
        XCTAssertGreaterThan(pid, 0)
        app.buttons["agent.latest"].tap()
        assertBottom(app, pid: pid)
        request(app, "bottom-maximum", maximum: true)
        assertBottom(app, pid: pid)
        request(app, "bottom-large", maximum: false)
        assertBottom(app, pid: pid)

        let scroll = app.scrollViews["agent.timeline"]
        scroll.swipeDown(velocity: .slow)
        scroll.swipeDown(velocity: .slow)
        XCTAssertGreaterThan(app.staticTexts["agent.stream"].frame.maxY, scroll.frame.maxY + 24)
        let baseline = probe(app)
        XCTAssertTrue((baseline["anchorID"] as? String)?.hasPrefix("agent.message.") == true)
        XCTAssertEqual(baseline["following"] as? Bool, false)
        record(app, "history-baseline")
        for (step, maximum) in [("history-maximum", true), ("history-large", false)] {
            request(app, step, maximum: maximum)
            let actual = probe(app)
            XCTAssertEqual(number(actual, "pid"), pid)
            XCTAssertEqual(actual["anchorID"] as? String, baseline["anchorID"] as? String)
            XCTAssertEqual(number(actual, "anchorTop"), number(baseline, "anchorTop"), accuracy: 2)
            XCTAssertEqual(actual["following"] as? Bool, false)
        }
    }

    private func ensureCompleteComposerControl(_ control: XCUIElement, app: XCUIApplication,
                                               attachmentName: String) {
        let composer = app.scrollViews["agent.composer"]
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.exists)
        XCTAssertGreaterThan(keyboard.frame.height, 0)
        func viewport() -> CGRect {
            let visible = composer.frame.intersection(app.windows.firstMatch.frame)
            return visible.intersection(CGRect(x: visible.minX, y: visible.minY,
                                              width: visible.width,
                                              height: max(0, keyboard.frame.minY - visible.minY)))
        }
        for _ in 0..<12 {
            let rect = control.frame, visible = viewport()
            if visible.isEmpty || visible.isNull { break }
            if visible.insetBy(dx: -1, dy: -1).contains(rect) { break }
            if rect.width > visible.width + 2 || rect.height > visible.height + 2 { break }
            if rect.minX < visible.minX - 1 || rect.maxX > visible.maxX + 1 { break }
            let down = rect.minY < visible.minY
            let origin = composer.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: visible.maxX - composer.frame.minX - 8,
                                                  dy: visible.minY - composer.frame.minY + visible.height * (down ? 0.3 : 0.7)))
            let end = origin.withOffset(CGVector(dx: visible.maxX - composer.frame.minX - 8,
                                                dy: visible.minY - composer.frame.minY + visible.height * (down ? 0.7 : 0.3)))
            start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        record(app, attachmentName)
        XCTAssertFalse(viewport().isEmpty)
        XCTAssertGreaterThan(control.frame.width, 0)
        XCTAssertGreaterThan(control.frame.height, 0)
        XCTAssertTrue(viewport().insetBy(dx: -1, dy: -1).contains(control.frame),
                      "The entire control must fit inside composer ∩ window and above the keyboard")
        XCTAssertTrue(control.isHittable)
        XCTAssertTrue(app.keyboards.keys["q"].firstMatch.isHittable)
    }

    private func ensureCompleteSend(_ app: XCUIApplication) {
        let send = app.buttons["agent.send"]
        ensureCompleteComposerControl(send, app: app, attachmentName: "complete-send-bounds")
        XCTAssertTrue(send.isEnabled)
    }

    func testLiveSystemSizePreservesDraftSelectionAndKeyboard() throws {
        let app = try launch()
        request(app, "draft-baseline", maximum: false)
        let field = app.textFields["agent.draft"]
        let draft = "ABCDEF"
        field.tap()
        field.typeText(draft)
        // Commit a possible IME marked range before moving the insertion point.
        let done = app.keyboards.descendants(matching: .any).matching(NSPredicate(
            format: "identifier IN %@ OR label IN %@", ["Done", "完成"], ["Done", "完成"])).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        done.tap()
        XCTAssertEqual(field.value as? String, draft)
        let letter = app.keyboards.keys["q"].firstMatch
        if !letter.isHittable { field.tap() }
        let keyboard = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"), object: letter)
        XCTAssertEqual(XCTWaiter.wait(for: [keyboard], timeout: 5), .completed)
        // Use the native space-bar trackpad to move the committed text's caret.
        let space = app.keyboards.keys.matching(NSPredicate(
            format: "identifier IN %@ OR label IN %@", ["space", "Space", "空格"], ["space", "Space", "空格"])).firstMatch
        XCTAssertTrue(space.waitForExistence(timeout: 5))
        XCTAssertTrue(space.isHittable)
        func moveCursor(horizontal distance: CGFloat) {
            let start = space.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let end = start.withOffset(CGVector(dx: distance, dy: 0))
            start.press(forDuration: 1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        moveCursor(horizontal: -40)
        let firstPlacement = probe(app)
        record(app, "draft-trackpad-first-placement")
        if number(firstPlacement, "selectionLength") == 0 {
            let position = number(firstPlacement, "selectionStart")
            // One bounded correction is allowed only when the native caret is at an endpoint.
            if position == 0 { moveCursor(horizontal: 20) }
            else if position == Double(draft.count) { moveCursor(horizontal: -20) }
        }
        let baseline = probe(app)
        let pid = number(baseline, "pid")
        let selectionStart = number(baseline, "selectionStart")
        record(app, "draft-selection-baseline")
        XCTAssertGreaterThan(pid, 0)
        XCTAssertEqual(field.value as? String, draft)
        XCTAssertGreaterThan(selectionStart, 0)
        XCTAssertLessThan(selectionStart, Double(draft.count))
        XCTAssertEqual(number(baseline, "selectionLength"), 0)
        for (step, maximum) in [("draft-maximum", true), ("draft-large", false)] {
            request(app, step, maximum: maximum)
            XCTAssertEqual(field.value as? String, draft)
            let actual = probe(app)
            XCTAssertEqual(number(actual, "pid"), pid)
            XCTAssertEqual(number(actual, "selectionStart"), selectionStart)
            XCTAssertEqual(number(actual, "selectionLength"), 0)
            XCTAssertEqual(actual["firstResponder"] as? Bool, true)
            ensureCompleteComposerControl(field, app: app, attachmentName: step + "-field-visible")
            let inputLineHeight = number(probe(app), "inputLineHeight")
            XCTAssertGreaterThan(inputLineHeight, 0)
            XCTAssertGreaterThanOrEqual(Double(field.frame.height), inputLineHeight,
                                        "The input frame must contain the actual native font line height")
            ensureCompleteSend(app)
            record(app, step + "-send-visible")
        }
        let insertionIndex = Int(selectionStart)
        let expected = String(draft.prefix(insertionIndex)) + "Z" + String(draft.dropFirst(insertionIndex))
        field.typeText("Z")
        XCTAssertEqual(field.value as? String, expected, "Insertion must occur at the original cursor")
        app.buttons["agent.send"].tap()
        let submitted = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "等待接受"),
                                                 object: app.staticTexts["agent.sendStatus"])
        XCTAssertEqual(XCTWaiter.wait(for: [submitted], timeout: 5), .completed)
        XCTAssertEqual(field.value as? String, expected)
        record(app, "draft-submitted-after-live-cycle")
    }
}
