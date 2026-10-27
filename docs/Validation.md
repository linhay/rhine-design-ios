# 验收计划与结果

> 当前主框架为 **UIKit**，依据[用户明确纠正](https://github.com/linhay/rhine-design/issues/34#issuecomment-6419860390)（2026-10-26）。此前 SwiftUI 主方案及其控件映射已被取代；SwiftUI 只可作为未来另行评估的可选消费适配，不是首批依赖。

确认依据：[方案 v1](https://github.com/linhay/rhine-design/issues/34#issuecomment-6410947901) 与 [维护者确认](https://github.com/linhay/rhine-design/issues/34#issuecomment-6410983498)，2026-10-26。设计规则已确认；实现和运行验收状态另见 [Validation](Validation.md)。

## 当前状态

UIKit 基础候选已有原生构建、公开包消费和局部 UI 证据；完整组件展台见 [PR #2](https://github.com/linhay/rhine-design-ios/pull/2) 及文末增量记录；最低系统、完整环境矩阵与真机验收仍未完成。旧 SwiftUI 候选结果不可当作 UIKit 通过。目标最低系统 17.0 不等于已经验证支持。

## 运行矩阵事实更正 · 2026-10-27

本节取代历史记录中将 `iOS/iPadOS 27.1` 视为统一设备矩阵的条目。[Apple Xcode 27.1 发布说明](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes) 列出 iOS 27.1、iPadOS 27 SDK；[Apple 的 Duo 说明](https://developer.apple.com/news/?id=rfb1rooi) 明确 27.1 为 Duo 形态提供专属支持。[系统发布记录](https://support.apple.com/en-by/100100) 也将 iOS 27.1 限定为 iPhone Duo，并另列 iPadOS 27.0.1 与后续 27.2，不能声称存在通用 iPadOS 27.1。

固定 Xcode 27.1 / Swift 6.4 / Swift 6 不变；当前固定工具链的较新系统模拟器矩阵为 Duo / iOS 27.1、普通 iPhone 与 iPad / 27.0，逐项记实际版本。27.0 模拟器不冒称 27.0.1 或 27.2 真机，也不称为当前最新系统。最低 iOS/iPadOS 17.0、iPhone/iPad 类别、窗口/方向/字号/外观/动态偏好与真机人工验收维度不变。未来工具链与系统升级另记录；本次更正不抬高下限、不消除未执行的检查。

## 已确认矩阵

| 编号 | 覆盖与预期 |
| --- | --- |
| P01 平台 | 在 iOS 17.0、iPadOS 17.0，以及固定工具链下 Duo / iOS 27.1、普通 iPhone 与 iPad / 27.0 上分别构建并运行同一公开 Package 样例；固定 Xcode 27.1。每一端均记录实际 runtime 版本，不用较新系统通过替代17.0证据。旧 runtime 获取困难记为阻塞，不能静默抬高下限或冒称验证完成。 |
| A01 布局 | 每个平台在默认 UIContentSizeCategory.large 字号运行核心场景；固定工具链较新系统补 UIContentSizeCategory.extraExtraExtraLarge、UIContentSizeCategory.accessibilityExtraLarge、UIContentSizeCategory.accessibilityExtraExtraExtraLarge。iPhone 375pt窄屏与常规宽屏、横竖屏；iPad全屏横竖屏和实际可用最窄多任务窗口，另以320pt内容容器测窄布局。记录实际point尺寸，不把容器测试当设备验证。长中英文、长错误、键盘出现均可阅读/操作。 |
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
| 历史 iOS/iPadOS17.0、iPadOS27.1 缺口 | 当时未验证 | 17.0 仍待验证；iPadOS27.1 的错误组合由上方 2026-10-27 事实更正取代，旧记录保留时点。 |
| 剩余窗口/字号/外观/动态偏好、真机VoiceOver | 未完成 | 逐项按已确认矩阵补证，#36继续等待必要前置。 |

5项测试为：`testPublicColorsRetainNativeTraitAdaptation`（6颜色×4trait组合）、`testCanvasActuallyChangesBetweenLightAndDark`、`testAccentResolvesInheritedTintAtTimeOfUse`（宿主tint改变后重新解析）、`testTextRolesScaleUsingTheConsumersTraits`（4角色从Large到最大辅助字号）及 `testUIKitGalleryShowsContentAndScrollsToEnd`（标题、末项可命中、标签存在）。UI测试不证明全局无裁切/重叠或真实VoiceOver可用。

只公开脱敏文字摘要；原始工具日志、截图、xcresult及设备标识不上传。没有发布、没有合并基础候选，也没有开始#36组件实现。


## UIKit 验收增量 · 2026-10-27

公开基线为 [21d17a3](https://github.com/linhay/rhine-design-ios/commit/21d17a3b9a6f67881d4966ccb3772dde43070261)，本轮新增 UI 验收用例与记录，公开产品和样例实现未改。工具链仍为 Xcode 27.1 / Swift 6.4 / Swift 6 模式。原始结果、源码差异及制品摘要保留在被忽略的 `.local/validation-20261027/`。各轮测试源码通过 SHA-256 清单绑定；后续测试补充不回溯改变旧运行的覆盖范围。

| 检查 | 状态 | 证据边界 |
| --- | --- | --- |
| 当前工作区 / iPhone Duo / iOS 27.1 / 原有 5 项测试 | PASS | 新 DerivedData 构建和测试成功，4 项 tokens 单元测试与 1 项滚动消费测试通过。 |
| 21d17a3 干净源码归档 / iPhone Duo / iOS 27.1 | PASS | `git archive` 独立导出并使用另一 DerivedData，5 项通过。补齐本修订的干净包消费证据；2026-10-26 的超时仍保留，根因未确认。 |
| Duo / 27.1 浅深外观实时切换、默认字号旋转 | FAIL | 两次检查均未通过：请求 Dark 后仍显示 Light；设备报告横屏而窗口仍为 466×678pt。截图也保留浅色竖屏。当前仅确认环境中的现象，尚不能归因为 UIKit tokens 或样例实现缺陷。 |
| SE（第3代）/ 27.0 对照检查 | PASS（断言） | 相同初版测试的 2 项通过；浅/深切换不重启，375×667 与 667×375pt，末项可命中、长文横向边界检查通过。深色首屏截图已实看；横屏截图与报告窗口比例不一致，**完整视觉验收仍未通过**。 |

补收完整结果：

| 检查 | 状态 | 证据边界 |
| --- | --- | --- |
| Duo / 27.1 四档竖屏字号 | PASS（4 项断言） | `portrait-fonts27_1.xcresult` 完整收尾，0 失败/0 跳过；实际 trait 回读与滚动可达性通过。最大辅助字号首屏及末项截图已审阅，所见内容自然换行；不外推整页逐行视觉通过。 |
| iPad A16 / 27.0 单设备 UI | FAIL（6 通过/1 失败） | `ipad-ui27_0.xcresult` 完整收尾。四档字号、默认字号旋转和滚动消费通过；外观切换请求 Dark 后仍读到 Light。窗口为 820×1180 / 1180×820pt；横屏截图异常仍保留，不计完整视觉通过。 |
| Duo 系统命令外观与 Device Hub 旋转 | PASS（有界交叉检查） | 同一公开样例进程中，系统外观改为深色后显示 Dark，Device Hub 旋转后主屏截图为 2034×1398 像素且正文重新排版。没有覆盖 app traits、修改产品代码或以重启代替实时响应；这不消除 XCTest 路径失败，也未确认其根因。 |

Duo 存在多个显示面。`simctl io` 不指定显示面时本次选到 LCD-1，产生黑屏；使用 `--display=primary` 可得到样例所在屏幕。截图必须核对显示面与稳定后的实际内容；首次紧随外观命令采集到旧状态，后续已稳定截图才显示 Dark。旧黑屏和首次截图保留，不作为产品失败或通过证据。

双设备整套运行的控制台在后期才刷新用例结果：SE / 27.0 的 11 项（4 单元 + 7 UI）全部通过，iPad / 27.0 的 4 单元与最大辅助字号 UI 检查通过。执行者误将延迟输出判断为启动停滞，约 5 分钟时中断，结果包未完整收尾；该次只能引用已输出的用例结果，不能声明整套 PASS，也不能把中断归为产品失败。后续改为单设备运行保留完整结果。

新增回归将四档字号（Large、XXXL、Accessibility XL、Accessibility XXXL）竖屏检查与旋转检查分开；字号启动参数必须由样例实际 UIKit trait 回读确认。测试检查末项可滚动到达、正文存在及正文/末项横向边界，并保留首屏与末项截图。它不证明所有文字无裁切、重叠，不能替代视觉审阅、实际系统设置切换或 VoiceOver。

### 剩余缺口与处理顺序

1. **最低系统阻塞**：可用模拟器中未发现 iOS/iPadOS 17.0；按官方路径执行 `xcodebuild -downloadPlatform iOS -buildVersion 17.0` 返回该版本不可下载（exit 70）。最低 17.0 声明与待验收状态保留。iPadOS27.1 不再列作待下载环境：它是已更正的平台组合错误，当前 iPad 按真实 27.0 simulator 继续验收。
2. **Duo 动态环境异常**：定位外观/旋转请求与实际 app 状态不一致；同时核对横屏截图采集异常。未定位前保留失败，不通过强制覆盖样例 traits 让系统切换测试变绿。
3. **本地矩阵待补**：大字号横屏、iPad 实际最窄多任务窗口、独立 320pt 内容容器；浅/深 × 提高对比度、减少透明度、实际 Reduce Motion 开关的读取与变化。颜色 trait 单元测试不替代这些真实环境检查。
4. **真机与人工验收**：设备清单存在已配对的较新系统 iPhone，但未发现 17.0 或 iPad 真机；配对/连接不等于已安装本候选或完成验收。VoiceOver 阅读顺序/语义和真实触控仍未验证，模拟器与自动测试不能替代。
5. **范围边界**：按钮/表单/空状态、键盘与提交/退出交互属于 #36，本轮 #35 基础样例没有这些组件，记为本轮 N/A；没有据此宣称完整组件矩阵通过。

PR #1 仍为 Draft；CodeRabbit 的成功状态对应跳过 Draft 审查，不算原生 CI 或人工审阅通过。本轮不关闭 #35，不开始 #36，不合并、发布或升级消费方。

### 2026-10-27 窄窗口回归补充

本轮把窄内容预览固定为真实 `320pt` 外层容器，正文在 section 内的可用宽度为 `288pt`；SE / iOS 27.0 的最大辅助字号窄内容回归重跑为 1 项通过。iPad A16 / iPadOS 27.0 使用系统可见的窗口右下角拖拽句柄，保留实际约 `375×839pt` 窄窗口的首屏、滚动末项和页尾整屏截图，窗口用例重跑为 1 项通过。一次早期失败来自窗口移动后 XCTest 子元素与滚动容器采用不同坐标空间，已移除不稳定的跨空间 X 坐标断言，保留正文宽度、滚动可达性和独立整屏截图；该失败结果仍保留在本地证据目录，不改写为产品失败。

Duo / iOS 27.1 的系统命令交叉检查继续保留浅/深色、对比度和大字号稳定截图；XCTest 外观/旋转路径的失败现象仍未定位，不能据此宣称完整外观矩阵通过。新增窄容器与 iPad 系统窗口证据不覆盖最低 17.0、真机 VoiceOver 或 #36 组件行为。


## 完整 UIKit 展示项目 · 2026-10-27

本节取代上述历史记录中“未开始 #36 / 必须完全等待 #35”的现行顺序：用户明确要求完整可操作的样式示例并持续提交，完整展台从基础候选 `7baf4db` 接续。公开组件提交 `6e7946b`，展示与测试源码提交 `a6c9ba6`；基础诊断仍通过 `--foundation-diagnostics` 运行。未完成的系统与辅助技术验收继续保留。

Xcode 27.1 / Swift 6.4 / Swift 6 模式；全程使用合成资料。源码 SHA-256 清单、原始日志、结果包和截图位于忽略的 `.local/gallery-20261027/`，提交后的 Swift 源码与工程逐文件匹配运行时清单。

| 检查 | 结果 | 边界 |
| --- | --- | --- |
| SE 第3代 / iOS 27.0 / hosted-interactions | PASS：8 项单元 + 7 项 UI；xcodebuild exit 0，完整 xcresult | 按钮门禁、输入/错误保留、宿主静默赋值、菜单选中项；导航、预览重置、任务失败重试、表单校验/草稿放弃/失败保留/成功、键盘 Next/Done、真实开关与菜单、口令不进入已保存资料、空状态与搜索恢复、最大辅助字号动作可达。 |
| SE / 原无宿主 first-interactions | FAIL：1 项开关事件断言；6 项 UI 用例已输出通过 | 原始失败保留。单元测试改为在示例 App 中托管后，同一原生 sendActions 断言通过；未改控件回调来绕过断言。首次测试输出完用例后仍未收尾，由执行者中断，结果包不完整，不计整套通过。 |
| SE / 截图审阅 | 有界通过 | 已查看浅色总览、表单输入与菜单选中、深色按钮首屏，以及最大辅助字号的长按钮/状态动作截图。大字号截图在滚动过程中只覆盖局部；通过动作可达断言不代表整页逐行无裁切。深色由系统命令在同一进程切换后采集，App 预览另有独立 UI 测试。 |

iPad A16 / iPadOS 27.0 的分轮检查单独保留：

- 已有 375×486pt 窗口：基础诊断与展台导航通过；表单入口与长按钮定位失败（2 PASS / 2 FAIL，完整结果包）。滚动辅助原先只向下滑，可能越过目标；失败层级显示目标已在视口上方。改为向目标中心所在方向滚动，未据此回溯将原运行算通过。
- 独立全宽模拟器初轮：3 项启动断言失败（完整结果包）。实际截图已显示展台，系统日志表明 iPad 浮动标签被表示为 cell 而非 TabBar；测试启动锚点改为真正的内容滚动容器，导航选择兼容两种原生标签表示。
- 修正测试后的全宽检查：导航/预览与最大辅助字号长按钮、空状态动作通过；表单已输入文字，但屏幕键盘存在断言失败。保留截图与后续键盘复核，不将硬件输入自动当成屏幕键盘验收。该轮用例完成后结果包长时间未收尾，由执行者终止，只引用日志里的逐项结果。

复现测试使用 `RhineExample` scheme，选 `RhineDesignTests` 与 `RhineExampleUITests/GalleryInteractionTests`，单设备运行、关闭 parallel testing，保留独立 result bundle。单元测试配置 `TEST_HOST` 指向示例 App，确保原生控件事件在 UIKit 应用环境派发；Swift Package 继续保持单一公开产品。

尚未完成：最低 iOS/iPadOS 17.0、Duo 上新增组件全套、完整方向/窗口/对比度/动态偏好组合、真实 VoiceOver 阅读/激活/归焦。预览字号和模拟授权不是系统设置或真实权限证据。#35/#36 仍保持打开，候选不自动合并、不发布、不升级消费产品。


测试适配提交 `3ac7908` 在新的 DerivedData 中重跑 SE / iOS 27.0 的全部 7 项 Gallery UI 用例，**7 PASS / 0 FAIL / 0 SKIPPED，exit 0、完整 xcresult**。公共组件与 App 实现仍是 `a6c9ba6` 中的源码，之前 8 项单元测试的实现未改；新旧测试清单和最终 App 二进制摘要分别保存。它不覆盖上述 iPad 失败，也不将首次失败的根因统一解释为平台类型差异。

iPad 单独键盘复核在加入最多 5 秒等待后发现 Keyboard 元素，但真实屏幕只显示输入辅助区，随后 Next 输入的空闲等待停滞。元素存在不能证明屏幕键盘布局验收，相关失败/停滞保留，仍需继续排查。没有为了让测试通过修改 App 的键盘、设备 traits 或跳过断言。

## 软件键盘、系统偏好与窗口验收增量 · 2026-10-27

验收测试提交 `2d20292`。本轮公开组件与 App 实现仍为 `24a5213` 所含源码；只修正、扩充 UI 验收用例和复现说明，没有通过修改产品 traits、隐藏状态或跳过断言让测试通过。固定 Xcode 27.1 / Swift 6.4 / Swift 6，全部数据为合成输入。各轮测试源码清单、App / 测试二进制 SHA-256、日志、录屏和结果包保存在忽略的 `.local/acceptance-20261027/`；新增测试不追溯计入旧运行。

| 场景与证据名称 | 结果 | 实际覆盖 |
| --- | --- | --- |
| SE 第3代 / iOS 27.0 / `phone-light-standard` | PASS：8 Gallery + 1 系统读回，完整 xcresult、exit 0 | 浅色、标准对比度、减少动态/透明度关闭；全部原有交互及新增加载失败、权限说明恢复动作。 |
| iPad A16 / 27.0 / `ipad-dark-high-reduced` | Gallery 8 PASS；系统读回 1 FAIL | 深色、提高对比度、减少动态/透明度开启；系统断言错误地期待 `High`，实际标签为 `Increased`。保留失败，不当作产品故障。 |
| iPad / `ipad-dark-high-system`、`ipad-light-high`、`ipad-dark-standard`、`ipad-light-standard` | PASS：分别 1、2、3、2 项，均完整收尾 | 修正预期标签后逐项读回真实系统值；覆盖浅/深 × 标准/提高对比度，并在减少动态开启/关闭下操作任务成功/失败、草稿退出、键盘保存。各组合用例数量不同，不是完整笛卡尔积。 |
| iPad 全窗口 / `keyboard-native-return` | PASS：1 项，完整 xcresult | 点击软件键盘 Next/Done，以后续输入落入正确字段确认焦点移动，完成开关/选择、保存、重新打开与口令清空。后续用例进一步要求字母键和当前字段可命中。 |
| iPad 375×486pt 实际系统窗口 / `ipad-small-adaptive-drag` | PASS：2 项，完整 xcresult | 软件键盘完整保存流程，以及最大辅助字号长按钮与空状态恢复动作；全屏截图核对窗口、完整字母键盘与当前输入字段。它不替代大字号下所有字段和最小窗口的组合检查。 |
| Duo / iOS 27.1 / `duo-gallery` | PASS：8 Gallery，完整 xcresult | 新增组件的导航、任务、校验、退出、软件键盘、选择、保存、空状态及大字号动作。 |
| iPad / `ipad-large-keyboard`；Duo / `duo-expanded-large-keyboard` | PASS：各 1 项、每项 3 档字号，完整 xcresult | XXXL、Accessibility XL、Accessibility XXXL，实际 UIKit 字号读回；靠后 URL 字段输入保留、软件键盘字母键和字段可命中、保存入口可达、放弃草稿。Duo 展开状态为 951×669pt，实际显示面录屏另存。 |
| SE / `phone-large-keyboard-reboot` | PASS：1 项、3 档字号，完整 xcresult | 重启本任务专用模拟器后，三档实际字号读回、靠后字段输入与软件键盘/保存入口、放弃草稿均通过。重启前定位失败仍保留，不声称已确定根因。 |
| iPad / `ipad-layout-boundaries` | 2 PASS / 1 FAIL，完整 xcresult | 深色 320pt 最大字号预览和最大字号旋转动作通过；首次 URL 用例错误假定点按后光标一定在末尾，失败保留。修正为检查插入文字及原文保留后，`ipad-large-keyboard` 通过。 |
| SE / `phone-layout-boundaries` | 逐项 1 PASS / 2 FAIL；结果包未完整收尾 | 深色 320pt 最大字号预览通过；URL 光标假设失败；旋转后手势切到其他标签，长按钮查询失败。用例已全部输出结束后，进程仍持续解析包而未收尾，终止该进程；不宣称整套 PASS。 |

### 有效控制路径与失败保留

- 原 `typeText("\n")` 路径发生 XCTest 空闲等待停滞。现在点击实际软件键盘返回键，并核对后续字段值、字母键可命中、Done 收起和保存结果。已验证这条原生交互路径可用，未证明旧注入换行路径的具体根因，也没有修改 App 键盘代理。
- 系统偏好使用每模拟器的 `com.apple.Accessibility` 中 `ReduceMotionEnabled` / `EnhancedBackgroundContrastEnabled` 配置，外观/提高对比度使用 `simctl ui`；随后启动 App 读取真实 `UIAccessibility` / traits。读回 On/Off 与交互对照分别保留。该方法验证启动环境，不冒称已验证同一进程内的偏好通知响应；复现用例及环境变量见 [样例说明](../Examples/README.md)。
- 小窗口诊断观察到：滚动容器仍使用屏幕坐标，子元素在滚动后改报窗口内坐标；整页手势还会越过邻近入口。测试优先原生命中检查，必要时换算坐标，远处翻页、近处小幅拖动。保留旧 2 FAIL、优先命中版本 2 FAIL、小幅拖动版本 1 PASS / 1 FAIL，最终有界回归单独记录，不回写旧结果。
- Duo 展开时原生返回按钮位于侧边工具栏；新增字号检查初次只查询 NavigationBar，导致 1 FAIL，修正查询后通过。显示面也必须现场枚举：本次展开屏为 `primary-1`，`primary` / `XCUIScreen.main` 捕获黑屏，首次录屏仅有静止帧；有效展开屏录屏保留完整过程。既往折叠状态 `primary` 有效的结论不能机械应用到所有姿态。
- 安全输入阶段部分截图没有呈现键盘/口令，而自动化能读到已聚焦的掩码值、可命中的字母键并完成 Done；原因未确认。该截图不独立计作视觉通过，普通字段的键盘截图与实际操作另存。
- 两次 SE 字号尝试的失败及结果未收尾分别保留，不把重启后的新结果当作已确认旧异常根因。

### 仍未满足的完成条件

最低 iOS/iPadOS 17.0、真实 VoiceOver 导航/激活/错误/归焦及真机触控仍未验证。当前没有可用的 17.0 runtime，声明下限不变，不要求 Apple 登录作为本地模拟器工作的前置。SE 横屏控制与实际画面/命中的一致性，以及剩余长错误/最窄窗口/最大字号的组合仍须补证；运行中偏好响应现有的 Duo 有界覆盖见下节，其他设备组合尚未完成。系统模拟授权只证明合成恢复流程，不证明真实权限处理。

因此 #35/#36 继续 OPEN，PR #1/#2 继续 Draft；本轮提交与推送验收改进，但不合并、不关闭、不发布或升级消费产品。

## Duo 运行中系统偏好响应 · 2026-10-27

**PASS（有界原生交互检查）**：在 Duo / iOS 27.1 展开态、Dark / Increased / Accessibility XXXL 环境中，保持基础环境页打开，通过 Device Hub 原生系统开关将 Reduce Motion 与 Reduce Transparency 从 On 切到 Off，再恢复 On。每步同时核对系统开关和 App 的 `environment.Reduce Motion` / `environment.Reduce Transparency`，均按 On → Off → On 更新。三个阶段的应用进程标识一致，未重新启动 App、覆盖 traits 或改写产品代码；本次改动的两项偏好已恢复原值，用户使用的 SE 展台未被操作。

候选源码为 `6e4619f`。已安装 App 主二进制与 debug dylib 的 SHA-256 均匹配上一轮 `LayoutDerivedData` 制品；App/组件源码逐文件匹配已保存的 Duo 验收清单。本地 `.local/live-preferences-20261027/` 保存进程快照、制品摘要和从工具读数转录的观察记录。本项为 CUA 原生交互与可访问性读回检查，不是新增 XCTest 或整页视觉验收。

该结果补充了此前仅有启动读回的证据。它证明这一环境下同一运行进程响应系统偏好变化，但未单独跟踪具体通知回调，也不外推其他设备、所有动效、真实 VoiceOver 或完整组合矩阵。前述最低系统及其他未满足条件继续保留，PR 和 issue 状态不变。
