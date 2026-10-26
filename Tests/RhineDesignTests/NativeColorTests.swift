import XCTest
import SwiftUI
import UIKit
import RhineDesign

@MainActor
final class NativeColorTests: XCTestCase {
    func testPublicColorsRetainNativeTraitAdaptation() {
        let colors: [(Color, UIColor)] = [
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
                    let actual = UIColor(exported).resolvedColor(with: traits)
                    let expected = native.resolvedColor(with: traits)
                    XCTAssertEqual(actual.cgColor, expected.cgColor)
                }
            }
        }
    }

    func testCanvasActuallyChangesBetweenLightAndDark() {
        let native = UIColor(RhineColor.canvas)
        let light = native.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = native.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        XCTAssertNotEqual(light.cgColor, dark.cgColor)
    }
}
