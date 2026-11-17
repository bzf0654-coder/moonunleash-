# MoonUnleash

**用 MoonBit 接入成熟的 Unleash 功能开关平台。** 本地评估、稳定灰度、实验变体和可解释的故障行为，不再造管理后台。

> 开发预览版；非 Unleash 官方 SDK。已验证明确范围内的兼容性，不是完整兼容或生产就绪声明。模块名 `moonunleash/sdk` 暂定，尚未发布到 Mooncakes。

## 解决什么问题

MoonBit 服务需要与 Go/Java/Node 服务共享已有的发布规则，而不是每次判定调用远程服务，或额外部署一个其他语言的中间服务。MoonUnleash 将官方配置解析、策略评估、分桶和变体选择放在 MoonBit 内完成，网络层只负责更新本地快照。

适用于功能渐进开放、新旧实现切换、稳定用户分流。功能开关不是身份认证或权限控制的替代品。

## 已完成

- 基础策略、userWithId、flexibleRollout、legacy 用户/会话/随机灰度。
- IN/NOT_IN、字符串和数值约束；分群引用的核心模型。
- 全局多变体、权重、override、payload 与 custom stickiness。
- 私有配置快照，严格拒绝未知语义、重复字段、非法配置。
- 单所有者 SnapshotStore：批量单快照评估、代次、就绪、陈旧、过期策略、关闭。
- 在线适配：注册、HTTP/HTTPS、周期刷新、超时、退避、ETag/304、作用域取消。
- 坏配置和网络错误不会清空最近有效快照；响应读取期间执行大小限制；不携带凭据跟随重定向。

## 快速运行（从源码）

已验证工具链：Moon CLI `0.1.20261104 (940aa18)` / moonc `v0.10.20+65efd5b93`。

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
| wasm | 核心与在线故障/生命周期测试共 32 项通过 |
| wasm-gc | 纯核心 24 项通过；在线适配不支持此后端 |
| JavaScript | 纯核心 24 项通过；在线适配尚未提供 |
| native | 有适配源码；本机缺少 MSVC，尚未验证通过 |

测试项数量包含 12 个上游 suite runner，每个 runner 内有多条官方断言，不能把 32 项解释为 32 条完整官方规范用例。完整版本与限制见[构建状态](<docs/BUILD_STATUS.md>)及[范围清单](<docs/COMPATIBILITY_SCOPE.md>)。

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

官方测试基线固定为 [client-specification 9ef6efa](https://github.com/Unleash/client-specification/tree/9ef6efa01feabeb699857192ad8106fd7d990235)。22 组共有 294 条；当前执行 01—05、07—12、18 共 12 组，**93 条通过，201 条明确未执行**，没有把未执行部分计为通过。三个已验证后端均生成[逐用例报告](<docs/COMPATIBILITY_SCOPE.md>)。

```sh
node tools/conformance.mjs wasm-gc
node tools/conformance.mjs wasm
node tools/conformance.mjs js
```

报告由 MoonBit 实际评估输出；Node 校验来源、清单及每条状态。后端标签由编译期配置产生，避免命令行参数误标。

- 未支持的非空策略级变体、依赖及未知运算符会导致**整份新快照被拒绝**；可能阻止其他开关更新，不会静默忽略。
- SemVer/日期、remoteAddress、依赖、策略级变体、增量、正则/CIDR 尚未声明支持；分群完整上游 suite 也尚未验收。
- 尚无磁盘缓存、metrics 上报、OpenFeature Provider、性能承诺及真实 Unleash 互通验收记录。
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

[一页项目说明](<docs/APPLICATION_ONE_PAGE.md>)、[官方要求核对](<docs/OFFICIAL_REQUIREMENTS.md>)及[开发历程](<docs/DEVELOPMENT_STORY.md>)已备草稿；申请人身份、公开仓库归属和报名仍待确认，不代表已获得 MoonBit 或 Unleash 官方认可。当前适用的是十一月黑客松，不能混用 2—4 月旧赛事的提交次数与支持金额要求。

[CI 配置](<.github/workflows/ci.yml>)覆盖四后端矩阵并上传本次运行产生的报告，不冒用仓库里已有的历史摘要。**尚未发布仓库、未运行云端 CI，也没有 native 通过证据。** CI 暂随官方稳定工具链并记录实际版本，本地已验证的精确版本见上文；历史发行标签尚未验证，不捏造可用的固定下载地址。

[Apache-2.0](<LICENSE>)；上游资料、算法来源及 AI 辅助说明见[第三方声明](<THIRD_PARTY.md>)。
