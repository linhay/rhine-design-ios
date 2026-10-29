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

## 单模拟器复核收尾 · 2026-10-28

按用户指定的单模拟器流程，在 `Rhine-Foundation-phone` / iOS 27.0 上使用固定 Xcode 27.1、`RhineExample` scheme，尝试组合运行 `RhineDesignTests` 与 `GalleryInteractionTests`。XcodeBuildMCP 等待 300 秒后超时；底层 `xcodebuild` 未自行收尾，已停止应用并终止残留进程，未产生可引用的完整结果包。本次是新的验证失败/超时记录，不解释为产品代码根因，也不把部分运行状态当作 PASS。源码未改，既有通过证据、失败和剩余最低 17.0、真机 VoiceOver/触控及完整窗口/方向/字号矩阵缺口继续有效；#35/#36 与 PR 状态不变。


## iPad 键盘与 SE 横屏边界补证 · 2026-10-27

本节更新前述“其他设备运行中偏好、SE 横屏画面/命中及长错误仍未补证”的当前结论，旧失败和未完成矩阵保留。候选 `bd25ae8`，App/组件实现未改；18 个源码/工程条目与既有验收清单逐项匹配。iPad 与 SE 已安装主二进制、debug dylib 的 SHA-256 均匹配 `FinalDerivedData` 制品。固定 Xcode 27.1，本轮为 **CUA / Device Hub 原生交互与画面核对**，没有新增 XCTest；原始观察转录、进程、制品摘要和截图在忽略的 `.local/boundaries-20261027/`，公开记录不附带设备标识或本机界面截图。

| 场景 | 有界结果与实际观察 |
| --- | --- |
| iPad A16 / 27.0，已有小窗口、Dark / Increased | PASS：减少动态、减少透明度分别 On → Off → On，系统开关与 App 读回一致，三个阶段进程相同。随后系统字号调至 Accessibility XXXL，App 实际读回确认。未单独跟踪通知回调。 |
| 同一小窗口、最大辅助字号长错误 | PASS：分段滚动核对长邮箱错误，从开头、示例地址到最后“窄窗口下也应完整换行”，相邻截图内容重叠，未见横向裁切或与只读字段重叠。沿用此前 375×486pt 窗口，未将其声明为系统允许的绝对最小窗口。 |
| 同一环境，错误定位及可见软件键盘 | PASS：清空必填后点击保存，两个错误和首字段定位；通过 Device → Keyboard → Toggle Software Keyboard 显示实际字母键盘。按画面坐标输入 URL 字母，点击 Next 转到密码，输入后可见掩码，点击 Done 收起；当前字段和保存入口均在键盘上方。URL 与安全输入的实际键盘截图分别保留。 |
| 同一环境，失败保留与重试 | PASS：填入有效合成示例后保存，提交期间字段/提交入口锁定；模拟失败后草稿保留，完整失败提示可滚动读到；再次保存、模拟成功后编辑器关闭并显示资料摘要。填入有效示例主动替换了先前键盘输入，不将两段误写成同一份输入的持久化检查。成功结果有 AX 读回，未另存成功截图。 |
| iPad 重启后全窗口、Light / 最大辅助字号 | PASS：竖屏与真实横屏分别显示完整长错误。外部关闭模拟器后窗口恢复全宽，这两项单列，不能与此前小窗口证据混算；两次拖角没有改变窗口，未据此声称最窄窗口已复验。 |
| SE 第3代 / 27.0、Light / Standard / Accessibility XXXL、真实横屏 | PASS：Device Hub 旋转后实际画面为横屏，长按钮全文两行显示。先用主要动作设置不同反馈，再定位并按画面坐标点击长按钮，反馈从“已激活：主要动作”变为“长文按钮已激活”。这是画面与命中的有界一致性检查，不解释旧 XCTest 旋转失败根因。 |
| SE 同进程偏好响应 | PASS：基础页实际字号读回为 Accessibility XXXL；减少动态与透明度分别 Off → On → Off，App 随之更新，三阶段进程一致。恢复系统字号 Large、浅色/标准对比度及原关闭偏好，回到竖屏 Gallery。 |

