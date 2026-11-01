# UIKit 设计体系导航

Rhine iOS 独立维护原生规范、语义 tokens、组件与运行证据。当前 Gallery 候选提供可操作的 UIKit 样例；规范确认、源码实现、系统矩阵通过和制品发布分别判断。

## 按工作进入

| 工作 | 契约入口 | 实现或验证入口 |
| --- | --- | --- |
| 确认框架、平台和外观 | [DesignSystem](DesignSystem.md) | UIKit、Auto Layout、系统原生主题；不从 Web 转换参数 |
| 颜色、文字和组合间距 | [Tokens](Tokens.md) | [RhineColor](../Sources/RhineDesign/RhineColor.swift)、[RhineTypography](../Sources/RhineDesign/RhineTypography.swift)、[RhineSpacing](../Sources/RhineDesign/RhineSpacing.swift) |
| 按钮层级与忙碌动作 | [Components](Components.md#按钮) | [RhineButton](../Sources/RhineDesign/RhineButton.swift)、Gallery 按钮页 |
| 普通与安全输入、开关、静态单选 | [Components](Components.md#基础表单契约) | [RhineFields](../Sources/RhineDesign/RhineFields.swift)、Gallery 表单页 |
| 无内容与无结果 | [Components](Components.md#空状态契约) | [RhineEmptyState](../Sources/RhineDesign/RhineEmptyState.swift)、Gallery 内容状态页 |
| 草稿、校验、保存与退出 | [Components](Components.md#基础表单契约) | [FormsPage](../Examples/RhineExample/FormsPage.swift)；宿主样例政策，不内置到字段 |
| 运行与复现 | [Examples](../Examples/README.md) | `RhineExample` scheme、真实公开产品消费 |
| 证据与未覆盖范围 | [Validation](Validation.md) | 按修订、制品、运行系统、字号与外观逐项判断 |
| 交付与兼容 | [CHANGELOG](../CHANGELOG.md)、[项目状态](../README.md#状态) | 候选 API 不等于已发布版本 |

## 当前候选 API 范围

基础语义入口为 `RhineColor`、`RhineTypography`、`RhineSpacing`、`RhineTarget`。组件入口为 `RhineButton`、`RhineTextField`、`RhineToggle`、`RhineChoice`、`RhineEmptyState`。其中普通文本与安全输入共用 RhineTextField 的用途配置，不因四种字段契约而虚构四个独立字段类。

公开类型与状态责任见[组件 API 映射](Components.md)及实际 [Sources](../Sources/RhineDesign/)。本候选不为与 Web 对齐而补齐远程多选、日期、图表、聊天或多主题。

## 取舍顺序

1. 确定任务、输入与结果，选择系统原生能力及现有公开组件。
2. 保留对象身份、持久标签、错误原因和恢复路径；布局可随 Dynamic Type 增高与重排。
3. 由宿主拥有校验、草稿、请求、保存、权限与退出政策。原生控件负责局部交互，不根据动画结束推断成功。
4. 自定义组合消费本平台语义 tokens；系统控件内部字号、圆角、材质和动效保留系统行为。
5. 按相关场景验证实际 trait、命中、键盘和辅助技术。模拟器截图、自动化测试与真机 VoiceOver 各有证明范围。

紧凑、稳定和精致都不能以缩字、隐藏错误或阻断系统偏好换取。Web 的暖白苔绿与装饰动画可作为品牌研究来源，不能覆盖这里已确认的系统原生主题与首批动效边界。

## 维护归属

平台决定写入 DesignSystem，变量写入 Tokens，API 与行为写入 Components，样例操作写入 Examples，实际结果写入 Validation。新增入口在本页链接，参数与 API 不另抄一份。更改契约时同步检查实现与样例；纯索引修改核对链接、类型名称和候选状态即可。
