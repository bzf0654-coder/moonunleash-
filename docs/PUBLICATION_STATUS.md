# 公开发布与云端验收

## 2026-11-20：当前增量尚待新云端验收

三个本地运行后端已各达到 **294 Pass / 0 Fail / 0 NotRun**，测试为 wasm **96/96**、wasm-gc/JS 各 **81/81**；Windows native 严格类型检查通过。公共 delta、完整约束/依赖、有界 metrics 与独立 UTF-8 Golden 已实现，见[当前验收清单](<ACCEPTANCE.md>)。[新的四目标云端运行](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44689082346)已在 `4249cc378a480f1d2196e02611fd51abb2ca76e1` 全部通过 294/0/0 和严格测试，Linux native 不再只有本地类型检查；[公开证明](<../artifacts/ci-run-44689082346.json>)核对了实际编译器、当前运行验证汇总/摘要及非空同 SHA 产物元数据，未下载原始产物归档。[固定真实服务器门](<REAL_SERVER.md>)已实际启动容器，但前两轮失败于 readiness/bootstrap，修复和失败保留于验收记录；互通与 metrics 数据库读回仍未通过。以下四目标 104 条或93条结果均仅为历史证据，不代表这次 294 条增量的 native、metrics 入库或新同 SHA 云端已经通过。

## 实际发布

