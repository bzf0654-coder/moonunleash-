# MoonUnleash

MoonBit-native, explicitly scoped Unleash server-side SDK (work in progress).

目标：直接消费 Unleash Client API 配置，在 MoonBit 中完成稳定灰度、条件约束与实验变体判定。不是官方 SDK，不另建管理后台，不通过外部 SDK 替代评估内核。

## Current status

2026-11-17: isolated repository created; MoonBit compiler v0.10.20 verified. Implementation and conformance work is in progress. No compatibility, publication or production-readiness claim yet.

## Development

```sh
moon check
moon test
moon run cmd/main
```

The initial module name `moonunleash/sdk` is provisional until repository ownership and registry namespace are confirmed.

License: Apache-2.0. Upstream fixtures and references will be attributed in THIRD_PARTY.md.
