# 发布与报名交接清单

这是待办，不是已完成记录。账号、个人资料和对外发布由申请人决定；不把本地 Git 身份推断为 GitHub 仓库所有权。

## 需要申请人确认

- [x] 用户确认 GitHub ID 为 bzf0654-coder；SSH 认证也返回该账号。
- [ ] 确认单人/组队身份；如组队，确认不超过三人与队长信息。
- [x] 已授权独立发布，不改动已有 moonshop 电商项目；用户已更正实际目标为 [moonunleash-](https://github.com/bzf0654-coder/moonunleash-)（末尾有连字符）。
- [x] 公开 API 已核验实际目标所属账号、public 状态和空仓库元数据。
- [x] 确认远程引用为空后首推 8dca496；不使用 force。公开 commit 与一页说明均已读回，见[发布实录](<PUBLICATION_STATUS.md>)。
- [x] 修复 9bd4255 的[第三轮 CI](https://github.com/bzf0654-coder/moonunleash-/actions/runs/44096693547)四目标成功，job/步骤及同 SHA 的新产物元数据已读取；未冒称下载产物内容。
- [ ] 确认历史 Git 作者 fbzqqqq 与参赛账号 bzf0654-coder 的关系及贡献归属；未擅自改作者或重写历史。
- [ ] 阅读[一页说明](<APPLICATION_ONE_PAGE.md>)，替换身份与公开仓库链接，不编造个人经历、用户采纳或已经掌握的工程经验。
- [ ] 阅读[第三方声明](<../THIRD_PARTY.md>)和[兼容边界](<COMPATIBILITY_SCOPE.md>)，接受开发预览版的限制。

## 发布时

1. 在有权限的 GitHub 账号下建立空仓库；不要另建 [README](<../README.md>) 或覆写本地历史。
2. 确认没有真实 Token、个人联系方式或其他不应公开的信息。凭据从进程环境传入，不提交到仓库，也不要发到聊天里。
3. 在项目根目录复查：

   ```sh
   git status --short
   git remote -v
   moon fmt --check
   moon test --target wasm --deny-warn
   node tools/conformance.mjs wasm-gc
   node tools/http-smoke.mjs
   ```

4. 只有在确认授权和目标后才添加/使用远端并 push；不用 force push，不删除真实阶段提交。当前环境未安装 gh，不能把一个未经验证的 gh 命令当成已发布记录。
5. 读取真实 GitHub Actions 运行结果及其新产物。未执行、失败或只上传历史文件均不是 CI 通过；native 只有跑过才能改成已验证。
6. 将真实仓库 URL 写入[模块元数据](<../moon.mod>)和[一页说明](<APPLICATION_ONE_PAGE.md>)，复查链接在公开仓库中可访问。临时命名空间不等于已获得 Mooncakes 发布权限。

## 报名时

- [ ] 登录[官方十一月赛报名入口](https://bxup9uklfcb.feishu.cn/share/base/form/shrcnWUMlgpbwHaXgzV7HmNhNhg)，核对表单当时实际字段。
- [ ] 读取正式章程，确认具体截止日、是否仍接收本期项目以及团队要求；不要从旧赛事推断。
- [ ] 提供真实公开仓库、一页概述和所需个人信息；已有/新建项目按事实填写。
- [ ] 加入官方赛事交流群，群昵称设为 GitHub ID；入口与小助手见[官方主页](https://moonbitlang.github.io/Hackathon2026/)。
- [ ] 由申请人确认提交；保留实际回执。没有回执就不记录为报名成功，更不能写已审核通过。

[当前官方要求核对](<OFFICIAL_REQUIREMENTS.md>)记录了来源和未能取得的正式章程全文。公开、报名或奖励均不因本地测试通过而自动成立。
