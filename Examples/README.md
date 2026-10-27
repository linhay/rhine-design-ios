# Rhine Gallery

Rhine Design 的可交互 UIKit 展示项目。使用本地 `RhineDesign` Swift Package 的公开组件，支持 iPhone 和 iPad，所有数据和任务均为合成演示，无登录、网络服务或真实权限请求。

## 打开与运行

用 Xcode 27.1 打开 `RhineExample.xcodeproj`，选择 `RhineExample` scheme 和已安装的 iOS Simulator，运行即可。工程已提交，无需先安装 XcodeGen；新增文件或修改 `project.yml` 时才需在源码仓根运行 `xcodegen generate --spec Examples/project.yml`。目标最低系统 17.0；实际验证范围见 [Validation](../docs/Validation.md)，不将部署目标当作全部系统均已测试。

## 四个展示分区

| 分区 | 可核对内容 | 操作 |
| --- | --- | --- |
| 总览 | 系统动态颜色、文字层级、中英长文、间距、最小触控范围 | 从组件手册进入各区；查看基础环境页 |
| 按钮 | primary / secondary / plain、破坏性、禁用、忙碌、图文、长标题 | 开始任务 → 手动成功/失败 → 重试；观察激活计数 |
| 表单 | 单行文字、email、URL、安全输入、开关、静态单选、说明与错误 | 编辑 → 清空必填 → 保存校验 → 填入有效示例 → 保存失败 → 重试成功；取消可继续编辑或放弃 |
| 状态 | 尚无内容、无匹配、加载、失败、权限说明、已有内容 | 下拉选择场景；添加收藏、清除筛选、重试、模拟授权均改变真实的本地状态；可打开长说明 |

右上角 **预览** 提供跟随系统/浅色/深色、标准/特大/最大辅助字号和 320pt 内容上限。预览只作用于 App，不修改设备全局设置；非系统预览会在页面标注，并可一键恢复跟随系统。提高对比度、减少透明度和减少动态仍读取系统偏好。预览不是系统设置切换或真实 VoiceOver 验收。

表单将草稿保存在编辑器中，提交时锁定快照并禁用编辑和退出，失败保留内容，成功才更新父页面并关闭。密码不写入保存后的资料，也不存入 UserDefaults/Keychain。只有宿主负责合成规则与任务结果，公共字段不包含业务校验。

## 诊断与测试入口

- `--foundation-diagnostics`：启动原基础环境页，保留 #35 的原生诊断路径。
- `--preview-narrow-content`：仅基础诊断页的 320pt 内容上限。
- `--gallery-tab=0` 到 `--gallery-tab=3`：直接进入一个展示分区，供复现和 UI 测试使用。
- `GalleryInteractionTests`：展示导航、预览、重复提交门禁、表单校验/失败保留/取消/成功、空状态恢复、大字体可达性。
- `ComponentBehaviorTests`：按钮点击与辅助激活共用门禁、字段状态不丢输入、宿主更新不产生伪用户事件、无回调不呈现空动作。
- `SystemEnvironmentTests`：显式配置模拟器后检查 App 实际读取的外观、对比度、减少动态和减少透明度。未提供四个预期值时标记 SKIPPED，不能计为通过。

键盘回归点击真实软件键盘的 Next/Done，再通过输入后的字段值确认焦点移动；同时要求字母键和当前字段可命中。连接硬件键盘、仅存在 Keyboard 元素或注入换行不代表软件键盘遮挡验证通过。

系统环境用例从测试运行器环境接收预期值。例如，将目标模拟器实际配置为浅色、标准对比度、关闭减少动态与透明度后，从源码仓运行：

```sh
TEST_RUNNER_RHINE_EXPECT_APPEARANCE=Light \
TEST_RUNNER_RHINE_EXPECT_CONTRAST=Standard \
TEST_RUNNER_RHINE_EXPECT_MOTION=Off \
TEST_RUNNER_RHINE_EXPECT_TRANSPARENCY=Off \
xcodebuild -project Examples/RhineExample.xcodeproj -scheme RhineExample \
  -destination 'platform=iOS Simulator,name=<目标模拟器名称>' \
  -parallel-testing-enabled NO \
  -resultBundlePath .local/system-environment.xcresult \
  -only-testing:RhineExampleUITests/SystemEnvironmentTests test
```

有效预期分别为 `Light/Dark`、`Standard/Increased`、`Off/On`、`Off/On`。测试只读真实系统值，不配置偏好或覆盖 traits。启动读回不替代运行中通知响应；测试后还原为运行前的系统设置。

原始 xcresult、日志和截图放在被忽略的 `.local/`；不上传本机路径和设备标识。界面预览、测试断言、视觉审阅和真实辅助技术证据分别记录。
