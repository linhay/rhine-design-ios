# 语义 tokens

确认依据：[方案 v1](https://github.com/linhay/rhine-design/issues/34#issuecomment-6410947901) 与 [维护者确认](https://github.com/linhay/rhine-design/issues/34#issuecomment-6410983498)，2026-10-26。设计规则已确认；实现和运行验收状态另见 [Validation](Validation.md)。

| 语义 | 原生映射 / 初值 | 责任与回退 |
| --- | --- | --- |
| `text.primary` / `text.secondary` | 系统 primary / secondary 前景 | 随外观与对比度变化；错误同时有文字，不只变色。 |
| `surface.canvas` / `surface.group` / `separator` | 系统背景、分组背景、分隔语义 | 可在模块内部用系统动态颜色桥接；公开 API 不暴露 UIKit 类型；禁止固定黑白。 |
| `action.accent` / `status.error` | 系统 tint / 系统 red 语义 | 原生 destructive role 优先；不把红色等同所有错误。覆盖色需浅/深色及提高对比度证据，不通过则保留系统默认。 |
| `type.title` / `body` / `label` / `supporting` | `.headline` / `.body` / `.body` / `.footnote` | 系统字体和默认字重；强调按上下文使用系统样式。无固定行高、缩小字体或限制 Dynamic Type 上限。 |
| `space.inline` / `related` / `group` / `page` | 4 / 8 / 16 / 20 pt | 仅用于自定义组合；系统 Form、List、Button 的内距保持默认。大字体重排、需要时增加间距，不能硬压回固定高度。 |
| `target.minimum` | 自定义交互区至少 44 × 44 pt | 范围不与相邻动作重叠；44 是最小交互区，不是固定行高。 |
| `motion.stateChange` | 首批自定义状态切换不附加装饰性位移、弹簧或循环动画 | 系统控件使用系统行为；读取 Reduce Motion。忙碌始终有静态文字可理解，系统进度动画不是唯一信号。暂不引入任意 duration/easing token。 |

系统组件保持自己的文字角色和布局，以上组合 tokens 不覆盖其内部样式。字段、标签、说明、错误按 leading 对齐；字段说明/错误置于该字段下方，同起点，错误优先于非必要帮助。空状态采用系统容器的居中布局，长说明可多行；操作在内容后，不用绝对定位。大字体、长中英文与窄窗口时纵向重排，不截断关键标题/错误或用缩字换密度。系统圆角、边框、阴影、材质暂不抽象成独立公开 token。

## #35 公开实现映射

颜色对应 `RhineColor.textPrimary/textSecondary/canvas/group/separator/error/accent`；字体对应 `RhineTypography.title/body/label/supporting`；间距对应 `RhineSpacing.inline/related/group/page`；自定义命中下限为 `RhineTarget.minimum`。`accent` 为 `TintShapeStyle`，继承宿主 tint；系统动态颜色在模块内部桥接，公开类型不暴露 UIKit。

动效规则当前表现为不添加自定义动画，不为了占位导出始终返回同值的动效API。样例直接读取 SwiftUI 的 Reduce Motion 与 Reduce Transparency 环境；真实组件有动效需求时再按具体 issue 明确 API 和验收。
