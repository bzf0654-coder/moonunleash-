# MoonUnleash：MoonBit 原生功能开关 SDK

**方向：**工具库 / 成熟生态适配　 **阶段：**开发预览，固定规范本地全覆盖；真实服务及同 SHA 云端验收仍待完成

**GitHub ID：**bzf0654-coder　 **仓库：**[moonunleash-](https://github.com/bzf0654-coder/moonunleash-)　 **许可证：**Apache-2.0

### 问题与通用性

MoonBit 服务融入多语言系统时，需要复用既有 Unleash 发布规则，而不是每次判定访问远端或额外部署其他语言中间服务。本项目提供可复用本地评估库与独立同步适配，不再造管理后台，也不以外部 SDK 代替 MoonBit 内核。

### 固定服务端与完整终点

目标是 **Unleash OSS v7.4.0**，源码提交 `77c5af4d991541a93b877ddac0554beaaf61c8c5`。内置网络使用公开 Client API 注册、全量轮询/ETag 与基础 metrics，不从内部 delta 代码推断 OSS 提供公开 SSE。

完整规范基线为 `Unleash/client-specification@9ef6efa01feabeb699857192ad8106fd7d990235`。结项要求固定 **22 组 / 294 Pass / 0 Fail / 0 NotRun** 覆盖 wasm、wasm-gc、JS、Linux native，另有 **24 项**上游文件完整性校验。公共 delta hydration/events 已实现；SSE 传输、磁盘缓存、OpenFeature、管理后台和完整 A/B 分析不在本期内。规范通过与固定服务端真实互通是两项独立必验。

### 三个完整使用场景

1. **结算灰度与回滚：**服务端配置 rollout 与目标用户，SDK 拉取并安装快照，请求按稳定身份本地判定，业务执行新旧分支；坏配置保留旧状态，超过陈旧阈值按显式 fallback 降级。
2. **推荐 A/B：**在服务端策略内配置 control/treatment 各 50%，通过 backend Token 获取 `strategies[].variants`；SDK 先判断策略约束/灰度，再在首个启用策略内分桶，返回变体及模型 payload。全局 variants 为空，不依赖已弃用环境级变体；曝光和转化由业务另行分析。
3. **租户功能试用：**业务从可信身份生成 tenantId/套餐上下文，SDK 按约束判定并批量使用同一快照；运营修改配置后由轮询更新。不把开关替代认证、授权或计费权益校验。

### 已有实现与验证（2026-11-20 本地）

- 基础/用户/legacy/flexible 策略、remoteAddress 与 IPv4/IPv6/CIDR；字符串/数值/日期/SemVer/正则约束与完整分组。
- 策略级变体、首个启用策略、groupId、payload、旧配置回退，以及 AND 父依赖/变体依赖。
- 私有严格快照、同代次批量评估、last-good/陈旧/关闭；公共原子 delta hydration/events、游标与回放。
- 有界响应 HTTP 适配、ETag/304、超时/退避/作用域取消；有界 yes/no/variant metrics、冻结待发桶、202 确认与独立错误状态。重试为至少一次语义，不承诺持久或恰好一次。
- wasm **96/96**、wasm-gc/JS 各 **81/81** 测试；三个本地后端各 **294 Pass / 0 Fail / 0 NotRun**。测试项包含 suite runner，不能与官方用例数量相加。native 当前只完成本地严格类型检查。
- 旧官方 93 / ASCII 4608、上下文 108、策略变体 1547、父依赖 57 的固定 Node 差分分别保留；不冒充额外官方规范覆盖。
- 原 Unicode 48 项中 Node **20 项差异保留**，分为 7 个 rollout、7 个传播的 feature_enabled、6 个变体；新增冻结的双独立字节参考，**144 个 full uint32 哈希 + 112 个公开 API 判定**已随三后端测试通过。选择明确的 UTF-8 策略，不冒称与 Node 6.12.2 非 ASCII 分桶一致，也不把统一字节编码说成规范已普遍约定。

### 仍需完成与诚实边界

当前变化尚未取得 Linux native 的完整 294 条及新同 SHA 云端证据，固定 v7.4.0 的 wasm/native 真实注册、配置更新、variants/依赖、断线恢复及 metrics 入库验收尚未完成。真实服务验收脚本和 CI 配置不是执行通过记录；可控 loopback HTTP 也不是真实 Unleash。

历史 [M1 四目标 CI](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44337305293)只证明 `25b13135f5cf9ed01c460dd3e587ab44ab9d5756` 当时的 104 条，不挪作当前全量结果。Windows native 运行和 Mooncakes 发布均不作已完成声明。

保留固定参考 SDK 的 **Copyright 2020 Bricks Software AS**、原始许可及改编声明，参见[第三方说明](<../THIRD_PARTY.md>)。AI 辅助开发不等于个人手写声明；参赛者仍需理解实现和负责最终资料，不虚填报名回执或官方认证。

**复现：**`moon test --target wasm --deny-warn`；`node tools/conformance.mjs wasm`；`node tools/unicode-verdict.mjs`（最后一项需固定开发参考依赖，不执行 MoonBit）。

[项目说明](<../README.md>) · [逐用例范围](<COMPATIBILITY_SCOPE.md>) · [metrics 契约](<METRICS.md>) · [构建记录](<BUILD_STATUS.md>) · [发布记录](<PUBLICATION_STATUS.md>)
