# 公开发布与云端验收

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

## 身份与报名边界

仓库所有者和本次 push actor 是 bzf0654-coder。历史提交沿用本机原有 Git identity，GitHub 将作者映射为 fbzqqqq；未擅自更改全局 identity 或重写作者历史。申请人需要自行确认两者关系及参赛贡献归属，不能由代理推定为同一人。

源码公开不等于正式报名。团队/个人资料、章程确认、入群及表单提交仍需申请人处理或明确授权；无回执不称报名成功。真实 Unleash 互通、完整规范、Mooncakes 发布和生产就绪仍不在已通过声明内。
