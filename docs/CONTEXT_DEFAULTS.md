# 在线上下文默认值契约

## 修复的问题

原在线适配将 Context 直接交给快照。如果业务只传 userId，但规则约束 appName 或 environment，就可能错误关闭。固定 Node SDK 6.12.2 的[构造与静态上下文](https://github.com/Unleash/unleash-node-sdk/blob/dc113ce745f6c0efe65ae3f6b49a439144ac4aa3/src/unleash.ts)以及 isEnabled/getVariant 方法先合并客户端静态上下文；本项目现在补齐该行为。

## 当前行为

- 在线 Options 增加可选 `environment`，默认 `"default"`，只表示**评估上下文**。
- `Client.evaluate`、`is_enabled`、`evaluate_many`、`get_variant` 都合并配置的 app_name 和 environment；批量调用仍只捕获同一快照代次。
- 调用方显式根字段优先，包括空串或 null，不以真值判断替换。此时约束可能不匹配，这是保留显式值而不是强行回退。
- 合并返回新 Context，不修改原上下文，不丢失 userId、自定义 properties 或其他字段。properties 中的同名项不会盖掉已存在的根默认字段。
- 纯 Snapshot / SnapshotStore 不知道客户端配置，**不自动注入默认值**；调用方可显式使用 `Context.with_defaults(app_name, environment=...)`。
- environment 配置要求非空、按 String.length 最多 128，且不能含 ASCII 控制字符（C0/DEL）。它不选择服务器环境、不改变 URL 或 Token 权限，不能用来跨环境访问服务端配置。服务器返回的配置仍取决于实际端点和凭据。

## 验证与范围

1. 新增一项纯核心回归，验证默认补齐、显式空/null、连续合并、保留用户和自定义属性、原对象不被修改。
2. 新增一项 wasm 在线回归，实际经 Client 构造/刷新后，验证默认和 production 两种配置、四类公开评估入口、显式覆盖、原 Context 保持、非法 environment 拒绝，以及请求路径不被环境配置改变。
3. [针对性差分](<../tools/context-defaults.mjs>)运行固定 Node SDK **实际 isEnabled/getVariant prototype 方法**，配以内存评估核心及与构造函数一致的 staticContext，关闭网络和计数器。与 MoonBit 默认合并后的实际判定比较：**108/108 一致**，涵盖两套默认配置、九种上下文、三个功能和 Boolean/variant 两类判定。

[逐条结果](<../artifacts/context-defaults.json>)记录范围、输入哈希、显式 null/空串与两侧结果。这不是 Node 构造生命周期、网络、metrics 或真实服务器互通测试。MoonBit 在线接线由第二项 wasm 回归覆盖；差分本身运行 JS 纯内核。

```sh
# 首次使用先按差分文档安装固定开发依赖
node tools/context-defaults.mjs
moon test --target wasm --deny-warn
```

新增 API 是源级可选参数/方法，不暴露内部 Map；既有调用不需要新增参数。公共接口变化见[核心接口](<../pkg.generated.mbti>)和[在线接口](<../online/pkg.generated.mbti>)。

## 在线示例配置

[在线示例](<../cmd/live/main.mbt>)增加可选环境变量：

- `UNLEASH_APP_NAME`，默认 moonunleash-live-demo。
- `UNLEASH_CONTEXT_ENVIRONMENT`，默认 default，仅影响本地评估上下文。

既有 URL、Token、flag、userId、loopback 设置继续有效。没有在本环境执行带真实凭据的在线示例；只能说已构建入口，不能据此声称真实服务器接受。
