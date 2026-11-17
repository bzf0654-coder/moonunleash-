# 固定参考 SDK 差分验证计划（执行前冻结）

## 参考与边界

- 官方 npm 包 `unleash-client@6.12.2`，Apache-2.0。
- npm 元数据 gitHead：`dc113ce745f6c0efe65ae3f6b49a439144ac4aa3`。
- tarball integrity：`sha512-aId4dG9E8zEOlOYLVy7YTMHG/gMKQYKDldWvWGt+x1z32a9g+IjlYBsFbqwOpD6T6CvMpCHzX1aONTW5MLVcHA==`。
- 参考来源：[不可变 client.ts](https://github.com/Unleash/unleash-node-sdk/blob/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/client.ts)、[策略集合](https://github.com/Unleash/unleash-node-sdk/blob/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/strategy/index.ts)、[分桶工具](https://github.com/Unleash/unleash-node-sdk/blob/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/strategy/util.ts)。

仅开发验证依赖，通过固定锁文件安装，并禁用生命周期脚本。MoonBit SDK 不依赖、嵌入或调用 Node SDK；只有测试监督程序调用它作为参考。

使用固定版本内部纯评估 Client 与原配 defaultStrategies，不启动网络、metrics 或定时器。内存 repository 只提供原始配置查询，不重写策略逻辑。

## 执行前区分三种样本

1. **官方共同范围：**沿用初始固定的 12 组、93 条官方用例，不移除失败项；Node 参考也须核对原始预期值。MoonBit 输出来自实际编译程序。
2. **共同确定性配置：**固定生成器版本与 seed，64 份 ASCII 稳定身份上下文，与基础/用户/灰度/字符串/数值约束/变体等固定功能矩阵组合。比较 Boolean 和 canonical variant 结果，不根据结果挑选身份。
3. **Unicode 分桶诊断：**执行前阅读参考 util.ts 发现它直接将 JavaScript 字符串交给 murmurhash3js，而 MoonBit 实现使用 UTF-8 字节。额外输入非 ASCII 用户/分组做诊断，单列所有一致与不一致结果，不与共同 ASCII profile 混成“完整兼容通过率”。若不一致，保留样本并公开为互操作限制，不能事后把它从共同必过集合里删除。

随机中间比例、无稳定身份时的随机变体不在逐样本一致性断言中；0/100 边界仍由官方原有用例覆盖。本轮不以统计测试代替随机分布证明，也不报告性能。

## 比较与归一化

- 每一侧都接收同一 state/context/flag/kind；记录语料 SHA-256、版本、seed、case ID 与结果。
- Node 变体仅投影到官方规范中的 name、enabled、feature_enabled、payload。额外的 camelCase featureEnabled 是同义别名；不删除规范内字段或不一致值。
- payload 未定义时统一为缺省字段，而非伪造有效 payload。
- 必过共同 profile 任一不一致或参考偏离官方预期，工具非零退出并留下失败报告；不得通过更换 seed、筛掉样本或修改预期消除失败。
- Unicode 诊断不阻塞工具执行，但必须单列不一致，不得对外称所有样本相同。
- 这不是线上 Unleash 实例、native、TLS 或云端 CI 的证据，也不扩大 93 条官方兼容范围。

## 失败后的处理

先定位输入编码、上下文取值、约束语义或变体选择上的分歧。仅在有明确规范或独立证据时修改实现，并追加最小回归测试；保留首个失败结论。若参考 SDK 与跨语言要求存在已知差异，分别陈述依据与适用范围，不在缺乏证据时断言某一侧普遍正确。
