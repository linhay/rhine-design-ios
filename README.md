# Rhine Design for iOS

> 当前主框架为 **UIKit**，依据[用户明确纠正](https://github.com/linhay/rhine-design/issues/34#issuecomment-6419860390)（2026-10-26）。此前 SwiftUI 主方案及其控件映射已被取代；SwiftUI 只可作为未来另行评估的可选消费适配，不是首批依赖。

独立的 UIKit 设计体系与原生组件库。规范、tokens、样例、版本和验收均独立于 [Rhine Design Web](https://github.com/linhay/rhine-design)。

## 状态

当前 `main` 仅包含已确认规范。基础包和可运行工程位于 [UIKit Draft PR #1](https://github.com/linhay/rhine-design-ios/pull/1)，尚未合入主线；候选 API 与构建步骤应在该 PR 的分支查看。

设计基线已确认，原生基础链路正在建设；尚未发布。目标 iOS / iPadOS 17.0，固定 Xcode 27.1、Swift 6.4 编译器和 Swift 6 语言模式。目标兼容范围不等于运行验证通过，详见验收记录。

## 规范

- [设计规范与平台决定](docs/DesignSystem.md)
- [独立语义 tokens](docs/Tokens.md)
- [首批组件契约](docs/Components.md)
- [验收计划与结果](docs/Validation.md)
- [版本记录](CHANGELOG.md)

## 任务入口

当前仍以原仓库的 [#34 设计决定](https://github.com/linhay/rhine-design/issues/34)、[#35 原生包与样例](https://github.com/linhay/rhine-design/issues/35)、[#36 组件与原生验收](https://github.com/linhay/rhine-design/issues/36) 为唯一权威任务，不重复建单。范围变化先记录到对应 issue。

首批计划为按钮、单行文本、安全输入、开关、静态单选和空状态。请求、校验规则、草稿与业务状态由宿主管理，不迁移消费应用。

## 贡献与隐私

仅使用合成数据和可公开引用的资料。提交前检查正文、命令、日志、截图、录屏、附件及其元数据；禁止凭据、内部地址、私人仓库信息、绝对本机路径、设备名称/序列号/UDID 和真实用户内容。保留公开修订、工具链、系统、通用设备型号及相对路径以便复现。

代码、规范和运行证据分别记录；未验证不能记为通过。任何发布均需单独记录制品与消费验收，不能随 Web/npm 自动发布。
