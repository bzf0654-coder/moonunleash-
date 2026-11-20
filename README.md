# MoonUnleash

**用 MoonBit 接入成熟的 Unleash 功能开关平台。** 本地评估、稳定灰度、实验变体和可解释的故障行为，不再造管理后台。

> 开发预览版；非 Unleash 官方 SDK。已验证明确范围内的兼容性，不是完整兼容或生产就绪声明。模块名 `moonunleash/sdk` 暂定，尚未发布到 Mooncakes。

**已发现的互操作限制：**与固定 Node SDK 6.12.2 比较，4608 个 ASCII 共同样本一致；48 个 Unicode 分桶诊断中有 **20 个不一致**，来自不同字符串编码路径。非 ASCII 的分组、身份或全局变体开关名可能改变人群分配；不能承诺与该 SDK 无差异迁移。原20差异仍完整保留；固定规范未明确裁定 Unicode hash 编码。本实现选择无归一化 UTF8，经双独立参考冻结并与固定 Rust 实现先例核对，详见[Unicode 裁定与原始差异](<docs/UNICODE.md>)及[差分诊断](<docs/DIFFERENTIAL_RESULTS.md>)。

## 解决什么问题

MoonBit 服务需要与 Go/Java/Node 服务共享已有的发布规则，而不是每次判定调用远程服务，或额外部署一个其他语言的中间服务。MoonUnleash 将官方配置解析、策略评估、分桶和变体选择放在 MoonBit 内完成，网络层只负责更新本地快照。

适用于功能渐进开放、新旧实现切换、稳定用户分流。功能开关不是身份认证或权限控制的替代品。

## 已完成

- 基础策略、userWithId、flexibleRollout、legacy 用户/会话/随机灰度。
- IN/NOT_IN、字符串/数值/日期/SemVer 约束、完整分群引用、IPv4/IPv6/CIDR 和 remoteAddress。
- 原生 MoonBit 正则 VM 及有界 RE2 适配；见[方言、资源限制与证据](<docs/REGEX.md>)，不依赖 JS RegExp 或 Node 生产包装器。
- 策略级多变体、首个匹配策略优先、groupId 分桶、stickiness、payload，以及旧全局变体回退；见 [M1 契约、回归与首败记录](<docs/STRATEGY_VARIANTS.md>)。
- AND 父依赖与变体依赖；原子公共 delta hydration/events、回放游标及显式重同步，见[状态接口](<docs/DELTA.md>)；不等于 SSE 传输。
- 私有配置快照，拒绝未知策略、重复字段和非法结构；结构有效的未知约束运算符依官方规范在反转前 fail closed，不影响无关开关更新。
- 单所有者 SnapshotStore：批量单快照评估、代次、就绪、陈旧、过期策略、关闭。
- 在线适配：注册、HTTP/HTTPS、周期刷新、超时、退避、ETag/304、作用域取消；有界 yes/no/variant metrics、冻结待发桶及仅 202 确认，见[计数、重试和关闭契约](<docs/METRICS.md>)。
- 在线评估补齐 appName/environment 默认上下文，保留调用方显式值，覆盖单项/批量/变体入口；见[上下文契约与验证](<docs/CONTEXT_DEFAULTS.md>)。
- 坏配置和网络错误不会清空最近有效快照；响应读取期间执行大小限制；不携带凭据跟随重定向。

## 快速运行（从源码）

已验证工具链：本地 Moon CLI `0.1.20261104 (940aa18)` / moonc `v0.10.20+65efd5b93`；四后端云端 Moon `0.1.20261119 (738607b)` / moonc `v0.10.22+124d61d05`（以实际运行 annotation 为准，不由 stable 标签推断）。

```sh
moon check --deny-warn --target wasm
moon test --deny-warn --target wasm
moon test --deny-warn --target wasm-gc
moon test --deny-warn --target js
moon run cmd/main --target wasm-gc
```

最后一条运行[离线示例](<cmd/main/main.mbt>)，不需要服务器、Token、Docker 或 npm 包，输出用户分桶和变体的 JSON。

| 后端 | 当前证据 |
|---|---|
| wasm | 本地 96/96 项测试；全部 294/294 条官方规范 |
| wasm-gc | 本地 81/81 项测试、294/294 条；在线适配不支持此后端 |
| JavaScript | 本地 81/81 项测试、294/294 条；在线适配尚未提供 |
| native | Linux 云端严格检查/测试、离线示例与 294/294 条已通过；Windows 本地仍仅类型检查 |

[四目标全量云端通过](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44689082346)对应 `4249cc378a480f1d2196e02611fd51abb2ca76e1`；[公开运行证明](<artifacts/ci-run-44689082346.json>)逐目标核对了 22 组、294/0/0、24 项哈希和报告摘要，而非只看绿色图标。真实 Unleash wasm/native 互通仍单独验收，不由此推断通过。

测试项数量包含 suite runner，每个 runner 内有多条官方断言，不能把 96 项解释为 96 条官方规范用例。全部 24 项上游 SHA-256 校验仍通过。完整版本与限制见[构建状态](<docs/BUILD_STATUS.md>)、[范围清单](<docs/COMPATIBILITY_SCOPE.md>)及[完整验收账](<docs/ACCEPTANCE.md>)。

## 真实 HTTP 故障演示

需要 Node.js 24 和 MoonBit，不需要额外 npm 包：

```sh
node tools/http-smoke.mjs
```

它临时绑定本机随机端口，运行实际 MoonBit HTTP 客户端，依次验证有效配置、304、坏 JSON、503、有效新配置、拒绝重定向以及 chunked 超大响应。服务退出时释放端口。

**这是可控 HTTP 服务，不是真实 Unleash 实例。** 已生成的[HTTP 验证摘要](<artifacts/http-smoke.json>)不能用来证明完整 Unleash 互操作。

