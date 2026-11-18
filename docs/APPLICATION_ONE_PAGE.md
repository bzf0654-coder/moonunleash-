# MoonUnleash：MoonBit 原生功能开关 SDK

**方向：**工具库 / 成熟生态适配　 **阶段：**开发预览，完整兼容目标明确但尚未验收

**GitHub ID：**bzf0654-coder　 **仓库：**[moonunleash-](https://github.com/bzf0654-coder/moonunleash-)　 **许可证：**Apache-2.0

### 问题与通用性

MoonBit 服务融入多语言系统时，需要复用既有 Unleash 发布规则，而不是每次判定访问远端或额外部署其他语言中间服务。本项目提供可复用本地评估库与独立同步适配，不再造管理后台，也不以外部 SDK 代替 MoonBit 内核。

### 固定服务端与完整终点

目标是 **Unleash OSS v7.4.0**，源码提交 `77c5af4d991541a93b877ddac0554beaaf61c8c5`。内置网络使用公开 Client API 注册、全量轮询/ETag 与计划中的基础 metrics，不从内部 delta 代码推断 OSS 提供公开 SSE。

完整规范基线为 `Unleash/client-specification@9ef6efa01feabeb699857192ad8106fd7d990235`，结项要求固定 **22 组 / 294 Pass / 0 Fail / 0 NotRun**；24 项上游文件完整性校验和跨语言分桶回归另行保留。delta hydration/events 必须作为公共状态更新能力完整实现；SSE 传输、磁盘缓存、OpenFeature、管理后台和完整 A/B 分析不在本期内。规范通过与固定服务端真实互通是两项独立必验，不用“逐步扩大”替代终点。

### 三个完整使用场景

1. **结算灰度与回滚：**服务端配置 rollout 与目标用户，SDK 拉取并安装快照，请求按稳定身份本地判定，业务执行新旧分支；坏配置保留旧状态，超过陈旧阈值按显式 fallback 降级。
2. **推荐 A/B：**在服务端策略内配置 control/treatment 各 50%，通过 backend Token 获取 `strategies[].variants`；SDK 先判断策略约束/灰度，再在首个启用策略内分桶，返回变体及模型 payload。全局 variants 为空，不依赖已弃用环境级变体；曝光和转化由业务另行分析。
3. **租户功能试用：**业务从可信身份生成 tenantId/套餐上下文，SDK 按约束判定并批量使用同一快照；运营修改配置后由轮询更新。不把开关替代认证、授权或计费权益校验。

### 已有实现与验证

已实现基础/用户策略、legacy/flexible 灰度、基本字符串/数值约束、私有快照及生命周期、上下文默认值、受作用域管理的 HTTP 更新。新增策略级变体、策略顺序、优先级、groupId 分桶与旧配置回退，见 [M1 实施与验证记录](<STRATEGY_VARIANTS.md>)。

当前本地 wasm **43/43**、wasm-gc/JS 各 **33/33**；官方规范各 **104 Pass / 0 Fail / 190 NotRun**，含第 16 组全部 11 条。新增差分 11 条官方及 1536 条矩阵一致；旧 93 条官方/4608 条 ASCII 差分不改写。48 条 Unicode 诊断仍有 20 条不同，结项前须按规范逐项修复或有依据地裁定参考实现差异。

### 仍需完成与诚实边界

M1 纯评估已落地，真实 v7.4.0 配置获取与端到端验收仍待完成；现有真实 loopback HTTP 测试使用可控模拟，不是 Unleash。后续须补高级约束、完整分组、依赖、delta 公共接口、基础 metrics 及余下 190 条官方用例。旧预览曾有四目标云端通过，但本次新增代码的云端结果须单独核验；Windows native 本地仍仅类型检查。

保留固定参考 SDK 的 **Copyright 2020 Bricks Software AS**、原始许可及改编声明，参见[第三方说明](<../THIRD_PARTY.md>)。AI 辅助开发不等于个人手写声明；参赛者仍需理解实现和负责最终资料，不虚填报名回执或官方认证。

**复现：**`moon test --target wasm --deny-warn`；`node tools/conformance.mjs wasm`；`node tools/strategy-variants.mjs`（后者需固定开发参考依赖）。

[项目说明](<../README.md>) · [逐用例范围](<COMPATIBILITY_SCOPE.md>) · [构建记录](<BUILD_STATUS.md>) · [发布记录](<PUBLICATION_STATUS.md>)
