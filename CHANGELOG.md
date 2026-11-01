# Changelog

## Unreleased — 0.1.0 target

- Add the UIKit component gallery with four navigable sections, appearance/type/content-width previews, and deterministic button, form and content-state interactions.
- Add public RhineButton, RhineTextField, RhineToggle, RhineChoice and RhineEmptyState candidates; the example owns validation, save outcomes and draft lifecycle. Preserve the standalone foundation diagnostic entry.
- User-requested full gallery work proceeds independently from remaining foundation runtime validation; implementation is not a completed release or platform acceptance.

- Correct the primary framework to UIKit following the maintainer's explicit direction; the former SwiftUI-first proposal is superseded.

- Confirm independent iOS design rules, platform baseline, semantic tokens and first component contracts in [#34](https://github.com/linhay/rhine-design/issues/34).
- Replace the candidate’s SwiftUI API and app with UIKit UIColor/UIFont APIs, inherited view tint, and an Auto Layout UIViewController example; prior SwiftUI test evidence is historical.
- Add native semantic colors, text styles, composition spacing and minimum custom hit-target size in a single Swift Package, plus a synthetic iPhone/iPad example consuming its public product ([#35](https://github.com/linhay/rhine-design/issues/35)).
- Add native color trait tests and a Simulator UI consumption/scrolling check. Minimum-system and full accessibility validation remain incomplete.
- No package version has been published. Native implementation and validation are tracked separately.

## Version policy

iOS versions are independent of Web/npm. During 0.x, breaking public API changes increment the minor version; compatible fixes increment the patch version. Record migration instructions for breaking changes. A target version is not a published tag or release.
