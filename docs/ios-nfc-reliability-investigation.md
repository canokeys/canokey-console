# iOS NFC 读取成功率调研

调研日期：2026-10-19。Console 基线：`80d47d0`；实际解析并由 iOS symlink 使用的 NFC 插件为 `flutter_nfc_kit 3.6.2`，不是 pubspec 下限 3.6.0。对照：[LibreKey Companion iOS，9133926](https://github.com/token2/librekeycompanion_ios/tree/91339265bfd7015a3868e3debbccf2a018381825)。

用户反馈是“读取困难”。本次完成源码和依赖对照，没有 iPhone 射频测量、真机失败日志或成功率样本。下文区分代码事实和待验证的因果关系；不能从源码给出各因素的影响百分比。

## 结论

两者底层都调用 Core NFC 的 `NFCTagReaderSession`、`connect(to:)` 和 `NFCISO7816Tag.sendCommand`，没有看到 LibreKey 使用更强的射频接口。最值得优先验证的差异是：

1. Console 默认轮询 ISO 14443 和 ISO 15693；LibreKey 只轮询 ISO 14443。
2. Console 插件连接成功后强制等待 `queryNDEFStatus`，再把卡交给 Dart；LibreKey 直接交给业务层。
3. Console 插件有确定的会话清理缺陷，连接失败后再次扫描可能持续遇到旧 session。
4. Console 在进入 OATH 业务前还有 Admin 身份和固件探测，增加卡必须持续留在有效场内的时间。

其中第 1 项直接影响发现阶段，第 2、4 项影响“已发现但还没读出”的体验，第 3 项会放大首次失败后的连续失败。尚不能确认用户现场失败落在哪个阶段。

## 1. 扫描协议范围不同：最先做单变量实验

证据：

- Console `lib/helper/utils/smartcard.dart:316` 只传入 `iosAlertMessage`，沿用插件默认扫描参数。
- 插件 `lib/flutter_nfc_kit.dart` 的 `poll` 默认 `readIso14443A=true`、`readIso14443B=true`、`readIso18092=false`、`readIso15693=true`。
- 插件 iOS `FlutterNfcKitPlugin.swift:67` 将上述配置变成 `[.iso14443, .iso15693]`。
- [LibreKey NFCTransport.swift:54](https://github.com/token2/librekeycompanion_ios/blob/91339265bfd7015a3868e3debbccf2a018381825/LibreKeyCompanion/Transport/NFCTransport.swift#L54) 明确只用 `[.iso14443]`。

CanoKey 当前智能卡路径使用 ISO 14443。扫描额外协议可能改变轮询周期和短暂靠近时的发现机会；具体时序由 iOS 决定，源码不能证明影响有多大。建议先在 iOS 设置 `readIso15693:false`、`readIso18092:false` 做 A/B。

注意：在 iOS，A/B 任意一个开启都会映射到同一个 `.iso14443` 选项。把 `readIso14443B` 设为 false 并不能单独关闭 Core NFC 的 Type B 轮询，不应把收益归因于它。

## 2. 强制 NDEF 探测：连接后多了一段不可见等待

证据：插件 iOS `FlutterNfcKitPlugin.swift:561` 连接成功后，在 `:584` 无条件调用 `queryNDEFStatus`，直到回调 `:614` 才完成 `poll`。LibreKey `NFCTransport.swift:127–138` 连接成功即恢复 continuation，没有 NDEF 探测。

Console 的实际路径：

```text
开始扫描 → didDetect → connect → queryNDEFStatus → Dart poll 返回
→ SELECT Admin → 读序列号 → profile 探测 → 目标 applet → 业务读取
```

LibreKey 的路径：

```text
开始扫描 → didDetect → connect → Swift connect 返回 → applet / 业务读取
```

这个差异确定存在。NDEF 查询会增加连接后的等待及潜在通信，并可能改变卡片选择状态；Core NFC 内部具体发了哪些命令、耗时多少，需真机跟踪，不能凭 API 名称断言。插件还会忽略 NDEF 查询错误并返回卡片信息，可能让失败表现为后续第一条 APDU 报错。

`androidCheckNDEF:false` 只控制 Android，iOS 原生代码不读取该开关。因此仅修改这个 Dart 参数无法解决 iOS 的 NDEF 探测。

建议在插件增加独立 iOS 开关，使 Console 的 ISO 7816 路径跳过自动 NDEF 状态查询。Console 的 NFC Tag 页面通过自身 NDEF APDU 客户端读写，修改前仍需核对全部 NDEF API 调用和回归该页面。

## 3. 会话清理存在代码级缺陷

### 3.1 connect 失败，旧 session 可能长期保留

插件 `FlutterNfcKitPlugin.swift:561–565`：连接失败只完成错误回调并设 `self.result=nil`，没有失效或清空 `session`。

Console `smartcard.dart:423` 的 `pollNfcOrWebUsb()` 位于内部 `try/finally` 外；`poll` 抛异常时，不会进入 `:427` 开始的业务块，也就不会执行该块负责的 `stopPollingNfc()`。

此时再次调用插件 `poll`，`:61–62` 会因 `session != nil` 返回 `406 / Cannot invoke poll in a active session`。即使系统随后使 session 失效，仍可能遇到下一项缺陷而无法清理。

这是一条源码可推导的失败链，能解释“失败后越试越难、需要重开应用”的现象，但尚未拿到用户现场日志验证。

### 3.2 poll 已完成后，会话失效回调跳过清理

插件 `FlutterNfcKitPlugin.swift:466–486`：

```swift
guard result != nil else { return }
// ...报告错误...
result = nil
session = nil
tag = nil
```

成功 `poll` 后 `result` 本来就会设为 nil（`:615`）。所以系统在后续读取期间使 session 失效时，回调可能直接返回，保留过时的 session/tag。LibreKey `NFCTransport.swift:107–119` 无论有没有等待连接的 continuation，都会先清理连接状态。

修复方向：

- 原生 invalidation 回调始终清理属于该 session 的状态；是否有待完成的回调仅决定是否报告错误。
- 根据回调的 session 身份隔离旧、新会话，防止旧失效事件清除新 session。
- connect 失败时，明确失效并清理本次 session。
- Console 将 poll/setup 也纳入清理范围，清理失败保留原始异常。
- 不要只用“每次扫描前先 finish”掩盖所有权问题；异步旧回调仍需身份检查。

这类修复主要改善失败恢复，不会直接增强首次发现时的射频性能。

## 4. Console 的业务前置链更长，但不能笼统说总 APDU 更多

Console `SmartCard._process` 每次 NFC 读取先 SELECT Admin、读四字节序列号（`smartcard.dart:429–440`）。OATH `_authenticate` 又调用 `prepare()` 和 `select()`（`oath_controller.dart:358–359`）。

`OathCardClient.prepare` 使用 Minimal Admin probe。固定依赖 `libcanokey f94f40a` 的 `crates/canokey/src/probe.rs` 显示，在传入 bootstrap serial 时，该 probe 发 SELECT Admin、读固件、读型号，跳过重复序列号读取。之后才 SELECT OATH。

因此在现代固件、无认证、无分段/Le 修正的简单路径，Console 到完成首次 OATH SELECT，至少已有 6 条应用层 APDU：2 条 bootstrap + 3 条 probe + 1 条 OATH SELECT。此计数不包含 Core NFC 自动 AID 选择及 NDEF 探测。实际旧固件/续传可能更多。

LibreKey `KeySession.scanOATH` 也不是零探测：先探测 Token2 applet，不支持时才走 OATH。其 OATH 路径直接 SELECT OATH、LIST，再逐条 CALCULATE TOTP（`KeySession.swift:640–653`）。Console 则使用 CalculateAll，条目多时可能更省 APDU。因此：

- Console 进入目标 applet 之前的前置工作较多，这点成立。
- “LibreKey 整个读取过程必然更短、命令必然更少”不成立，需按条目数量和保护状态比较。

优化应保留固件兼容性、卡片身份和认证边界。可研究同一物理 lease 内复用已验证的探测/选择结果，或者提供 libcanokey 显式的组合只读操作；不能跨次贴卡沿用认证状态或盲目省略身份验证。

## 5. 失败恢复、桥接及 AID：次级因素与排除项

- **LibreKey 没有自动重试优势**：其 connect 出错会 invalidate，sendCommand 出错直接抛错，仓库没有 `restartPolling`。Console 没有重试值得改进，但不是本次两个实现的已证实差异根因。
- **可设计安全恢复**：在尚未发送业务命令的连接阶段，或明确可重新开始的只读用例，允许有界重新发现。不要在通用 transceive 层重放 PIN、写入或 HOTP 等可能改变状态的命令。恢复必须新建 lease、重做身份/认证；插件虽提供 `iosRestartPolling`，现有错误路径已 finish，不能直接加一行调用解决。
- **Flutter 桥接会增加主线程调度及编解码**：Console 每条 APDU 经 Dart/MethodChannel/Swift，使用 hex 字符串；LibreKey 直接使用 Swift Data。但它发生在发现之后，没有延迟测量支持“Flutter 是主要根因”。先测每条 APDU 及桥接空隙，再考虑二进制传输或原生组合操作。
- **AID 列表不同**：Console 含 Admin 和 NDEF，LibreKey 不含这两个。两边都正确放在 Info.plist，并启用 TAG entitlement。可记录 `initialSelectedAID` 以检查自动选择行为；仅凭列表顺序不能断言 iOS 每次顺序遍历所有 AID，也不能直接删掉业务所需 AID。
- **超时参数**：插件 Dart 的 poll/transceive timeout 在 iOS 被忽略，由系统决定。Android 的 10 秒等待、500 ms 清理延迟和 2 秒去抖不适用于这条 iOS 路径，调大这些值无助于此问题。
- **交互提示**：Console 中文已提示使用 iPhone 顶部，英文没有明确顶部位置。提示可改进，但没有证据把明显差距归因于文案。

## 6. 验证与实施顺序

先在原生插件增加结构化阶段日志，记录单调时钟、session ID：`begin`、`didBecomeActive`、`didDetect`、connect 开始/完成、NDEF 开始/完成、poll 返回、首条业务 APDU、每条 APDU 耗时、invalidate。保存 NSError domain/code/underlying error 和当时阶段；目前多数错误压成 `500 + localizedDescription`，不利于区分原因。诊断不要新增 PIN、密钥或完整敏感 APDU 内容。

| 组别 | 改动 | 目的 |
| --- | --- | --- |
| A | 当前 Console，仅增加测量 | 建立基线及失败阶段分布 |
| B | A + iOS 仅扫描 ISO 14443 | 隔离发现阶段的协议范围影响 |
| C | B + 跳过自动 NDEF 查询 | 隔离 connect 后的额外等待/通信 |
| D | C + 修复会话清理 | 比较失败后的连续重试成功率 |
| E | D + 经审计的前置命令优化 | 测量业务链缩短的收益 |
| R | 同一部手机、同一把 CanoKey 的 LibreKey | 对照基准；记录确切构建版本 |

同一手机/iOS、同一卡片/固件、同一页面与 OATH 条目数量、同样密码状态、手机壳和摆放方式，随机交错测试各组，每组至少 50 次，条件允许时 100 次以上。必须确认原先对比的是同一把卡；换了 Token2/CanoKey 硬件就无法把差异全归因于软件。

分别统计：

1. 固定贴卡窗口内 `didDetect` 比例，以及从贴卡到发现的时间（需要实验触发标记或视频对时，`begin→didDetect` 包含用户移动时间）。
2. 已发现后的 connect 成功率。
3. 已连接后的第一条业务 APDU 成功率，以及完整读取成功率。
4. 首次出结果时间 p50/p95、NDEF 耗时、APDU 总数与耗时。
5. 一次失败后，下一次尝试是否出现 406、是否必须重启应用。

优先落地 B/C 的对照验证和会话清理修复；在这些结果出来前，没有依据重写整个 Flutter NFC 栈，也没有依据承诺某项改动能将成功率提升到特定数值。

## 7. 当前真机实验版

已将插件 3.6.2 放入 `third_party/flutter_nfc_kit`，以本地依赖提供可复现的 iOS 修改，没有修改全局 pub 缓存。所有实验组统一包含 session 清理修复；因此这里的 A 是扫描/NDEF 基线，不是完全未修改的旧版。

Debug 版「日志」页面新增 `NFC experiment (next scan)`，选择后返回 OATH 页面进行读取；无需重新编译。默认 C，切换作用于下一次扫描，应用重启后恢复默认。

| 页面选项 | ISO 15693 | 自动 NDEF 查询 | session 修复 |
| --- | --- | --- | --- |
| A | 开 | 开 | 有 |
| B | 关 | 开 | 有 |
| C | 关 | 关 | 有 |

`NFC:iOS` 日志包含 session 编号、单调时钟 elapsedMs、detect/connect/NDEF/poll/APDU/finish/invalidate 阶段及原生错误标识。新增阶段事件不包含 APDU 内容；原有 SmartCard APDU 调试日志仍按原逻辑收集。复制现有日志页面可导出记录。

运行开发版：`flutter run --debug --flavor dev -d <iPhone UDID>`。Dev bundle ID 为 `org.canokeys.console.dev`，与正式版分开。先使用 C 正常贴卡几次，再切 A 交错比较；单独做短暂贴卡后移开的失败恢复实验。若日志只有 active 没有 detect，优先分析发现阶段；出现 detect 后再定位 connect、NDEF 或业务 APDU。

### 第一轮真机记录

设备：iPhone 18 Pro Max / iOS 27.0.1；CanoKey Canary / 固件 3.1.0；C 组。以下均为单次样本，不是成功率统计，也没有排除调试构建开销。

- 20:50 的设置读取在分 applet 存储查询时报 NFCError 102，underlying nfcd 29。此前发现、连接、认证和其他读取成功。用户表示可能提前移开卡，不能将此样本判断为固件或命令缺陷。
- 20:51:12 的再次设置读取完整成功，没有重启应用。connect 约 0.71 ms；发现到 finish 约 1.05 秒；分 applet 存储查询约 868 ms，其他大部分 APDU 为 7–21 ms。说明该查询在成功情况下也明显偏慢，应计入需要保持贴卡的时间。
- 20:51:48 的另一轮设置读取也完整成功，15 条 APDU，发现到 finish 约 1.04 秒，分 applet 存储查询约 869 ms。
- 随后的 NFC Tag 页面读取成功，11 条 APDU 完成，验证了跳过插件自动 NDEF 探测后，Console 自身 NDEF APDU 路径仍可使用。

### 后续 A/C 交错实测

用户反馈 C 组读取体验较好。保留下来的完整原生日志支持 C 缩短发现后的等待：

| 操作 / 组别 | session | 发现至 poll.ready | 自动 NDEF 查询 | 发现至 finish | APDU 数 |
| --- | --- | --- | --- | --- | --- |
| 设置读取 / A | 7 | 225.82 ms | 221.99 ms | 1281.35 ms | 15 |
| 设置读取 / A | 8 | 225.18 ms | 219.79 ms | 1284.31 ms | 15 |
| 设置读取 / C | 6 | 5.20 ms | 跳过 | 1064.89 ms | 15 |
| 设置读取 / C | 17 | 2.63 ms | 跳过 | 1059.86 ms | 15 |
| 设置读取 / C | 20 | 4.43 ms | 跳过 | 1059.01 ms | 15 |
| NFC Tag 读取 / A | 9 | 224.08 ms | 219.85 ms | 373.44 ms | 11 |
| NFC Tag 读取 / C | 18 | 3.01 ms | 跳过 | 113.39 ms | 11 |

同样的设置读取，A 组发现后约 1.28 秒、C 组约 1.06 秒，缩短约 220 ms（约 17%），与 A 组 NDEF 查询耗时相符。C 组在发现后约 3–5 ms 即可返回 poll，A 组则需约 224–226 ms。由此可以确认：跳过自动 NDEF 查询移除了一段可观测的额外等待，缩短用户需要持续稳定贴卡的窗口。它没有增强射频场，也不能据此断言首次发现概率提高。

上述完整样本均未记录诊断错误，但样本很少，且本次提取的运行日志存在截断（session 10 不完整，11–15 缺失），不能把可见样本当作全部尝试来计算成功率。没有可用的 B 组对照，因此还不能单独量化仅扫描 ISO 14443 的影响；`begin→detect` 包含用户移动卡片的时间，也不能用来比较发现速度。

当前保留 C 为默认配置。下一轮若要证明成功率提升，应按第 6 节固定贴卡条件、交错运行 B/C 并完整记录每次尝试；A/B 用来隔离扫描范围。设置页约 868–871 ms 的分 applet 存储查询仍是主要耗时，后续可独立评估按需读取或延后读取，避免它拉长首次结果的等待。

### C 组方案固化

已将 iOS 扫描固定为仅 ISO 14443、跳过插件自动 NDEF 查询，保留会话清理修复和阶段诊断。日志页的 A/B/C 切换入口与实验状态已移除；上文实验版操作步骤仅描述测量时的构建。Console 自身 NDEF APDU 读取路径继续使用。

### 2026-10-21：切换到上游固定 commit

[上游 PR #239](https://github.com/nfcim/flutter_nfc_kit/pull/239) 已合并。Console 改为 Git 依赖，固定到合并 commit `c7079d91c0b336a77ba8ae5c927bcb5889ed57bf`，移除本地插件副本。继续使用 `checkNDEF: false` 和仅 ISO 14443 的 C 组配置，并保留 Dart 侧 poll 失败清理。实验专用的原生阶段诊断通道未进入上游，现已移除相关调用；应用层 poll 耗时及错误日志继续记录。上文阶段日志与实验入口描述的是当时的实验构建。

后续整理：删除实验期独立的 `ios_nfc.dart`，将 iOS 扫描配置、耗时日志与失败清理直接合入现有的 `SmartCard.pollNfcOrWebUsb()`，不再保留单独的 iOS 扫描方法。回归测试直接通过 `pollNfcOrWebUsb()` 检查连接入口。

## 8. PR #234：会话错误分类与在途调用的错误传递

调研日期：2026-10-21；[PR #234](https://github.com/nfcim/flutter_nfc_kit/pull/234) 当前为 OPEN，GitHub 标记与 develop 冲突。审阅的 head 为 `845e8d2c26dfcdc9e652735174dcb4c8648980ce`。维护者已要求解决冲突并移除示例应用的测试界面改动。

### 它解决什么

原插件只把 poll/restartPolling 的等待回调放在 `self.result`。poll 返回后，transceive、NDEF、块读写等操作使用各自局部回调；系统使 session 失效时，delegate 无法把具体会话错误直接交给这些在途调用。调用方可能只收到通信回调的通用 500，不能可靠区分取消与系统原因。

PR 增加 `mapNFCError`，把用户取消映射为 `409 / UserCanceled`、超时为 `408 / SessionTimeOut`、系统忙为 `503 / SystemIsBusy`、意外终止为 `502 / SessionTerminatedUnexpectedly`；通过 `trackResult` 把在途操作放入 `self.result`，让会话失效也能完成操作，并把无待返回回调时的 session/tag 清理移到条件之外。

### 与本次问题的关系

| 问题 | #234 的作用 | 当前 Console / #239 |
| --- | --- | --- |
| 扫描范围、首次发现困难 | 没有改变轮询协议或射频行为 | C 组仅扫描 ISO 14443；其发现成功率收益仍未量化 |
| 连接后的自动 NDEF 等待 | 没有修改 queryNDEFStatus | `checkNDEF: false` 已实测省下约 220 ms |
| poll 返回后的失效清理 | 有重叠，避免无回调时不清理 | #239 已覆盖，并保留旧 session 身份隔离 |
| 读取中取消/系统终止的错误原因 | 有补充价值，可向在途调用返回更具体错误 | 当前普通 APDU 仍使用局部回调，可能只返回通用通信错误 |
| 系统忙后的恢复 | 503 便于应用决定稍后重试 | PR 的退避重试只在示例里，插件本身没有自动重试 |

此前设置读取记录的是 `NFCReaderError 102 / nfcd 29`。本机 CoreNFC SDK 将 102 定义为 TagResponseError，即标签响应无效或未响应，不能据此认定就是 PR 新增分类中的 SystemIsBusy 或 SessionTerminatedUnexpectedly。用户当时可能提前移开卡；没有证据说明 #234 能使那次 APDU 成功。

### 当前实现不能直接采用的原因

1. `trackResult`（head Swift 文件 68–75 行）只检查全局 `self.result != nil`，没有每次调用独立的完成标记或身份。可按顺序触发：旧操作等待 → invalidation 已向旧操作返回错误 → 新 poll 写入 self.result → 旧操作回调迟到。旧 wrapper 会把新 poll 的回调清空，并再次调用旧操作的原始回调。将该函数原样抽入独立 Swift 状态探针后，确定性得到“旧回调调用 2 次、新 poll 回调丢失”；这验证的是回调状态逻辑，不是真机 NFC 复现。不同队列并发也未被当前 PR 完整隔离。
2. head 的 invalidation 处理没有 #235/#239 的 session 身份检查和主队列保护。解决冲突时必须保留这些已经合并的修复，不能用旧 handler 整段覆盖。
3. `409` 的 message 从 `SessionCanceled` 改为 `UserCanceled`。Console 当前仍按前者字符串显示取消提示，直接采用后在该分支会落到通用失败提示；后续宜根据错误 code 分类。

结论：它对诊断读取中断和完善失败处理有价值，与本次会话生命周期问题有交集；不提供已证实的首次发现/完整读取成功率提升，也不替代 C 组优化。值得在 #239 基础上完善每操作的身份与完成状态、回调串行化及取消/新旧会话交错测试后再考虑引入。保持当前固定依赖不变。