## 连接自己的 Unleash

提供[在线示例](<cmd/live/main.mbt>)，凭据只从进程环境读取。PowerShell 示例：

```powershell
$env:UNLEASH_URL = 'https://your-unleash.example/api/'
# 通过你的安全方式设置 UNLEASH_API_TOKEN，不要把真实 Token 写进源码或提交记录。
$env:UNLEASH_FLAG = 'checkout'
$env:UNLEASH_USER_ID = 'demo-user'
moon run cmd/live --target wasm
```

API Token 的作用域决定可见项目和环境，不是 context.environment。开发时如使用本机明文 HTTP，必须额外设置 `UNLEASH_ALLOW_HTTP_LOOPBACK=1`；不允许远程明文 HTTP。服务配置需要处于当前支持范围内。

在线使用首选 `with_client`：回调退出时取消后台轮询和在途请求；显式 close 也会取消受管理的轮询。手动调用 Client::refresh 时，请求任务由调用方持有，调用方需负责其作用域取消；close 仍会拒绝安装迟到结果。

## 兼容性与限制

官方测试基线固定为 [client-specification 9ef6efa](https://github.com/Unleash/client-specification/tree/9ef6efa01feabeb699857192ad8106fd7d990235)。本地 wasm、wasm-gc、JS 均执行全部 22 组，达到 **294 Pass / 0 Fail / 0 NotRun**，各有[逐用例报告](<docs/COMPATIBILITY_SCOPE.md>)。原始用例和期望未修改；19/20 通过公共 delta API 安装状态。当前改动的 Linux native 执行与同 SHA 云端证明仍待完成，不能用旧 104 条云端结果顶替。

```sh
node tools/conformance.mjs wasm-gc
node tools/conformance.mjs wasm
node tools/conformance.mjs js
```

报告由 MoonBit 实际评估输出；Node 校验来源、清单及每条状态。后端标签由编译期配置产生，避免命令行参数误标。

- 非法结构、未知策略及超出安全预算的配置仍会导致**整份新快照被拒绝**，可能阻止其他开关更新；保留最近有效快照。结构有效的未知运算符不会通过反转打开功能。
- 全部官方规范本地通过不等于每个 RE2/JavaScript 扩展均兼容，也不消除上文 Unicode 分桶差异；精确边界见[范围清单](<docs/COMPATIBILITY_SCOPE.md>)。
- 项目终点是固定 22 组 **294 Pass / 0 Fail / 0 NotRun** 的四后端证据，加固定 OSS v7.4.0 真实互通（提交见 [M1 记录](<docs/STRATEGY_VARIANTS.md>)）。当前只完成三个本地规范门，真实服务端验收尚未完成。
- 已实现基础 metrics 及其单元/生命周期回归，真实服务端接收与入库仍待独立验收；计数不是 A/B 曝光或转化归因。尚无磁盘缓存、OpenFeature Provider、性能承诺及真实 Unleash 互通通过记录。
- 默认继续使用最近有效快照并标记陈旧；可设置 max_stale 后按应用显式 fallback 降级。关闭功能不是瞬间全局生效。
- 当前标准库时钟为 Unix epoch 毫秒；检测回拨后保守停止使用旧快照判定，直到全量有效响应重建新鲜度，不将它冒称单调时钟。
- 在线适配使用当前 core/async 实验性 API，固定工具链很重要。单异步运行时模型，不声明跨 OS 线程安全。

## 复现上游资料

源码已包含固定资料和生成绑定；正常测试不需要下载：

```sh
node tools/generate-fixtures.mjs
```

该脚本先校验哈希，再生成绑定和全量清单。需要重新下载固定来源时运行 `node tools/fetch-spec.mjs`。不要修改上游预期结果以使测试通过。

## 项目状态与许可

[一页项目说明](<docs/APPLICATION_ONE_PAGE.md>)、[官方要求核对](<docs/OFFICIAL_REQUIREMENTS.md>)及[开发历程](<docs/DEVELOPMENT_STORY.md>)已备草稿；用户提供的实际公开目标为 [bzf0654-coder/moonunleash-](https://github.com/bzf0654-coder/moonunleash-)（末尾有连字符），已核验空引用后完成首推，源码和历史已公开；不改动已有 moonshop。此前不带末尾连字符的地址返回 404，并非当前目标。个人报名信息仍待填写。这不代表已获得 MoonBit 或 Unleash 官方认可。当前适用的是十一月黑客松，不能混用 2—4 月旧赛事的提交次数与支持金额要求。

**历史 M1 策略级变体增量通过了 [SDK checks #5](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44337305293)**，验证源码提交 `25b13135f5cf9ed01c460dd3e587ab44ab9d5756`。四目标的检查、测试、104 条规范校验和离线示例均成功，JS 还执行新增变体差分；[本轮公开 API 证据](<artifacts/ci-run-44337305293.json>)记录同 SHA 的四份产物元数据，未下载或冒称审读产物内容。

[CI 配置](<.github/workflows/ci.yml>)覆盖四后端矩阵并上传本次运行产生的报告，不冒用仓库里已有的历史摘要。**源码已公开；修复后的 [SDK checks #3](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44096693547) 四目标全部通过**，验证提交为 `9bd4255`。前两轮 wasm/native 的实际失败及实验性 HTTP API 迁移过程均保留，详见[发布与 CI 记录](<docs/PUBLICATION_STATUS.md>)。 CI 暂随官方稳定工具链并记录实际版本，本地已验证的精确版本见上文；历史发行标签尚未验证，不捏造可用的固定下载地址。

[Apache-2.0](<LICENSE>)；上游资料、算法来源及 AI 辅助说明见[第三方声明](<THIRD_PARTY.md>)。
