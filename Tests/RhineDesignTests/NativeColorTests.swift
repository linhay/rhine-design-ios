import XCTest
import UIKit
import RhineDesign

@MainActor
final class NativeColorTests: XCTestCase {
    func testPublicColorsRetainNativeTraitAdaptation() {
        let colors: [(UIColor, UIColor)] = [
            (RhineColor.textPrimary, .label),
            (RhineColor.textSecondary, .secondaryLabel),
            (RhineColor.canvas, .systemBackground),
            (RhineColor.group, .systemGroupedBackground),
            (RhineColor.separator, .separator),
            (RhineColor.error, .systemRed)
        ]
        for style in [UIUserInterfaceStyle.light, .dark] {
            for contrast in [UIAccessibilityContrast.normal, .high] {
                let traits = UITraitCollection { traits in
                    traits.userInterfaceStyle = style
                    traits.accessibilityContrast = contrast
                }
                for (exported, native) in colors {
                    let actual = exported.resolvedColor(with: traits)
                    let expected = native.resolvedColor(with: traits)
                    XCTAssertEqual(actual.cgColor, expected.cgColor)
                }
            }
        }
    }

    func testCanvasActuallyChangesBetweenLightAndDark() {
        let native = RhineColor.canvas
        let light = native.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = native.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        XCTAssertNotEqual(light.cgColor, dark.cgColor)
    }

    func testAccentResolvesInheritedTintAtTimeOfUse() {
        let parent = UIView()
        let child = UIView()
        parent.addSubview(child)
        parent.tintColor = .systemGreen
        XCTAssertEqual(RhineColor.accent(in: child), parent.tintColor)
        parent.tintColor = .systemPurple
        XCTAssertEqual(RhineColor.accent(in: child), parent.tintColor)
    }

    func testTextRolesScaleUsingTheConsumersTraits() {
        let standard = UITraitCollection(preferredContentSizeCategory: .large)
        let accessible = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        for role in RhineTypography.Role.allCases {
            XCTAssertGreaterThan(RhineTypography.font(role, compatibleWith: accessible).pointSize,
                                 RhineTypography.font(role, compatibleWith: standard).pointSize)
        }
    }
}
