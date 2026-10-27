import XCTest
import UIKit
import RhineDesign

@MainActor
final class ComponentBehaviorTests: XCTestCase {
    func testButtonBlocksReentryAndAccessibilityWhileBusy() {
        var calls = 0
        let button = RhineButton("保存")
        button.onActivate = { calls += 1; button.isLoading = true }
        XCTAssertTrue(button.activate())
        XCTAssertEqual(calls, 1)
        XCTAssertFalse(button.activate())
        XCTAssertFalse(button.accessibilityActivate())
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(button.accessibilityLabel, "保存")
        XCTAssertEqual(button.accessibilityValue, "正在处理")
        button.isLoading = false
        button.isEnabled = false
        XCTAssertFalse(button.accessibilityActivate())
        XCTAssertEqual(calls, 1)
        button.isEnabled = true
        XCTAssertTrue(button.accessibilityActivate())
        XCTAssertEqual(calls, 2)
        button.onActivate = nil
    }
    func testFieldErrorAndDisabledDoNotDiscardInput() {
        let field = RhineTextField("邮箱", purpose: .email, help: "用于联系")
        field.text = "draft@example.com"
        field.error = "模拟保存失败"
        field.isEnabled = false
        XCTAssertEqual(field.text, "draft@example.com")
        XCTAssertEqual(field.input.accessibilityHint, "模拟保存失败")
        XCTAssertFalse(field.input.isEnabled)
        field.error = nil
        field.isEnabled = true
        XCTAssertEqual(field.input.accessibilityHint, "用于联系")
        XCTAssertEqual(field.input.keyboardType, .emailAddress)
        XCTAssertEqual(field.text, "draft@example.com")
        XCTAssertTrue(RhineTextField("口令", purpose: .password).input.isSecureTextEntry)
    }
    func testHostUpdatesAreSilentAndMenuUsesStableIDs() {
        let toggle = RhineToggle("提醒")
        var calls = 0
        toggle.onChange = { _ in calls += 1 }
        toggle.isOn = true
        XCTAssertEqual(calls, 0)
        toggle.control.sendActions(for: .valueChanged)
        XCTAssertEqual(calls, 1)
        let choice = RhineChoice("频率", options: [.init(id: "a", title: "每日"), .init(id: "b", title: "每周")], selectedID: "a")
        choice.onChange = { _ in XCTFail("Host update must not synthesize a user action") }
        choice.selectedID = "b"
        XCTAssertEqual(choice.control.accessibilityValue, "每周")
        let actions = choice.control.menu?.children.compactMap { $0 as? UIAction }
        XCTAssertEqual(actions?.map(\.state), [.off, .on])
    }
    func testEmptyStateDoesNotCreateAnInertAction() {
        func buttons(in view: UIView) -> Int {
            (view is RhineButton ? 1 : 0) + view.subviews.reduce(0) { $0 + buttons(in: $1) }
        }
        let unavailable = RhineEmptyState(title: "空内容", actionTitle: "继续")
        XCTAssertEqual(buttons(in: unavailable), 0)
        let actionable = RhineEmptyState(title: "空内容", actionTitle: "添加", action: {})
        XCTAssertEqual(buttons(in: actionable), 1)
    }
}
