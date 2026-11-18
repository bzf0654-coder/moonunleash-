# 申报准备状态（更新于 2026-11-18）

**M1 新增状态：**策略级变体纯评估已实现；本地 wasm 43/43、wasm-gc 33/33、JS 33/33；三者规范均为 104 Pass / 0 Fail / 190 NotRun，13/22 组。新增固定差分 11 条官方及 1536 条矩阵一致，原 93/4608/48 差分不变。源码 `25b1313` 已通过[第五轮四目标 CI](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44337305293)，新 SHA 的 job/step 和四份产物元数据均已核验；真实 v7.4.0 互通仍待验证。完整终点为固定 22 组 294 Pass / 0 Fail / 0 NotRun，见 [M1 契约与边界](<STRATEGY_VARIANTS.md>)；下面 11 月 17 日数据保留为历史。


这是开发预览包的可核查状态，不是“已报名”“官方认证”或生产就绪声明。

**地址更正更新：**用户现已提供实际目标 [moonunleash-](https://github.com/bzf0654-coder/moonunleash-)（末尾有连字符），公开 API 返回 200，确认属于 bzf0654-coder、public、size=0。此前阻塞针对的是不同的无连字符地址；现已核验空引用并首推 8dca496，公开源码已读回。前两轮 CI 暴露并定位工具链 HTTP API 失配；修复后的第三轮四目标全部通过，见[当前发布记录](<PUBLICATION_STATUS.md>)；下面旧阻塞经过仅保留为历史，不再要求用户重复创建。

## 11 月 17 日预览记录（历史）

| 项目 | 实际证据 |
|---|---|
| MoonBit 实现与文档 | 核心、快照生命周期、在线适配、离线/在线示例；见[入口说明](<../README.md>) |
| 构建与测试 | wasm 36/36、wasm-gc 26/26、JS 26/26；Linux native 已过云端检查/测试/规范校验，Windows 仅类型检查通过 |
| 官方规范范围 | 三个已验证后端各 93 Pass / 0 Fail / 201 NotRun，12/22 组；[范围清单](<COMPATIBILITY_SCOPE.md>) |
| 固定参考差分 | Node 6.12.2：93 条原官方用例及 4608 条 ASCII 共同样本一致；[逐项结果](<DIFFERENTIAL_RESULTS.md>) |
| 互操作限制 | 48 条 Unicode 分桶诊断有 20 条不一致；原结果保留，首页已明示 |
| 封装契约修复 | 默认 appName/environment 合并；108 条针对性比较一致；[边界说明](<CONTEXT_DEFAULTS.md>) |
| 实际网络故障验证 | 真实 loopback HTTP，覆盖 200/304、坏 JSON、503、更新、302、流式超限；[结果](<../artifacts/http-smoke.json>) |
| 可复现入口 | 无需服务器的离线示例；带真实服务器环境变量的入口已构建但未实连 |
| 材料与授权来源 | [一页申报稿](<APPLICATION_ONE_PAGE.md>)、[当前官方要求](<OFFICIAL_REQUIREMENTS.md>)、[来源和许可](<../THIRD_PARTY.md>) |
| CI | 修复后的[第三轮](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44096693547)四目标 job/步骤均成功，已核验相同 SHA 的四份新产物元数据；前两轮失败保留 |

测试项包含 suite runner，不能把 36 项当作 35 条完整官方规范。生成 JSON/夹具的行数不是手写实现规模或参赛代码量。

## 此前的外部阻塞（历史，地址已更正）

以下两段记录的是更正前状态；当前源码公开与实际 CI 状态以上文为准。

用户已授权使用独立公开仓库 bzf0654-coder/moonunleash，而不是改动已有 moonshop。但第 4 轮再次访问[目标公开 API](https://api.github.com/repos/bzf0654-coder/moonunleash)仍为 **HTTP 404**；此前账号 SSH 已验证，读取目标也曾返回 Repository not found。404 本身不能区分不存在或非公开，因此不假装知道仓库的后台状态。

尚未添加 remote、未 push、未执行云端 CI、未发布 Mooncakes、未提交官方表单。需要仓库所有者完成公开创建，或提供真正可公开访问的正确仓库 URL。此条件从第 2 轮持续至第 4 轮；本地继续完善不能替代公开入口。申请人资料、参赛群/表单操作按[发布清单](<PUBLICATION_CHECKLIST.md>)由用户确认，不能虚填。

## 仍是后续开发/运行验证，不计为当前已通过

- 真实 Unleash 服务端接受与持续互通：尚无本次授权配置好的实例/凭据；可控 HTTP 服务不是替代证明。
- Windows native C 编译与运行：本机缺少编译器；本机类型检查不能替代运行。Linux native 云端构建测试已通过，不据此声称 native 真实网络 smoke 已跑。
- 完整 22 组规范、metrics、磁盘缓存、OpenFeature 等：不在本次已验证预览范围。
- 正式发布前需要继续评估 Unicode 分桶迁移与真实业务配置；ASCII 样本一致不保证任何配置都可无差异替换。