初次 iPad Keyboard AX 元素存在时，截图仍没有完整键盘；该截图继续作为未满足视觉条件的记录。软件键盘开关提供了新的有效控制路径，没有证据将所有旧空闲超时/截图缺失归为同一个原因。AX 点击可能滚动并直接激活，故 SE 的坐标命中检查先重置反馈再点击；不以元素存在或旧反馈重复出现计成功。

用户明确要求后续只启动一台本任务模拟器：完成 iPad 后先关闭，再启动 SE；其他设备保持关闭。iPad 偏好恢复 Dark / Large / Increased 与两项减少设置 On，方向恢复竖屏，但重启后的全宽窗口未恢复到旧小窗口；SE 已恢复常用展示环境。

**仍未验收**：最低 iOS/iPadOS 17.0、真机触控及真实 VoiceOver 导航/激活/错误/归焦；最窄窗口的尺寸确认及剩余方向、长错误、字号、外观/状态组合。当前结果不外推完整矩阵或所有动效。未发现需修改产品代码的新故障，本轮提交证据和复现方法；#35/#36 继续 OPEN，PR #1/#2 继续 Draft，未合并、关闭、发布或升级消费产品。


## SE 横屏软件键盘与制品身份复核 · 2026-10-28

本节补充 A01 的一个有界组合，取代该组合尚无本轮证据的结论，不取代旧失败或完整矩阵缺口。源码候选 `b600eea156fde2217cd9285e92aa5969ff112565`；组件和 App 实现未改。本轮复用此前 Xcode 27.1（27A9275）编译制品，没有新增构建或 XCTest。重新安装后核对主二进制和 debug dylib 的 SHA-256，均与指定构建一致；源码清单、安装前后摘要、观察与截图保存在忽略的 `.local/se-landscape-20261028/`。

**PASS（CUA 原生交互与实际画面核对）**：iPhone SE 第3代 / iOS 27.0，Light / Standard，系统 Accessibility XXXL，减少动态/透明度关闭，实际横屏。在表单 URL 字段点击可见软件键盘字母键，原文中插入合成字符；点击 Next 后输入落入密码字段，点击 Done 后键盘实际消失、密码显示掩码。URL、密码及 Done 后截图分别保留；键盘出现时当前字段与导航保存/取消入口可见。安全输入截图中的最后一个字符短暂可见，随后掩码截图另存；不把该瞬时显示解释为密码持久化。

**排除与失败保留**：首次观察时，已安装 App 主二进制匹配构建，但 debug dylib 的摘要及 Mach-O UUID 不匹配，因此首次观察不计入当前候选 PASS。重新安装指定制品后才重复上述操作；旧安装身份差异的成因未确认。期间发生屏幕捕获错误、控制通道无窗口及超时；重新安装后的坐标点击取消也被控制通道拒绝，未完成退出确认，不计为取消、草稿保留/丢弃或保存完成的新增通过证据。工具错误不直接判定为产品故障。

收尾恢复系统 Large、浅色标准对比度、减少偏好关闭，重新启动正常 Gallery 并恢复竖屏，截图确认。仅使用一台本任务模拟器。本节不外推长错误、完整窗口/字号/方向组合、真实 VoiceOver 或真机触控。最低 iOS/iPadOS 17.0、真实辅助技术/触控及剩余矩阵仍未满足；#35/#36 保持 OPEN，PR #1/#2 保持 Draft，未合并或关闭。


## iPad 深色大字号长错误与横屏草稿退出 · 2026-10-28

本节补充 A01/F02 的有界组合，取代这两个具体场景尚无证据的状态，不消除其他矩阵缺口。CUA 检查源码 `9d52c74`，新增定向用例源码 `ac7451b`；公共组件和 Gallery 实现未改。Xcode 27.1，iPad A16 / iPadOS Simulator 27.0（24A434），Dark / Increased，Reduce Motion 与 Reduce Transparency 均 On。先关闭任务 SE，再启动任务 iPad；未启动第二台本任务模拟器。

