# 独立 iOS 设计规范

> 当前主框架为 **UIKit**，依据[用户明确纠正](https://github.com/linhay/rhine-design/issues/34#issuecomment-6419860390)（2026-10-26）。此前 SwiftUI 主方案及其控件映射已被取代；SwiftUI 只可作为未来另行评估的可选消费适配，不是首批依赖。

确认依据：[方案 v1](https://github.com/linhay/rhine-design/issues/34#issuecomment-6410947901) 与 [维护者确认](https://github.com/linhay/rhine-design/issues/34#issuecomment-6410983498)，2026-10-26。设计规则已确认；实现和运行验收状态另见 [Validation](Validation.md)。

iOS 的规范、tokens、原生实现、样例、版本和验收独立于 Web/React。共同品牌仅为可选参考；不共享 CSS 真源，不转换 Web 数值，不绑定 npm 发布。

| ID | 已确认方案 | 原因与影响 |
| --- | --- | --- |
| D01 归属 | 使用独立公开仓库 `linhay/rhine-design-ios`，规范与源码同仓 | 平台和版本边界清楚；代价是独立 CI、维护与发布。原生代码放回 Web 仓库虽少一个仓库，但独立演进不够直观，不作为首选。 |
| D02 包与框架 | UIKit；一个 Swift Package、一个 library product/module `RhineDesign`；`Sources/RhineDesign/`、`Tests/RhineDesignTests/`，`Examples/` 为单独 Xcode 样例 App，通过公开产品导入 | 公开组件与样例以 UIKit 原生实现为主；公开 UIColor / UIFont 等 UIKit 类型，Auto Layout 布局。不依赖 SwiftUI 或以其包装作为核心。UI Kit 设计资源仍不等于 UIKit 运行库。 |
| D03 平台 | 最低 iOS / iPadOS **17.0**；首批覆盖 iPhone / iPad，随容器适配；不承诺 macOS、Catalyst、watchOS、tvOS、visionOS | 使用 iOS 17 系统空状态能力，减少自绘与兼容分支；不支持 16 及更早系统是明确代价。新设备专属 API 不进入首批，尺寸适配不等于已验证所有机型。 |
| D04 构建 | 固定 **Xcode 27.1 / iOS 27.1 SDK / Swift 6.4 编译器 / Swift 6 语言模式**；manifest `swift-tools-version: 6.0`，不使用高于此 manifest 门槛的特性 | 固定可复现工具链，采用 Swift 6 并发检查；tools-version 是 manifest 门槛，不代表已验证旧 Xcode。当前只承诺固定工具链；若希望支持旧 Xcode，另补具体编译矩阵。运行系统下限与编译器/SDK分别记录。 |
| D05 外观 | 单一系统原生主题；跟随浅色/深色、提高对比度、Dynamic Type、减少动态；默认系统 tint，允许宿主注入可访问的语义 accent | 不复制 Web 多主题、字体、材质或圆角；不锁定某一代系统的截图外观，不自绘模仿新系统材质。宿主覆盖 accent 也需通过对比度验收。 |
| D06 Tokens | 使用 [Tokens](Tokens.md) 最小语义集合；系统控件内部尺寸、字形和动效交给系统；自定义值仅用于组件组合 | 独立维护，避免不必要的全量 token 层；数值是本库已确认项目规则，不冒称 Apple 强制规范。 |
| D07 组件 | [Components](Components.md) 中的按钮、四种基础字段和空状态契约 | 小范围可交付；请求、校验规则、数据、路由、权限和草稿生命周期由宿主拥有。 |
| D08 版本 | 首个交付版本目标为 **0.1.0**；独立 CHANGELOG 与 tag，0.x 破坏性公开 API 变更升 minor，兼容修复升 patch，记录迁移说明 | 不与 npm 版本或 Web 发布联动；本项以及 #35/#36 不自动触发发布，发布前单独明确制品和验收范围。 |
| D09 职责与承接 | 当前维护侧负责 #34 整合，原生资料侧负责设计审阅，维护者负责最终范围确认；#35/#36 开工时明确实施与验收负责人 | 当前 issues 保留为权威入口。独立仓库就绪后记录双向链接与唯一承接位置，再决定迁移；不在两处维持相互冲突的任务。 |

规范入口：`docs/DesignSystem.md`、`docs/Tokens.md`、`docs/Components.md`、`docs/Validation.md`；README 链接这些入口。本仓库规范与原 issue 共同保留决定依据；任务以原 issue 为权威入口。

## 平台依据

- [Apple Xcode 系统要求](https://developer.apple.com/xcode/system-requirements)：2026-10-26 核对，Xcode27.1条目列出iOS27.1 SDK、Swift6.4编译器、Swift6语言模式，设备/模拟器支持iOS17及以后；27.2标为RC。**选择27.1是本方案判断**，并非Apple要求所有库使用此版本。
- [UIContentUnavailableConfiguration](https://developer.apple.com/documentation/uikit/uicontentunavailableconfiguration-swift.struct)：iOS/iPadOS17起可用。**以17为最低系统是减少兼容分支的项目取舍**，不由参考图版本或消费应用设置推导。任何更高版本API须显式availability分支和17基线回退。
- 原生设计依据：[Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons)、[Text fields](https://developer.apple.com/design/human-interface-guidelines/text-fields)、[Typography](https://developer.apple.com/design/human-interface-guidelines/typography)、[Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)。本规范具体组件范围、间距、状态责任与矩阵为已确认的项目规则，不是Apple原文或已通过的运行结果。

本规范采用纯文字，不新增截图/录屏/附件，不复制私人消费源码或配置。实施阶段的图片、日志与元数据仍需逐项检查；已有研究外链可访问不等于完成全部媒体审计。
