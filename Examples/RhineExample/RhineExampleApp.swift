import SwiftUI
import RhineDesign

@main
struct RhineExampleApp: App {
    var body: some Scene {
        WindowGroup { FoundationGallery() }
    }
}

private struct FoundationGallery: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: RhineSpacing.group) {
                    Text("Independent iOS foundations")
                        .font(RhineTypography.title)
                    Text("Synthetic content only. This app consumes the public RhineDesign package; first-batch components are tracked separately.")
                        .font(RhineTypography.body)

                    GroupBox("System environment") {
                        VStack(alignment: .leading, spacing: RhineSpacing.related) {
                            environmentRow("Appearance", value: colorScheme == .dark ? "Dark" : "Light")
                            environmentRow("Contrast", value: contrast == .increased ? "Increased" : "Standard")
                            environmentRow("Dynamic Type", value: String(describing: typeSize))
                            environmentRow("Reduce Motion", value: reduceMotion ? "On" : "Off")
                            environmentRow("Reduce Transparency", value: reduceTransparency ? "On" : "Off")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GroupBox("Semantic colors") {
                        VStack(alignment: .leading, spacing: RhineSpacing.related) {
                            Text("Primary text").foregroundStyle(RhineColor.textPrimary)
                            Text("Secondary text").foregroundStyle(RhineColor.textSecondary)
                            Text("Host accent").foregroundStyle(RhineColor.accent)
                            Text("Error: synthetic example; no operation failed.")
                                .foregroundStyle(RhineColor.error)
                            Rectangle().fill(RhineColor.separator).frame(height: 1)
                            Text("Canvas surface")
                                .padding(RhineSpacing.related)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RhineColor.canvas)
                            Text("Grouped surface")
                                .padding(RhineSpacing.related)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RhineColor.group)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GroupBox("Typography") {
                        VStack(alignment: .leading, spacing: RhineSpacing.related) {
                            Text("Title · 系统标题").font(RhineTypography.title)
                            Text("Body · 示例内容在较大辅助字号下自然换行，保留完整信息和可滚动的阅读路径。 Long synthetic content wraps without reducing the text size.")
                                .font(RhineTypography.body)
                            Text("Label · 持久标签").font(RhineTypography.label)
                            Text("Supporting · 合成说明").font(RhineTypography.supporting)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text("No custom animation is added. System accessibility preferences above are read live.")
                        .font(RhineTypography.supporting)
                        .foregroundStyle(RhineColor.textSecondary)
                }
                .padding(RhineSpacing.page)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(RhineColor.canvas)
            .foregroundStyle(RhineColor.textPrimary)
            .navigationTitle("Rhine Foundation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func environmentRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: RhineSpacing.inline) {
            Text(label).font(RhineTypography.label)
            Text(value)
                .font(RhineTypography.supporting)
                .foregroundStyle(RhineColor.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}