| 检查 | 结果与边界 |
| --- | --- |
| 系统字号最大档、实际全窗口竖屏与横屏长错误 | PASS（CUA 操作与画面）：定位长邮箱错误，两个方向的截图均可读完全文，包括末句，并与后续只读标题分开。该轮未新采集 point 尺寸，不作最窄窗口证据。 |
| 横屏、Accessibility XXXL 草稿继续/放弃 | PASS：新增 `testLargestTextLandscapeDraftContinueAndDiscard` 定向测试。清空必填后取消，确认两项选择可命中；继续编辑后两字段仍空，再取消并放弃，原资料摘要不变。断言窗口宽大于高，退出确认截图另行实看，标题、说明及两动作完整可读。字号由测试启动参数设定；不冒充本轮系统偏好通知测试或真实 VoiceOver。 |
| 原生控制与最窄窗口尝试 | 未完成：Device Hub 连接/选择曾超时；拖拽分别返回窗口定位失败或无窗口，未完成新的最窄窗口尺寸确认。编辑器导航动作在画面可见但未出现在该控制通道的 AX 树中，字段 Cancel 辅助动作未关闭编辑器。手动段不计作退出通过；后续 XCTest 是独立证据，未确认前述工具异常根因。 |

测试首次调用因重复 `-resultBundlePath` 参数在执行前失败。移除重复参数后，XcodeBuildMCP 返回 **1 PASS / 0 FAIL / 0 SKIPPED**，但其临时结果包随后已被清理。为保留可复查证据，对同一已构建测试制品执行单设备 `test-without-building`，指定 90 秒默认/120 秒最大单用例限时；独立复跑 **1 PASS / 0 FAIL / 0 SKIPPED，exit 0**，完整结果包及两个截图附件已导出。两次通过不写成两个不同场景，参数失败与旧超时保留。

本地证据在忽略的 `.local/ipad-boundaries-20261028/`：手动步骤、竖横屏长错误截图、源码及主二进制/debug dylib 摘要、测试源码/制品摘要、日志、`landscape-draft.xcresult` 和附件。测试后已安装主二进制/debug dylib 均匹配指定构建。复现选择 `RhineExampleUITests/GalleryInteractionTests/testLargestTextLandscapeDraftContinueAndDiscard`，关闭并行；结果包保留方法见样例 README。

收尾恢复原 Dark / Large / Increased、两项减少偏好 On、竖屏 Gallery，截图确认。仍缺最低 iOS/iPadOS 17.0（本轮 runtime 清单仍只有27.0/27.1）、真机 VoiceOver/触控、最窄窗口尺寸确认及其他未覆盖的布局/外观/状态组合。没有新发现需要修改产品源码的故障；#35/#36 保持 OPEN，PR #1/#2 保持 Draft，未合并、关闭、发布或升级消费产品。


## Agent 会话组合 #109 · 2026-10-30

