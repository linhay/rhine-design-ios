import XCTest

@MainActor
final class FoundationConsumptionTests: XCTestCase {
    func testUIKitGalleryShowsContentAndScrollsToEnd() {
        let app = XCUIApplication()
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
}
