# Rhine Gallery

Rhine Design 的可交互 UIKit 展示项目。使用本地 `RhineDesign` Swift Package 的公开组件，支持 iPhone 和 iPad，所有数据和任务均为合成演示，无登录、网络服务或真实权限请求。

## 打开与运行

用 Xcode 27.1 打开 `RhineExample.xcodeproj`，选择 `RhineExample` scheme 和已安装的 iOS Simulator，运行即可。工程已提交，无需先安装 XcodeGen；新增文件或修改 `project.yml` 时才需在源码仓根运行 `xcodegen generate --spec Examples/project.yml`。目标最低系统 17.0；实际验证范围见 [Validation](../docs/Validation.md)，不将部署目标当作全部系统均已测试。

验收复用已有安装时，先核对实际源码清单与构建制品，再比较已安装 App 的主二进制及 `*.debug.dylib`（如存在）的 SHA-256。只匹配主二进制不足以证明实现一致；仅执行 build 不会替换设备安装。发现不匹配时，安装指定构建并重新执行受影响的检查，旧观察保留但不能归入当前候选通过证据。

需要长期保留 XCTest 截图与结果包时，确认执行工具是否自动清理临时 `xcresult`。本机 XcodeBuildMCP `test_sim` 自动添加 `-resultBundlePath`，不要在 `extraArgs` 重复传入；成功摘要不等于结果包仍可读取。若工具清理了结果包，可对同一已构建测试制品执行有界 `xcodebuild test-without-building`，指定 `.local/` 结果路径并保存日志；分开记录两次执行，重新核对制品摘要。

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


## Agent 会话合成配方

总览 → **Agent 会话 · 合成配方**，或用 `--agent-session` 启动独立入口。规范见 [AgentSession](../docs/AgentSession.md)。所有正文、工具结果、连接和授权均为合成数据，没有网络请求、真实文件访问或系统权限请求。

页面上方保留连接、运行、发送与授权事实；底部是单行草稿。大字号与键盘共同占用空间时，输入区域自身可滚动，Done 只确认组合文本或收键盘，不提交，“发送”才锁定本次草稿。输入区域滚动不会主动收键盘；阅读区域可交互收起。

右上角“演示”可手动追加片段、断线/重连、确认发送接受/拒绝、开始/停止运行以及注入授权。授权页需选择后再“模拟宿主确认”；“模拟请求撤回”代表外部失效。授权期间后台回来后可在同一弹窗“模拟连接同步完成”，无需撤回有效请求。“其他弹窗遮挡”可在弹窗内收到或撤回请求，再关闭观察恢复。关闭弹窗不是授权决策。

范围为有限消息、页面内草稿与单个活动请求，离开页面后的持久化和真实协议由宿主负责。`--agent-dark` / `--agent-large` 是本 App 的预览参数，实际环境文本读回 UIKit traits；它们不冒充系统偏好变化。真实后台通过 Home / Activate 验证，模拟重连按钮的检查另记。

定向测试入口为 `RhineDesignTests/AgentSessionModelTests`、`RhineExampleUITests/AgentSessionInteractionTests`、`RhineExampleUITests/AgentSessionLiveSizingTests` 与 `RhineExampleUITests/AgentSessionLandscapeTests`。工程通过公开 `RhineDesign` 产品消费；样例模型测试托管在 App 中，没有加入 Swift Package 的公共目标。原生结果与环境缺口见 [Validation](../docs/Validation.md)，包括最低 17.0、真实 VoiceOver/触控和 iPad 最窄窗口。以下命令说明复现方法，不代表这些环境已经通过。

使用 `--agent-long-history` 可显示 18 条合成正文，供较高的 iPad 视口测试历史阅读。锚点测试必须先断言末条内容已离开视口底部跟随区；仅执行两次下滑不证明已经脱离底部。默认仍显示 6 条正文。

复现前设置 `SIMULATOR_ID`（已启动的任务模拟器）、`DERIVED_DATA`（本轮构建目录）与 `OUTPUT_DIR`（新的证据目录），在 iOS 源码仓根执行。先构建一次，后续定向运行复用同一测试制品：

