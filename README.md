# Rhine Design for iOS

> 当前主框架为 **UIKit**，依据[用户明确纠正](https://github.com/linhay/rhine-design/issues/34#issuecomment-6419860390)（2026-10-26）。此前 SwiftUI 主方案及其控件映射已被取代；SwiftUI 只可作为未来另行评估的可选消费适配，不是首批依赖。

独立的 UIKit 设计体系与原生组件库。规范、tokens、样例、版本和验收均独立于 [Rhine Design Web](https://github.com/linhay/rhine-design)。

## 状态

当前 `main` 仅包含已确认规范。基础包和可运行工程位于 [UIKit Draft PR #1](https://github.com/linhay/rhine-design-ios/pull/1)，尚未合入主线；基础 API 与工程属于该候选；新增组件和完整展台位于下述 gallery 分支。

设计基线已确认，原生基础链路已有候选实现；尚未发布。目标 iOS / iPadOS 17.0，固定 Xcode 27.1、Swift 6.4 编译器和 Swift 6 语言模式。目标兼容范围不等于运行验证通过，详见验收记录。

## 完整展示 App

打开 `Examples/RhineExample.xcodeproj` 的 `RhineExample` scheme，默认进入 **Rhine Gallery**：总览、按钮、表单、内容状态四个分区。可实际操作模拟成功/失败、校验与草稿退出、空状态恢复；右上角可预览外观、字号与窄内容，并恢复系统设置。使用说明及复现入口见 [Examples/README.md](Examples/README.md)。

完整展示候选位于 `codex/ios-component-gallery`，从基础候选 `7baf4db` 接续；用户最新要求已允许推进 #36 样例与首批组件。基础候选 PR #1 的未完成环境验收继续单独记录，不因展台实现自动关闭。

## 规范

候选组合配方：从总览进入 **Agent 会话 · 合成配方**，体验正文/工具混排、流式阅读位置、未确认草稿与一次性授权。见 [组合契约](docs/AgentSession.md)；此入口没有真实网络或新增公开 API，依赖仍未发布的 gallery 候选。

- [UIKit 设计体系导航](docs/README.md)：平台决定、变量、组件、样例与验证的工作入口。
- [设计规范与平台决定](docs/DesignSystem.md)
- [独立语义 tokens](docs/Tokens.md)
- [首批组件契约](docs/Components.md)
- [验收计划与结果](docs/Validation.md)
- [版本记录](CHANGELOG.md)

## 任务入口

当前仍以原仓库的 [#34 设计决定](https://github.com/linhay/rhine-design/issues/34)、[#35 原生包与样例](https://github.com/linhay/rhine-design/issues/35)、[#36 组件与原生验收](https://github.com/linhay/rhine-design/issues/36) 为唯一权威任务，不重复建单。范围变化先记录到对应 issue。

首批候选提供按钮、单行文本、安全输入、开关、静态单选和空状态。请求、校验规则、草稿与业务状态由宿主管理，不迁移消费应用。

## 本地构建与消费

使用 Xcode 27.1 打开 `Examples/RhineExample.xcodeproj`，选择 `RhineExample` scheme 和已安装的 iOS Simulator。工程已提交，不要求安装工程生成工具。只有修改 `Examples/project.yml` 后才需使用 XcodeGen 2.46.0 重新生成：

```sh
xcodegen generate --spec Examples/project.yml
```

样例通过本地 Package reference 和公开 `RhineDesign` 产品消费，源码只包含 `import RhineDesign`，没有复制组件源文件。命令行检查示例（需要对应型号和运行时已安装）：

```sh
xcodebuild -project Examples/RhineExample.xcodeproj -scheme RhineExample \
  -destination 'platform=iOS Simulator,name=iPhone Duo,OS=27.1' \
  -derivedDataPath .local/DerivedData -parallel-testing-enabled NO \
  -resultBundlePath .local/Validation.xcresult test
```

结果路径每次使用新的名称，保留完整 xcresult；一次只指定一个 destination。验收测试回读实际外观、字号与窗口尺寸，并同时保留 app 与 display 截图；断言通过不代替视觉审阅。

在样例 scheme 的启动参数同时加入 `--foundation-diagnostics` 与 `--preview-narrow-content` 可将真实内容容器上限设为 320pt；默认仍为 720pt。该预览只约束内容布局，不覆盖系统字号或外观，也不代替 iPad 多任务窗口验收。

公开入口：`RhineColor`、`RhineTypography`、`RhineSpacing`、`RhineTarget`、`RhineButton`、`RhineTextField`、`RhineToggle`、`RhineChoice`、`RhineEmptyState`。例如：

```swift
import UIKit
import RhineDesign

let label = UILabel()
label.text = "Synthetic example"
label.font = RhineTypography.font(.body, compatibleWith: label.traitCollection)
label.adjustsFontForContentSizeCategory = true
label.numberOfLines = 0
label.textColor = RhineColor.textPrimary
```

`RhineColor.accent(in:)` 读取视图继承的 tintColor；宿主设置 UIView.tintColor 并验证对比度。样例通过 UIKit traitCollection 与 UIAccessibility 读取外观、字号及动态偏好，并响应变化；本阶段没有自定义动画或外部资源，不创建空资源包。

本包是 iOS UI 产品，不能用 macOS 上通用 `swift build` 代替 iOS 构建验收。样例默认禁用签名，面向 Simulator；真机运行时由维护者本地配置自己的签名，不提交账号、团队配置或签名材料。不要直接公开原始构建日志或 xcresult，它们可能含本机路径和设备标识。

## 贡献与隐私

仅使用合成数据和可公开引用的资料。提交前检查正文、命令、日志、截图、录屏、附件及其元数据；禁止凭据、内部地址、私人仓库信息、绝对本机路径、设备名称/序列号/UDID 和真实用户内容。保留公开修订、工具链、系统、通用设备型号及相对路径以便复现。

Git 提交使用维护者明确指定并授权公开的邮箱，不强制改为 GitHub noreply；提交前核对作者与提交者身份，保留既有提交历史。

代码、规范和运行证据分别记录；未验证不能记为通过。任何发布均需单独记录制品与消费验收，不能随 Web/npm 自动发布。