用户给出的正确仓库是 [bzf0654-coder/moonunleash-](https://github.com/bzf0654-coder/moonunleash-)（名称末尾有连字符）。公开 API 先确认 owner/public，分支列表与 SSH 远程引用再确认空仓库后，才添加 origin 并普通 push main；没有 force，也未改动已有 moonshop。

首推为 [8dca496](https://github.com/bzf0654-coder/moonunleash-/commit/8dca4960759826d9f5436c0943c24e5aa47076c5)，公开 commit API 与原始一页说明均已读回确认。保留全部本地真实提交，没有为参赛制造提交数。此前反复 404 的是不同的无末尾连字符地址；旧阻塞已解除，不再要求用户重建。

Git 的 MSYS SSH 包装层在工作区沙盒仍触发 IPC 权限错误；批准后对同一完整命令重试，空引用检查和首次推送均成功。未修改全局代理或主机密钥校验。

## 首轮云端验收：确有失败

[SDK checks #1](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44090981004)，head `8dca4960759826d9f5436c0943c24e5aa47076c5`：

| 目标 | 实际 job 结论 |
|---|---|
| JS | success |
| wasm-gc | success |
| wasm | failure，Type check and test 步骤 |
| native | failure，Type check and test 步骤 |

[公开 API 逐步记录](<../artifacts/ci-run-44090981004.json>)保留 run、目标、步骤及新产物元数据。四份产物都存在不等于四个目标通过；失败目标可能只有工具链信息。此文件不冒称下载过产物内容，也不凭元数据猜测确切编译器版本。

下载旧 job 详细日志的公开 API 返回 403、要求管理员权限；公开 annotations 当时只有进程退出码。没有绕过权限获取旧日志。下一次受控运行新增[诊断器](<../tools/ci-command.mjs>)：保存新鲜完整 stdout/stderr、保持子进程失败退出码、将失败诊断和实际工具链以转义后的公开 annotation 输出。日志回显期间暂停工作流命令解析；负向控制验证退出码 7 和两个输出流均被保留。不删除断言、不改变冻结语料，也不把日志改造称为 SDK 修复。

状态读取可复现（只读，无需 Token）：

```sh
node tools/ci-status.mjs 44090981004 8dca4960759826d9f5436c0943c24e5aa47076c5
```

该已失败 run 的读取器预期非零退出；证据先保存，再报告失败，不把读取失败结论包装为绿色。后续重跑须按实际 SHA 与 run 单独记录。

## 第二轮定位与修复候选

[SDK checks #2](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44092864629) 对 c6b088c 再次给出 JS/wasm-gc 成功、wasm/native 失败；[逐步状态](<../artifacts/ci-run-44092864629.json>)与首轮分别保留。新 annotation 明确显示：

- 实际工具链为 moon 0.1.20261117 (eb64713)、moonc v0.10.21+06da1ed44 (2026-11-16)、moonrun 0.1.20261117。
- [wasm 编译诊断](https://api.github.com/repos/bzf0654-coder/moonunleash-/check-runs/134072258870/annotations)及 [native 诊断](https://api.github.com/repos/bzf0654-coder/moonunleash-/check-runs/134072258125/annotations) 都报旧 `@http.request` 不存在，并产生级联 unused_async 错误；不是已观察到的单测逻辑失败。
- 本机 2026-11-04 的接口仍有该函数，而当前上游改为 request_stream。未降级工具链、关闭 deny-warn 或删除测试。

修复候选改用两份已查接口共有的 ClientConnection 构造与 request 方法，显式分离 origin 与原始 path；连接建立后先注册 defer close，再发请求。它仍逐块检查字节限额、拒绝重定向，不换成无界聚合响应。新增白盒回归覆盖端口、嵌套路径、编码路径、IPv6 authority 和保留双斜线；公开 SDK 接口无变化。

本机旧工具链复验已通过：wasm **36/36**、wasm-gc **26/26**、JS **26/26**、native 类型检查及原有真实 loopback HTTP 故障测试。**这仍不是新工具链云端通过；须等待修复提交的独立 CI 结果。**

## 第三轮：四目标实际通过

修复提交 [9bd4255](https://github.com/bzf0654-coder/moonunleash-/commit/9bd4255775b3a654ab22fd76569ae99e3bb1f45f) 的 [SDK checks #3](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44096693547) 结论为 **success**，JS、wasm-gc、wasm、native 四个 job 及其检查/测试、规范校验、离线示例步骤均成功。[本轮 API 证据](<../artifacts/ci-run-44096693547.json>)与两轮失败分别留存。四份非空、未过期产物的元数据与相同 head SHA 均已核对；没有把历史报告复制成新产物。

Native 的[实际工具链 annotation](https://api.github.com/repos/bzf0654-coder/moonunleash-/check-runs/134085569605/annotations) 确认 moon 0.1.20261117 (eb64713)、moonc v0.10.21+06da1ed44。CI 的规范校验器逐项强制每个目标 93 Pass / 0 Fail / 201 NotRun；本地未下载云端产物内容，不能声称已在本机审读或运行 native 报告。真实 loopback HTTP smoke 本轮仅在 wasm job 执行；不扩大为 native 网络或真实 Unleash 服务端接受证据。

这使 Linux native 从“只有源码/类型检查”推进为云端实际构建测试通过。Windows 本机仍无 C 编译器，真实 Unleash、完整规范、Unicode 分桶迁移、metrics 等限制不因 CI 绿色消失。源码和申报概述现在有可公开核查的技术预览与四目标验证入口，适用于申请立项沟通，不是正式报名或完整 SDK 认证。

## 2026-11-18：策略级变体增量与第五轮四目标通过

当前原生实现首个启用策略、策略变体优先级、groupId/stickiness 分桶与旧配置回退，新增第 16 组的 11 条原始用例。三个本地运行后端现为 **104 Pass / 0 Fail / 190 NotRun**，测试项数为 wasm **43/43**、wasm-gc/JS 各 **33/33**；Windows native 仍只有类型检查。

新增差分 v2 为 **11/11 官方 + 1536/1536 矩阵**，0 参考异常；v1 的省略 parameters 参考异常与原始输入保留，见 [M1 记录](<STRATEGY_VARIANTS.md>)。既有 93/4608/48 差分没有变更，20 条 Unicode 差异仍在。版权整改保留了 `Copyright 2020 Bricks Software AS`、原许可和源文件改编说明。

源码提交 [25b1313](https://github.com/bzf0654-coder/moonunleash-/commit/25b13135f5cf9ed01c460dd3e587ab44ab9d5756) 已实际推送。第一次批准的 SSH 推送在上传时被远端断开，之后先核对公开分支仍停在旧 SHA，再重试；未 force push 或改写历史。重试触发的 [SDK checks #5](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44337305293) 为 **success**，native、wasm-gc、JS、wasm 四个 job、检查测试、逐例规范校验与离线示例均成功，JS 新变体差分所在步骤也成功。

[本轮 API 证据](<../artifacts/ci-run-44337305293.json>)保留 job/step 状态及四份非空、未过期、同 SHA 产物的元数据；不声称下载了产物内容或核实了本次安装的具体编译器版本。本轮 Linux native 的规范门槛已是 104 Pass / 0 Fail / 190 NotRun，不再只引用旧 93 条的结果。申请书完整 JSON 也在本地 MoonBit JS 内核实跑 **7/7** 正负例通过；这不是从真实服务端抓包。真实 OSS v7.4.0 互通仍未完成。

## 身份与报名边界

仓库所有者和本次 push actor 是 bzf0654-coder。历史提交沿用本机原有 Git identity，GitHub 将作者映射为 fbzqqqq；未擅自更改全局 identity 或重写作者历史。申请人需要自行确认两者关系及参赛贡献归属，不能由代理推定为同一人。

源码公开不等于正式报名。团队/个人资料、章程确认、入群及表单提交仍需申请人处理或明确授权；无回执不称报名成功。当前完整规范和真实互通状态以本页顶部与验收记录为准；历史段落保留当时边界。Mooncakes 发布与生产就绪仍不作已完成声明。
