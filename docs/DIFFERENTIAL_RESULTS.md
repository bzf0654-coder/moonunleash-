# 固定版本 Node SDK 差分结果

参考 `unleash-client@6.12.2`，gitHead `dc113ce745f6c0efe65ae3f6b49a439144ac4aa3`。依赖锁定并禁用安装脚本。生成器版本 1，seed `1831565813`；初次与当前结果均保留。

## 实际结果（MoonBit JS 后端）

| 执行前确定的 profile | 一致 | 不一致 | 说明 |
|---|---:|---:|---|
| 原固定官方 93 条 | 93 | 0 | Node 同时全部符合原始官方预期 |
| ASCII 共同确定性矩阵 | 4608 | 0 | 36 个功能 × 64 个上下文 × Boolean/variant 两类判定 |
| Unicode 分桶诊断 | 28 | **20** | 单列差异，不算共同范围通过，也不称完整兼容 |

比较的是两侧纯评估内核；不覆盖 Node 顶层 wrapper 注入 appName/environment 等默认上下文，也不证明在线适配在该行为上已对齐。这是功能比较，不是性能、随机分布、真实服务器或 native 测试。额外 4608 条不能冒充新增官方规范覆盖；官方声明范围仍是 12 组 93 条。

- [当前逐条结果](<../artifacts/differential.json>)
- [工具保留的首次结果](<../artifacts/differential.initial.v1.json>)
- [执行前计划](<DIFFERENTIAL_PLAN.md>)
- [确定性生成器](<../tools/generate-differential.mjs>)及[执行器](<../tools/differential.mjs>)

输入语料 SHA-256：`7d801d96ca2820e8ed81e850d2d22c221374dcdd10e985a1ec4b80bf10ed93a8`。工具发现 v1 输入变化时拒绝覆写首次结果。只把 Node 特有的 camelCase featureEnabled 别名投影掉，保留规范内全部状态和 payload。

## 发现的真实互操作风险：非 ASCII 分桶键

MoonBit 明确以 UTF-8 字节执行 MurmurHash3；所固定 Node SDK 把原始 JS 字符串直接传给 murmurhash3js。两者对非 ASCII 输入可能不同。影响的不只是用户 ID，也包括显式 groupId，以及全局变体使用的非 ASCII 开关名。

具体样本：分组 `共享组-🌍`、用户 `用户甲`、37% userId rollout。MoonBit UTF-8 hash 为 `1483014240`，桶为 **41**，因此关闭；参考 Node 原字符串 hash 为 `3785767911`，桶为 **12**，因此开启。这不是“相同算法就必定相同分桶”。官方 suite 18 仅验证 Unicode 名称查询，不能证明 Unicode 灰度一致。

进一步做了**仅用于诊断的编码干预**：不改语料或 MoonBit，不修改安装文件，只在独立进程中临时把 Node primitive 的字符串输入桥接为 UTF-8 字节视图，结束后恢复。原始 SDK 仍保持 20/48 不一致；经过此单一干预，诊断 48/48 与 MoonBit 一致。结果见[编码诊断](<../artifacts/hash-encoding.json>)和[诊断脚本](<../tools/hash-diagnostic.mjs>)。

这支持“该样本范围内的差异来自编码路径”，但**经过修改的参考不再是原始 SDK，不能计为原始 SDK 兼容通过**。额外十个字节哈希向量已加入 [MoonBit 白盒回归](<../sdk_wbtest.mbt>)，并在三个已验证后端通过。

当前决定：保持明确的 UTF-8 策略，不为消除差分而暗改为 Node 字符串行为；也不在缺少统一契约证据时宣称一侧对所有 SDK 普遍正确。业务要求与 Node 6.12.2 精确保持人群一致时，应限定分桶键为 ASCII 并单独验证；非 ASCII 分桶迁移尚不能承诺无变化。

## 复现

要求 Node 24（本机已验证 24.13.1）、MoonBit 已验证工具链和 pnpm 11.28.5。仅开发验证需要参考依赖；纯 MoonBit SDK、原有单元测试和官方 conformance 不需要安装它。

```sh
pnpm --dir tools/reference install --frozen-lockfile --ignore-scripts --node-linker=hoisted
node tools/differential.mjs
node tools/hash-diagnostic.mjs
```

本机使用运行器提供的 Node/pnpm，没有修改全局 PATH、代理或安装全局包。显式 hoisted 布局避免本机 pnpm junction 的模块解析问题；第一次 isolated 布局导入失败，不是评估结果。MoonBit 文件 I/O 使用 JS 宿主读入生成语料；全部开关评估仍由 MoonBit 执行。两个生成的中间 JSON 被忽略，不需要提交。
