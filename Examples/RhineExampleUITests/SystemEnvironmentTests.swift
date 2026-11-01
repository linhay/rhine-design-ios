import XCTest

/// Opt-in checks for simulator settings configured outside the app. No trait overrides.
@MainActor
final class SystemEnvironmentTests: XCTestCase {
    func testConfiguredSystemPreferencesMatchNativeReads() throws {
        continueAfterFailure = false
        let expectations = [
            ("Appearance", "RHINE_EXPECT_APPEARANCE"),
            ("Contrast", "RHINE_EXPECT_CONTRAST"),
            ("Reduce Motion", "RHINE_EXPECT_MOTION"),
            ("Reduce Transparency", "RHINE_EXPECT_TRANSPARENCY")
        ]
        let environment = ProcessInfo.processInfo.environment
        guard expectations.allSatisfy({ environment[$0.1] != nil }) else {
            throw XCTSkip("Set TEST_RUNNER_RHINE_EXPECT_* to match actual simulator system settings.")
        }
        let app = XCUIApplication()
        app.launchArguments = ["--foundation-diagnostics"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Independent UIKit foundations"].waitForExistence(timeout: 30))
        for (name, variable) in expectations {
            let value = app.staticTexts["environment.\(name)"]
            let expected = environment[variable]!
            let matches = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: value)
            XCTAssertEqual(XCTWaiter.wait(for: [matches], timeout: 5), .completed, "\(name): expected \(expected), read \(value.label)")
        }
        let attachment = XCTAttachment(data: XCUIScreen.main.screenshot().pngRepresentation, uniformTypeIdentifier: "public.png")
        attachment.name = "native-system-preferences"; attachment.lifetime = .keepAlways; add(attachment)
    }
}
