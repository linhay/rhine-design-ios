import XCTest
import UIKit

@MainActor
final class FoundationConsumptionTests: XCTestCase {
    func testUIKitGalleryShowsContentAndScrollsToEnd() {
        let app = XCUIApplication()
        app.launchArguments = ["--foundation-diagnostics"]
        app.launch()
        guard app.staticTexts["Independent UIKit foundations"].waitForExistence(timeout: 30) else {
            XCTFail("The UIKit gallery did not reach its initial screen.")
            return
        }

        let supporting = app.staticTexts["Supporting · 合成说明"]
        for _ in 0..<16 {
            if supporting.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(supporting.isHittable, "The final typography role must remain reachable by scrolling.")
        XCTAssertTrue(app.staticTexts["Label · 持久标签"].exists)
    }

    func testAppearanceChangesAreReportedWithoutRelaunch() {
        continueAfterFailure = false
        let original = XCUIDevice.shared.appearance
        let app = launchGallery()
        defer {
            XCUIDevice.shared.appearance = original
            app.terminate()
        }
        for (appearance, label) in [(XCUIDevice.Appearance.light, "Light"), (.dark, "Dark")] {
            XCUIDevice.shared.appearance = appearance
            let value = app.staticTexts["environment.Appearance"]
            let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", label), object: value)
            let result = XCTWaiter.wait(for: [changed], timeout: 10)
            capture(app, name: "appearance-\(label)")
            XCTAssertEqual(result, .completed, "Expected \(label), received \(value.label); device appearance \(XCUIDevice.shared.appearance.rawValue)")
        }
    }

    func testLargeTextInPortrait() {
        verifyLayout(category: .large)
    }

    func testExtraExtraExtraLargeTextInPortrait() {
        verifyLayout(category: .extraExtraExtraLarge)
    }

    func testAccessibilityExtraLargeTextInPortrait() {
        verifyLayout(category: .accessibilityExtraLarge)
    }

    func testAccessibilityExtraExtraExtraLargeTextInPortrait() {
        verifyLayout(category: .accessibilityExtraExtraExtraLarge)
    }

    func testDefaultTextRemainsReachableAfterRotation() {
        verifyLayout(category: .large, orientations: [.portrait, .landscapeLeft])
    }

    func testLargestAccessibleTextRemainsReachableAfterRotation() {
        verifyLayout(category: .accessibilityExtraExtraExtraLarge, orientations: [.portrait, .landscapeLeft])
    }

    func testLargestAccessibleTextInNarrowContent() {
        verifyLayout(category: .accessibilityExtraExtraExtraLarge, narrowContent: true)
    }

    func testIPadWindowResizeKeepsLargestTextReachable() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad,
                          "This check exercises the iPad system window resize handle.")
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("Earlier iPadOS multitasking requires its own split-view interaction.")
        }
        continueAfterFailure = false
        let app = launchGallery(category: .accessibilityExtraExtraExtraLarge)
        let window = app.windows.firstMatch
        let initial = window.frame
        defer {
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.99))
                .press(forDuration: 0.5, thenDragTo: app.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: initial.maxX - 5, dy: initial.maxY - 5)))
            app.terminate()
        }
        // Drag the system's visible bottom-right resize handle, not a test-only view constraint.
        // A previous interrupted run may leave the simulator in a narrow window; that
        // state is itself valid evidence for the narrow-window assertions below.
        if initial.width > 400 {
            for requestedWidth in [320.0, 200.0] {
                let target = app.coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: requestedWidth, dy: initial.height * 0.8))
                window.coordinate(withNormalizedOffset: CGVector(dx: 0.99, dy: 0.99))
                    .press(forDuration: 0.5, thenDragTo: target)
            }
        }
        let resized = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            initial.width <= 400 || window.frame.width < initial.width - 50
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [resized], timeout: 10), .completed)
        capture(app, name: "ipad-window-\(Int(window.frame.width))x\(Int(window.frame.height))-initial")
        let footer = app.staticTexts["No custom animation is added. System accessibility preferences above are read live."]
        let scroll = app.scrollViews["foundation.scroll"]
        for _ in 0..<48 {
            if footer.isHittable { break }
            scroll.swipeUp(velocity: .fast)
        }
        XCTAssertTrue(footer.isHittable)
        let body = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Body ·")).firstMatch
        XCTAssertGreaterThan(body.frame.width, 0)
        // XCTest reports child frames in the app window while the scroll view frame
        // can be reported in the simulator display coordinate space after a system
        // window move. Width and full-display captures provide the stable geometry
        // evidence for this resized-window check.
        scroll.swipeUp(velocity: .slow)
        scroll.swipeUp(velocity: .slow)
        capture(app, name: "ipad-window-\(Int(window.frame.width))x\(Int(window.frame.height))-end")
    }

    private func launchGallery(category: UIContentSizeCategory? = nil,
                               narrowContent: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--foundation-diagnostics"]
        if let category {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", category.rawValue]
        }
        if narrowContent {
            app.launchArguments.append("--preview-narrow-content")
        }
        app.launch()
        XCTAssertTrue(app.staticTexts["Independent UIKit foundations"].waitForExistence(timeout: 30))
        if let category {
            // Assert the effective UIKit trait; launch arguments alone are not evidence.
            XCTAssertEqual(app.staticTexts["environment.Dynamic Type"].label, category.rawValue)
        }
        capture(app, name: "initial-\(category?.rawValue ?? "system")")
        return app
    }

    private func verifyLayout(category: UIContentSizeCategory,
                              orientations: [UIDeviceOrientation] = [.portrait],
                              narrowContent: Bool = false) {
        continueAfterFailure = false
        let device = XCUIDevice.shared
        let originalOrientation = device.orientation
        device.orientation = .portrait
        let app = launchGallery(category: category, narrowContent: narrowContent)
        defer {
            device.orientation = originalOrientation
            app.terminate()
        }
        for orientation in orientations {
            device.orientation = orientation
            let window = app.windows.firstMatch
            let rotated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                let frame = window.frame
                return orientation == .portrait ? frame.height > frame.width : frame.width > frame.height
            }, object: nil)
            let result = XCTWaiter.wait(for: [rotated], timeout: 10)
            capture(app, name: "rotation-\(orientation.rawValue)")
            XCTAssertEqual(result, .completed, "Requested orientation \(orientation.rawValue), device \(device.orientation.rawValue), window \(window.frame)")
            let scroll = app.scrollViews["foundation.scroll"]
            let end = app.staticTexts["Supporting · 合成说明"]
            for _ in 0..<24 {
                if end.isHittable { break }
                scroll.swipeUp(velocity: .fast)
            }
            XCTAssertTrue(end.isHittable, "The final role must remain reachable at \(category.rawValue).")
            let body = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Body ·")).firstMatch
            XCTAssertTrue(body.exists)
            if narrowContent {
                // 320pt outer content minus the section's 16pt margins on each side.
                XCTAssertEqual(body.frame.width, 288, accuracy: 1)
            }
            for label in [body, end] {
                XCTAssertGreaterThan(label.frame.width, 0)
            }
            let footer = app.staticTexts["No custom animation is added. System accessibility preferences above are read live."]
            for _ in 0..<8 {
                if footer.isHittable { break }
                scroll.swipeUp(velocity: .fast)
            }
            XCTAssertTrue(footer.isHittable, "The final explanatory text must remain reachable.")
            // Move past the hittable threshold so the independent display capture
            // includes the complete footer rather than only its first line.
            scroll.swipeUp(velocity: .slow)
            scroll.swipeUp(velocity: .slow)
            capture(app, name: "\(category.rawValue)-\(orientation.rawValue)-\(Int(window.frame.width))x\(Int(window.frame.height))")
        }
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "app-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        // Preserve an independent full-display capture for rotation diagnostics.
        // A successful layout assertion alone does not establish visual correctness.
        let display = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        display.name = "display-\(name)"
        display.lifetime = .keepAlways
        add(display)
    }
}