本项为 [#109](https://github.com/linhay/rhine-design/issues/109) 的 UIKit 组合规范及合成配方，见 [Draft PR #4](https://github.com/linhay/rhine-design-ios/pull/4) 与 [AgentSession](AgentSession.md)。基于远端 gallery `c62d920`，依赖 PR #2/#1；没有带入共享检出的 `ead93f3` / `2797159` 文档提交，没有改变公共 Package API、发布版本或消费项目。

实现修订 `cf2c7f9`；输入法门禁刷新及严格键盘回归为 `3fb9e31`。固定 Xcode 27.1（27A9275）、Swift 6 模式，iOS/iPadOS Simulator 27.0（24A434），只使用合成数据。测试按单台任务模拟器串行执行，切换前关闭上一台，其他项目设备未操作。原始源码/工程摘要、主二进制与 debug dylib、测试二进制、日志、结果包与附件位于忽略的 `.local/agent-session-109/`。

| 实际检查 | 结果与边界 |
| --- | --- |
| 初次 build/run 与定向 test_sim，SE 第3代 | PASS：UIKit 构建/安装/启动；8 项模型 + 1 项流式锚点 UI 通过。随后发送未知和初版键盘 2 项断言通过；工具临时结果包被清理，摘要单独保留，不冒称完整包存在。 |
| `cf2c7f9` / SE / phone-fixed | 14/0/0，完整 xcresult：8 模型回归；授权后台恢复/允许/拒绝、遮挡/撤回、运行停止、流式锚点及未知发送行为通过。初版最大字号键盘用例断言不足，见下方失败保留，不据此声称真实发送或完整视觉通过。 |
| 严格键盘首次复验 | FAIL：第一次 Done 后等待键盘消失超时；本环境中键盘仍存在。保留测试 stdout 与来源，测试已经失败后仅终止本任务诊断收集子进程，工具最终返回 1 FAIL。它不是整个产品的键盘故障结论。 |
| `3fb9e31` / SE / phone-motion-fixed | PASS：3/0/0，完整 xcresult。实际读回 Reduce Motion 开启，普通浅色与深色最大辅助字号；授权 Home/Activate→同页同步→允许/拒绝、未知发送→重连→接受及迟到确认、严格键盘发送均通过。窗口读回 375×667pt。 |
| 同一制品 / SE / phone-standard-fixed | PASS：1/0/0，完整 xcresult。恢复系统 Reduce Motion 关闭后，严格最大字号深色键盘发送通过；实际偏好读回与点击前按钮全文/键盘截图分别保留。 |
| `3fb9e31` / iPad A16 / ipad-fixed | 5 PASS / 1 FAIL，完整 xcresult。Dark / 系统 Reduce Motion On，窗口实际 820×1180pt；授权确认/遮挡/撤回、后台运行、严格最大字号键盘和未知发送通过；原历史锚点测试失败，诊断见下节。 |

### 键盘结果与证据修正

初次最大字号截图中的 q 仍处于中文输入法组合，发送禁用且按钮文字部分被键盘裁切。旧用例只检查 isHittable，未断言 enabled 或点击后的“等待接受”，所以旧绿灯不能证明真实发送。另一个点击后截图存在文字未完整绘制的现象，成因未确认，不计完整视觉通过；原件保留。

新用例先用原生 Done 确认组合文本；若键盘保留则继续，若收起则重新显示。分别检查可用性、发送按钮完整 frame 位于 composer/实际键盘边界内、字母键仍可命中，并且点击后必须进入“等待接受”、草稿保留、发送禁用。最终点击前截图实看确认完整按钮文字与键盘同时可见。样例在 editingDidEnd 刷新最终文本及门禁；结束输入不自动提交。

### iPad 历史阅读前提修正

原用例在两次下滑后把首条正文位置作为历史锚点，但 iPad 的 720pt 宽内容在初始视口中几乎完整可见。临时诊断构建的固定复跑再次失败，并记录 contentSize 855→877→899→921pt、viewport 868.5pt；进入所谓“历史”状态时实际距底仅 8.5pt，仍在 24pt 跟随区且 followsBottom=true。追加后偏移52.5pt与新的底部距离一致，证明本次是测试未建立历史阅读前提，不是已确认的模态或滚动算法缺陷。

旧 iPad 5/1 与独立诊断失败包、几何附件和临时源码差异均保留；诊断 test_sim 的调用收尾没有取得可引用摘要，后续固定制品诊断单独记证。修正用 18 条合成历史，并在测锚点之前断言末条正文位于视口底部24pt以外，容差仍为2pt。默认6条配方和滚动算法未改变；临时滚动诊断已从交付源码移除。最终长历史候选为 `0526003`；iPad 定向 test_sim 1 PASS。固定制品 `ipad-history-final` 1/0/0，SE `phone-history-final` 9/0/0（8模型+1流式UI），均有完整xcresult、前后几何附件及截图；SE读回Reduce Motion关闭，iPad读回开启。两个设备安装后的主二进制与debug dylib均匹配冻结制品，临时诊断未进入交付。

### 制品与未覆盖范围

`3fb9e31` 已验收 App 主二进制 SHA-256 为 `a171cfff87597bad293cf0c0700e76c4c778a666709e4dc81c5ff84f7e18613e`，debug dylib 为 `f6cdf8a109381c5e754cf5a70c051b49f3e71345215ad2d3bbdcfb8a73ef6d1f`。SE 已安装的两者均匹配构建；这份 App 已归档于 artifacts-3fb9e31，完整源码/工程与测试二进制清单见本地 final-candidate-manifest。最终 `0526003` 的主二进制摘要相同，debug dylib 为 `4d2692cc4bc5a00dd6614d5e5c7ecae7c2bcfc9d770c05db5a51274d73c35249`；App 和测试制品另冻结于 artifacts-final，并由 delivery-candidate-manifest 绑定。test_sim 与固定制品 test-without-building 分开记录，不把同一场景的复跑算作新的覆盖。

截至交付文档 `57e4861` 的 SKIPPED：最低 iOS/iPadOS 17.0（当时运行时清单只有27.0/27.1）、真实 VoiceOver 阅读/激活/归焦与触控、iPad 最窄多任务窗口、实时字号变化及剩余横竖屏/外观组合。本轮只读设备清单有两台物理 iPhone 显示可用，但未核验本候选签名、安装、信任或人工验收；不沿用“所有物理设备不可用”的旧事实，也不把连接可见当通过。既有 Device Hub 最窄窗口拖拽失败、历史超时和 #35/#36 的未完成条件仍保留。

N/A：真实协议、主机网络、持久化、多行输入、历史分页与并发授权队列；本项不提供这些实现。合成状态和消费者 loopback 证据不能互相补算。#109 保持 OPEN，PR #4 保持 Draft，依赖 PR #1/#2 也不因本项推进而合并或关闭；不发布、不升级消费产品。


### 运行中系统字号与真实横屏补验 · 2026-10-30

本节补充并取代上方 `57e4861` 时点的实时字号、已列明方向组合状态。App 实现为 `0b5d95d`，仍为 UIKit 合成配方，公共产品和 #35/#36 未改。工具链与运行时沿用上节，原件保存在忽略的 `.local/agent-adaptation-20261030/`；运行均为已有构建的 `test-without-building`，每次只启动一台任务模拟器。

真实字号测试由宿主修改并读回系统 `content_size`，每个用例保持同一非空 PID，分别执行底部、真实历史位置和草稿的 Large → 最大辅助字号 → Large。本轮真实系统字号用例未使用字号启动参数或 trait override；只读 accessibility getter 返回当前字体、行高、锚点、偏移和选区。驱动要求指定测试恰好全 Passed、零 skip、完整系统切换及偏好恢复；仅退出码为零不能通过。

本轮确认并修复三项布局问题：

- 父 VC 布局回调先于子滚动内容更新：字号已变为53pt，contentSize仍2731pt，定位后才增长至15797pt；底部因此少滚13066pt。消息栈完成直接子行布局后再恢复原底部或行锚点，重排中间滚动不覆盖锚点。
- SE横屏实际667×375pt，键盘布局顶部169pt、导航底部78pt，91pt的“查看最新”占满可用高度。紧凑编辑态收起导航，将查看最新放入composer并允许其占据剩余高度；该动作主动结束编辑恢复可见正文，再滚到最新。
- 最大字号草稿字段被压缩到44pt，而实际字体53pt、行高63.248pt、固有高度73pt。严格反例 `phone-field-negative` 失败；将原生输入竖向抗压缩优先级设为required后恢复73pt，分别滚到完整字段和发送按钮验证，未缩小字体或改公共TextField。

失败保留：首次附件读取不存在键盘失败；首次字号底部行为失败后诊断收集超时，原不完整结果包没有可解析Info.plist，不能冒称完整xcresult。后续时序诊断有完整失败包；临时时序日志已移除。方向键rawValue被输入为字符、点按/长按未移动光标的草稿前置失败保留；最终通过原生空格键触控板移动并读取真实内部索引，再用后续插入证明。授权AX将换行归一为空格，定位改用稳定前缀，完整操作/范围/末尾仍必验。横屏收尾等待系统动画曾超时，保留失败，不因后续测试先终止App再恢复方向而宣称确认了系统根因。后续滚动手势校准与结果另按各包保留，不放宽完整边界、键盘、启用或发送状态断言。

App截图在部分横屏模态中出现方向裁剪；同一阶段的display截图和实际窗口几何另存并实看。不能只按App截图或请求的orientation声称横屏通过。

| 设备与实际环境 | 最终 App 的有界结果 |
| --- | --- |
| SE 第3代，Light / Reduce Motion Off，竖屏375×667pt | `phone-live-candidate`：2 PASS / 0 FAIL / 0 SKIPPED。底部跟随、离底历史行及草稿各完成系统字号往返；每个用例 PID 不变，历史锚点容差2pt，内部光标索引、first responder 和草稿保留。最大字号字段73pt高，原生行高63.248pt；后续按保存索引插入并实际发送。 |
| 同一 SE，系统最大辅助字号，真实横屏667×375pt | `phone-landscape-candidate` 原包为 **1 PASS / 1 FAIL**：只计授权项通过，完整上下文、允许/拒绝及各自确认状态可达；该包的键盘项仍为 FAIL。独立 `phone-landscape-keyboard-pan` 为1 PASS / 0 FAIL / 0 SKIPPED：完整字段、实际软件键盘、完整发送及等待接受；查看最新结束编辑后恢复正文和导航。发送 frame 为(16,68,635,93.5)pt，位于顶部169pt的键盘布局边界上方。 |
| 同一 SE，系统 Large | `phone-stream-candidate`：1 PASS / 0 FAIL / 0 SKIPPED，追加时底部跟随及真正历史位置保留回归。 |
| iPad A16，Dark / Reduce Motion On，竖屏820×1180pt | `ipad-live-final`：2 PASS / 0 FAIL / 0 SKIPPED，同进程字号往返、底部、历史、草稿与键盘全部通过。历史行 `agent.message.7.row` 相对顶部始终−30.5pt，滚动偏移786.5→3198.5→786.5pt；实际字体17→53→17pt。草稿内部索引3保持，最大字号字段73pt高。 |
| 同一 iPad，系统最大辅助字号，真实横屏1180×820pt | `ipad-landscape-final`：2 PASS / 0 FAIL / 0 SKIPPED。模态滚动区580×576pt，重叠分段核对完整上下文；允许/拒绝全文及实际确认状态可达。分别滚到完整字段和发送按钮，发送frame为(230,302,720,93.5)pt，位于键盘布局顶部398pt上方；原生字母键可命中，发送后等待接受、草稿保留且发送禁用。 |
| 同一 iPad，系统 Large | `ipad-stream-final`：1 PASS / 0 FAIL / 0 SKIPPED，追加时底部跟随及真正历史位置保留回归。 |

以上是每台设备5项、共10项设备×用例通过结果，来自分别列出的结果包，不是一次全绿测试套件或完整组合矩阵；重复复跑不增加覆盖数。两台设备的实时字号驱动各记录6次实际系统切换及恢复。首次 `ipad-live-candidate` 为1 PASS / 1 FAIL：草稿通过，阅读项的两次整屏滑动越过消息到了顶部状态区。调整为有界手势后仍要求真实消息行ID、离底距离和原2pt容差；旧失败包保留。SE发送手势的边缘大步长来回越过目标、过短拖动未启动原生滚动等失败也保留，最终按实际裁剪距离加手势启动余量，不降低几何断言。

制品绑定：App源码为 `0b5d95d`；主二进制 SHA-256 `896eb222ea1a88ed09f0c630867207d4855aaf256db9ffef115c221f84bed9d9`，debug dylib SHA-256 `6b261a376890d6b0e93cd0adbf4fcb99ad0d397a38e1674e47d6844607fb23e6`。本表各包使用同一App，两设备安装后摘要均匹配。`artifacts-candidate` 绑定 `0b5d95d` 测试，供phone-live-candidate及phone-landscape-candidate；`artifacts-candidate-pan` 绑定 `ce9de13` 测试，供phone-landscape-keyboard-pan、phone-stream-candidate及ipad-live-candidate；`artifacts-candidate-history-gesture` 绑定 `3450e3d` 测试，供三个iPad最终包。后两次提交只修正测试手势，App二进制未变。完整结果包、测试源码/二进制摘要、系统读回、安装摘要及冻结制品由本地 `delivery-manifest.json` 逐项关联；历史 candidate-manifest 不覆盖。

收尾读回系统Large；SE保留Light、减少动态Off，iPad保留Dark、减少动态/减少透明度On，测试恢复竖屏。两台任务模拟器均已关闭，其他项目设备未操作。未重试既有失败的最窄窗口拖拽。

**截至 `29b32ab` 时点的 SKIPPED**：最低iOS/iPadOS17.0、真实VoiceOver阅读/激活/归焦及真机触控、iPad最窄多任务窗口，以及未列出的方向/外观/字号/状态组合。旧修订上的8项模型测试单列保留，本次不冒称在新App上重跑全套模型或交互矩阵。真实服务、持久化、多行输入、分页与并发授权仍为N/A。#109继续OPEN，PR #4继续Draft；依赖PR #1/#2和#35/#36的验收缺口不由本项补算，不合并、关闭、发布或升级消费产品。

### 正常 Gallery 导航补验的前提与失败保留 · 2026-10-30

本轮从正常Gallery推入Agent配方，检查小iPhone系统最大字号横屏下的Done、旋转到充足高度、离开后重新进入。独立`--agent-session`入口没有返回按钮，不能替代宿主导航证据。App保持`0b5d95d`及前述相同主二进制/debug dylib；三条目标路径未复现永久隐藏导航，未修改App或公共组件实现。

前三次phone-navigation-observe、phone-navigation-query-fix、phone-navigation-geometry均为0 PASS / 1 FAIL；首轮达120秒用例上限，后续对同一前提的观察按有界中断保存，SIGINT后的退出码分别75、73、75，系统字号均恢复。最初仅凭末行日志怀疑隐藏按钮查询停住；geometry轮采样纠正了该判断：App主线程处于正常事件等待，测试运行器在失败断言的符号化报告中。采样原件保留，不将旧末行日志当作产品死锁或已确认AX查询根因。

先取证的phone-navigation-capture得到1 PASS，但**不计紧凑态验收**：`typeText`之后实际keyboard frame为(0,375,667,162)pt，已在667×375pt窗口外；q不可命中，导航可见，composer为(0,226.5,667,148.5)pt。display截图确认键盘未显示。该用例只完成了普通编辑结束/返回，不能回写前三次紧凑前提失败。后续改用实际软件键盘q按键、原生Done确认组合文本，必要时重新显示键盘，并在取证后严格要求q可命中和实际紧凑窗口几何。没有用放宽前提后的绿灯替代目标场景。

真实键盘版phone-navigation-native-keyboard仍记0 PASS / 2 FAIL：Done后草稿/导航检查及实际返回已完成，但两次等待动画空闲各约60秒，越过原120秒用例上限；另一项退出用例在中断时被结果包记为Testing was canceled。采样记录App主线程正常等待、测试运行器等待quiescence。之后使用复现命令已有的180秒单用例上限，断言不变；成功重跑约39秒，没有确认旧等待的系统根因。phone-navigation-remaining的边缘返回尝试为0 PASS / 1 FAIL，截图仍在紧凑编辑页，没有离开；配方未承诺隐藏导航时的边缘pop，最终按已有“查看最新→原生返回”入口验证退出，未增加手势实现或把这条失败写成通过。

| 目标路径（SE第3代，iOS27.0，Light / Reduce Motion Off，系统最大辅助字号） | 最终有界结果 |
| --- | --- |
| 紧凑编辑 → 原生Done → 实际返回Gallery | **PASS**：phone-done-180，1/0/0，39.411秒。起始窗口667×375pt，composer为(0,0,667,169)pt，实际字母键可命中、字段73pt完整可读。Done后键盘关闭，原导航与“总览”返回入口恢复；草稿q保留、仍未发送，并实际返回Gallery。 |
| 紧凑编辑 → 旋转到充足高度 | **PASS**：phone-navigation-final中的旋转项，38.629秒。真实窗口变为375×667pt，键盘仍可命中；导航及返回入口恢复，字段为(16,324,343,73)pt，键盘顶部451pt。草稿q保留且未发送，随后Done和实际返回完成。 |
| 紧凑编辑 → 查看最新 → 原生返回 → 重新进入 | **PASS**：phone-navigation-final中的重进项，46.845秒。回阅读后原页面草稿q仍保留，原生返回后Gallery导航/标签正常；再次进入的新配方有完整返回入口、独立新草稿及未发送状态，再次实际返回完成。此项不承诺跨实例持久化或边缘pop。 |

最终为两个结果包的3项通过，零失败、零skip；先前失败包及未满足紧凑前提的普通Done绿灯单列保留。测试源码为`bbc4e18`。Done包使用更早的冻结测试源码artifacts-navigation-180，其Done用例及所有调用helper与交付逐段一致；后两项使用artifacts-native-return，完整测试源码与交付一致。每份测试二进制/源码摘要、源码差异、日志、xcresult、系统偏好读回及截图绑定到本地`.local/agent-navigation-20261030/delivery-manifest.json`。display截图已实看，安装后的App主二进制/debug dylib仍与`0b5d95d`冻结制品一致。收尾恢复原Large/Light/减少动态Off，SE关闭；iPad一直关闭，其他设备状态保持。

### #109 有限验收边界 · 2026-10-30

本节把此前笼统的“剩余方向/外观/字号/状态组合”收敛为与 [组合合同](AgentSession.md) 对应的有限清单；不撤销旧失败，不把未测组合声明通过，也不追加任意字号、外观和状态的笛卡尔积。新导航布局的补验单列，未修改的模型与状态逻辑沿用原修订证据。

| 合同要求 | 已有证据及适用范围 |
| --- | --- |
| 长正文层级、流式底部/历史、显式回最新 | App `0b5d95d`：SE的phone-stream-candidate、iPad的ipad-stream-final各1 PASS；最大字号长正文和回最新另见phone-live-candidate、ipad-live-final及phone-landscape-keyboard-pan。 |
| 同进程真实系统字号往返、草稿与原生光标 | App `0b5d95d`：phone-live-candidate和ipad-live-final各2 PASS；Large与最大辅助字号往返，真正离底行锚点与2pt容差、实际内部选区及后续插入/发送。 |
| 软件键盘、完整输入/发送、浅深色和减少动态环境 | App `0b5d95d`：SE Light / Motion Off、iPad Dark / Motion On；竖屏见两个live包，系统最大字号真实横屏见phone-landscape-keyboard-pan和ipad-landscape-final。字段73pt且完整动作可达。 |
| 一次性授权上下文及允许/拒绝、等待确认与完成 | App `0b5d95d`：SE横屏phone-landscape-candidate仅授权项PASS（整包1/1）；iPad横屏ipad-landscape-final对应授权项PASS。 |
| 发送未知/失败/接受、后台连接与运行、停止、遮挡/撤回/迟到响应 | 沿用`cf2c7f9`、`3fb9e31`的phone-fixed、phone-motion-fixed与ipad-fixed中对应通过项，具体失败边界见上节；发送、后台及授权状态方法本轮无逻辑变更，不能用这些旧包替代新增导航布局的证据。普通/Reduce Motion的状态操作对照已有，不机械重跑所有交换组合。 |
| 模型门禁、草稿及请求/决定身份 | 沿用`0526003`的phone-history-final中8项模型回归；模型及模型测试到本轮未改，未宣称重跑全套。 |
| 正常Gallery入口的导航恢复与页面内草稿 | 本轮phone-done-180与phone-navigation-final，共3项PASS，覆盖上表明确的Done、旋转、退出/重进路径；不是任意导航转场组合的保证。 |

必要外部缺口固定为以下三项，仍为 **SKIPPED**：

1. **最低 iOS/iPadOS 17.0 实际运行**：候选的构建/安装/启动、会话阅读与追加、输入发送、授权决策及返回路径。较新模拟器与manifest声明不能替代；不抬高系统下限。
2. **真机 VoiceOver 与触控**：会话阅读与更新不抢焦点、草稿/Done/发送、授权上下文/允许/拒绝及完成归焦、页面退出后隐藏内容不再参与辅助导航；实际触控完成相应动作。AX读取和自动化点击不替代。
3. **iPad 实际最窄多任务窗口**：确认真实窗口point尺寸，在最大辅助字号下核对长正文末尾、软件键盘上方完整字段/发送、授权全文与允许/拒绝可达。旧拖拽失败保留，本轮未重复无效控制；320pt预览不替代。

现有Light/Off与Dark/On、竖/横屏、Large/最大字号提供上述有界覆盖；未测的交换组合不自动成为新增关闭条件。若后续出现具体回归，再按触发路径定向补证。真实服务、跨实例/进程持久化、多行、分页和并发授权仍按原合同不在本项实现范围，不能将前三项明确要求改作N/A。#35/#36与依赖PR #1/#2自身的未完成条件仍归其原任务。
