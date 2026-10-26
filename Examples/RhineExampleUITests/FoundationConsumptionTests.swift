import XCTest

@MainActor
final class FoundationConsumptionTests: XCTestCase {
    func testPublicPackageGalleryRemainsReadableAndScrollable() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Independent iOS foundations"].waitForExistence(timeout: 10))

        let supporting = app.staticTexts["Supporting · 合成说明"]
        for _ in 0..<16 {
            if supporting.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(supporting.isHittable, "The final typography role must remain reachable by scrolling.")
        XCTAssertTrue(app.staticTexts["Label · 持久标签"].exists)
    }
}
