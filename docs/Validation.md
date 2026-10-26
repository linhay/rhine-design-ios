# 验收计划与结果

> 当前主框架为 **UIKit**，依据[用户明确纠正](https://github.com/linhay/rhine-design/issues/34#issuecomment-6419860390)（2026-10-26）。此前 SwiftUI 主方案及其控件映射已被取代；SwiftUI 只可作为未来另行评估的可选消费适配，不是首批依赖。

确认依据：[方案 v1](https://github.com/linhay/rhine-design/issues/34#issuecomment-6410947901) 与 [维护者确认](https://github.com/linhay/rhine-design/issues/34#issuecomment-6410983498)，2026-10-26。设计规则已确认；实现和运行验收状态另见 [Validation](Validation.md)。

## 当前状态

UIKit规范按用户纠正更新；UIKit候选原生构建、运行和组件验收须重新记录。旧SwiftUI候选结果不可当作UIKit通过。目标最低系统 17.0 不等于已经验证支持。

## 已确认矩阵

| 编号 | 覆盖与预期 |
| --- | --- |
| P01 平台 | 在 iOS 17.0、iPadOS 17.0 与 iOS/iPadOS 27.1 上分别构建并运行同一公开 Package 样例；固定 Xcode 27.1。每一端均记录实际 runtime 版本，不用27.1通过替代17.0证据。旧 runtime 获取困难记为阻塞，不能静默抬高下限或冒称验证完成。 |
| A01 布局 | 每个平台在默认 UIContentSizeCategory.large 字号运行核心场景；最新系统补 UIContentSizeCategory.extraExtraExtraLarge、UIContentSizeCategory.accessibilityExtraLarge、UIContentSizeCategory.accessibilityExtraExtraExtraLarge。iPhone 375pt窄屏与常规宽屏、横竖屏；iPad全屏横竖屏和实际可用最窄多任务窗口，另以320pt内容容器测窄布局。记录实际point尺寸，不把容器测试当设备验证。长中英文、长错误、键盘出现均可阅读/操作。 |
| 外观 | 最低与较新系统均浅/深色、标准对比度；较新系统补浅/深色 × 提高对比度，并开关减少透明度核对内容可读，大字体 + 窄容器 + 深色组合。动态文本颜色不丢失，错误不只靠颜色，关键动作可识别；若使用自定义 accent，完整补同矩阵。 |
| B01/B02 | 合成任务手动触发完成与失败；忙碌期间快速重复点击/辅助激活不重复调用，禁用零调用；破坏性role与名称可理解，无通用强制确认。回调计数证据与实际触屏证据分别记录。 |
| F01/F02 | 空必填、错误格式、修正重提、长错误、失败后草稿保留；Next/Done、离散选择草稿、键盘遮挡、脏草稿继续/放弃、成功关闭与归焦。合成规则不变成库内业务规则；提交期间不重复保存、不退出丢草稿。 |
| E01 | 独立注入无内容、无匹配、加载、失败、权限不足，用户能区分，动作在样例真实执行下一步；不要求后3种成为空状态组件模式。 |
| A02 | 至少在一台受支持的较新系统真机上手动进行 VoiceOver 导航、标签/值/错误理解、禁用/忙碌激活、表单退出归焦；同时验证实际触屏与键盘；iPhone/iPad 的布局及焦点场景均需覆盖，未实测的真机类别不宣称通过。记录OS与设备型号、步骤和结果。自动审计或模拟器不能替代这一真机证据。 |
| A03 | 较新系统分别开启/关闭 Reduce Motion 实际操作忙碌/完成/失败与草稿退出；静态状态始终可理解，录屏或逐步交互记录说明动画变化。不能仅凭截图宣称动效通过。 |

验证采用有界组合，不宣称全设备/全字号笛卡尔积通过；实际发现边界失败时增加对应回归。#35 验证包消费、tokens与环境读取；#36 执行完整组件BDD。每项证据记录公开修订、产品/模块、工具链、OS、通用设备型号/容器尺寸、合成场景、预期/实际以及通过/失败/未验证/不适用。未执行的必需检查保持未验证，不能关闭相应实施issue。

## 公开证据

只使用合成数据；日志、截图、录屏和附件内容及元数据分别脱敏。记录工具链、OS、通用型号、尺寸、相对路径与公开修订；不包含凭据、内部地址、本机路径、设备标识或私人消费工程信息。

## 历史记录：已被替代的 SwiftUI 候选

此前6811f67及文档8bae4e6使用SwiftUI；其3种模拟器环境各3项测试和干净归档复验只属于该旧候选，**不计入UIKit当前验收**。完整历史记录可在[旧修订](https://github.com/linhay/rhine-design-ios/blob/8bae4e6/docs/Validation.md)查看。UIKit候选结果在下文另行记录。

## UIKit 当前候选结果 · 2026-10-26

绑定实现修订 [fded02a](https://github.com/linhay/rhine-design-ios/commit/fded02a)；后续仅补文档和主线说明。Swift Package、样例和测试源码没有 SwiftUI 导入或 UIHostingController：公开 UIColor/UIFont、UIView.tintColor继承、UIViewController + UIScrollView/UIStackView + Auto Layout，UIKit trait/UIAccessibility变化读取。固定 Xcode27.1 / Swift6.4编译器 / Swift6模式。

| 实际检查 | 结果 | 范围与限制 |
| --- | --- | --- |
| iPhone SE（第3代）/ iOS27.0 | UIKit build/install/launch成功，5项原生测试通过 | 375pt竖屏、浅色标准字号截图本地实看；不代表完整字号/外观矩阵通过。 |
| iPad（A16）/ iPadOS27.0 首次 | 4项单元测试通过，1项UI测试失败 | 初始标题在10秒内未找到，后续也无ScrollView；保留失败，不将其改写为通过。 |
| iPad（A16）/ iPadOS27.0 复查 | 显式boot/install/launch后UIKit界面可见；重测5项通过 | UI测试将启动等待调整为30秒，并在未显示首屏时立即失败，避免级联滚动错误。尚未确定首次失败根因；不声称修复了已定位的产品缺陷。 |
| 干净源码归档 / iPhone SE / iOS27.0 | 将fded02a用git archive导出、新建DerivedData，5项测试通过 | 相对Package消费链路可独立构建；无复制工作区实现或挪用旧SwiftUI结果。 |
| 干净归档 / iPhone Duo / iOS27.1 | **未完成**：工具调用300秒超时 | 遗留的本任务测试进程已终止；无最终成功结果，不计为通过。 |
| iOS/iPadOS17.0、iPadOS27.1 | **未验证，仍阻塞#35完成** | 缺少可用目标运行环境的既有问题仍在，不能由27.0结果代替。 |
| 剩余窗口/字号/外观/动态偏好、真机VoiceOver | 未完成 | 逐项按已确认矩阵补证，#36继续等待必要前置。 |

5项测试为：`testPublicColorsRetainNativeTraitAdaptation`（6颜色×4trait组合）、`testCanvasActuallyChangesBetweenLightAndDark`、`testAccentResolvesInheritedTintAtTimeOfUse`（宿主tint改变后重新解析）、`testTextRolesScaleUsingTheConsumersTraits`（4角色从Large到最大辅助字号）及 `testUIKitGalleryShowsContentAndScrollsToEnd`（标题、末项可命中、标签存在）。UI测试不证明全局无裁切/重叠或真实VoiceOver可用。

只公开脱敏文字摘要；原始工具日志、截图、xcresult及设备标识不上传。没有发布、没有合并基础候选，也没有开始#36组件实现。
