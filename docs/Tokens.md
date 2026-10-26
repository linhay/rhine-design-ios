# 语义 tokens

> 当前主框架为 **UIKit**，依据[用户明确纠正](https://github.com/linhay/rhine-design/issues/34#issuecomment-6419860390)（2026-10-26）。此前 SwiftUI 主方案及其控件映射已被取代；SwiftUI 只可作为未来另行评估的可选消费适配，不是首批依赖。

确认依据：[方案 v1](https://github.com/linhay/rhine-design/issues/34#issuecomment-6410947901) 与 [维护者确认](https://github.com/linhay/rhine-design/issues/34#issuecomment-6410983498)，2026-10-26。设计规则已确认；实现和运行验收状态另见 [Validation](Validation.md)。

| 语义 | 原生映射 / 初值 | 责任与回退 |
| --- | --- | --- |
| `text.primary` / `text.secondary` | UIColor.label / secondaryLabel | 随外观与对比度变化；错误同时有文字，不只变色。 |
| `surface.canvas` / `surface.group` / `separator` | UIColor.systemBackground / systemGroupedBackground / separator | 公开 UIColor 保留动态解析，遵循视图 traitCollection；禁止固定黑白或提前固化为 CGColor。 |
| `action.accent` / `status.error` | UIView.tintColor 继承 / UIColor.systemRed | 按钮破坏性意图使用原生 role；强调色取当前视图 tint，不能在全局静态缓存。错误文字不只靠颜色。覆盖色需浅/深色及提高对比度证据，不通过则保留系统默认。 |
| `type.title` / `body` / `label` / `supporting` | UIFont.TextStyle.headline / body / body / footnote | 用 UIFont.preferredFont(forTextStyle:compatibleWith:)；UILabel/UITextField 等开启 adjustsFontForContentSizeCategory。trait 改变时重新解析缓存字体，保留完整辅助字号；不固定行高或缩字。 |
| `space.inline` / `related` / `group` / `page` | 4 / 8 / 16 / 20 pt | 仅用于自定义组合；系统 UIKit 列表、分组和 UIButton 的内距保持默认。大字体重排、需要时增加间距，不能硬压回固定高度。 |
| `target.minimum` | 自定义交互区至少 44 × 44 pt | 范围不与相邻动作重叠；44 是最小交互区，不是固定行高。 |
| `motion.stateChange` | 首批自定义状态切换不附加装饰性位移、弹簧或循环动画 | 系统控件使用系统行为；读取 UIAccessibility.isReduceMotionEnabled 并响应对应变化通知。忙碌始终有静态文字可理解，系统进度动画不是唯一信号。暂不引入任意 duration/easing token。 |

系统组件保持自己的文字角色和布局，以上组合 tokens 不覆盖其内部样式。字段、标签、说明、错误按 leading 对齐；字段说明/错误置于该字段下方，同起点，错误优先于非必要帮助。空状态采用系统容器的居中布局，长说明可多行；操作在内容后，不用绝对定位。大字体、长中英文与窄窗口时纵向重排，不截断关键标题/错误或用缩字换密度。系统圆角、边框、阴影、材质暂不抽象成独立公开 token。