```sh
xcodebuild -project Examples/RhineExample.xcodeproj -scheme RhineExample \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  -parallel-testing-enabled NO build-for-testing
```

运行中的系统字号验收由宿主驱动 `simctl ui … content_size`，在每个用例的同一 App PID 内执行 Large → 最大辅助字号 → Large；reading 用例分别检查底部跟随与已离开底部的历史锚点，draft 用例检查已提交草稿、真实光标选区、软件键盘及完整发送按钮。测试读取实际字体度量、锚点和选区，完整按钮 frame 必须位于 composer 与窗口交集内、且在键盘上方。`--agent-inspection` 仅开启读取当前 UIKit 状态的 accessibility getter 测试探针，不设置选区、字号或布局。

```sh
python3 Examples/Scripts/verify-agent-live-sizing.py \
  --device "$SIMULATOR_ID" \
  --derived-data "$DERIVED_DATA" \
  --output "$OUTPUT_DIR/live-size" \
  --test both
```

`--test reading` / `--test draft` 可单独复现。驱动核验每次切换前后的真实系统 `content_size` 读回、同一用例的非空一致 PID，以及 xcresult 中指定测试全部执行并通过；跳过、缺失切换或恢复失败均不能算成功。运行结束尝试恢复原字号，并保留恢复读回、系统切换记录、日志、xcresult 与测试结果 JSON。`--agent-large`、启动字号参数或 trait override 不能作为运行中系统字号变化的证据。

最大辅助字号横屏验收先从外部设置并读回系统字号，再用测试运行器环境传入预期。`TEST_RUNNER_RHINE_AGENT_EXPECT_SIZE` 会在测试内映射为 `RHINE_AGENT_EXPECT_SIZE`，禁用默认的 `--agent-large` 预览参数。测试真实设置 `landscapeLeft` 并断言窗口宽大于高；验证真实键盘字母键可命中、授权上下文可滚至末尾。发送、允许/拒绝及确认按钮的完整 frame 必须位于实际可见视口内，不以部分可命中代替。

```sh
(
  set -eu
  mkdir -p "$OUTPUT_DIR/landscape"
  original_content_size="$(xcrun simctl ui "$SIMULATOR_ID" content_size)"
  trap 'xcrun simctl ui "$SIMULATOR_ID" content_size "$original_content_size"
    restored_content_size="$(xcrun simctl ui "$SIMULATOR_ID" content_size)"
    printf "%s\n" "$restored_content_size" > "$OUTPUT_DIR/landscape/restored-content-size.txt"
    test "$restored_content_size" = "$original_content_size"' EXIT
  xcrun simctl ui "$SIMULATOR_ID" content_size accessibility-extra-extra-extra-large
  actual_content_size="$(xcrun simctl ui "$SIMULATOR_ID" content_size)"
  printf '%s\n' "$actual_content_size" > "$OUTPUT_DIR/landscape/content-size.txt"
  test "$actual_content_size" = accessibility-extra-extra-extra-large
  TEST_RUNNER_RHINE_AGENT_EXPECT_SIZE=最大辅助字号 \
  xcodebuild -project Examples/RhineExample.xcodeproj -scheme RhineExample \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath "$DERIVED_DATA" \
    -parallel-testing-enabled NO -collect-test-diagnostics never \
    -test-timeouts-enabled YES \
    -default-test-execution-time-allowance 180 \
    -maximum-test-execution-time-allowance 180 \
    -resultBundlePath "$OUTPUT_DIR/landscape/result.xcresult" \
    -only-testing:RhineExampleUITests/AgentSessionLandscapeTests \
    test-without-building > "$OUTPUT_DIR/landscape/test.log" 2>&1
)
```

测试附件包含 App 与 display 截图、实际环境及控件几何；失败和超时保留原记录，不由后续重跑覆盖。横屏启动时已处于系统最大字号，只证明该次横屏环境；运行中字号往返另由 live-size 用例证明。可支持的结论、实际结果及剩余缺口统一见 [Validation](../docs/Validation.md)。
