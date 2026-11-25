# 梦笔生花 · 自动更新发布频道

本仓库仅存放「梦笔生花」桌面端编译后的轻量增量更新包（`app-patch.zip` 与 `latest.json`），不含源码、字体与个人书稿。

## 旧版一键升级说明（给另一台电脑上的 AI 或用户）

若目标电脑已有旧版「梦笔生花便携版」（未内置自动更新功能），直接运行本仓库根目录的 [`update.ps1`](./update.ps1) 即可完成一次性升级；**升级后软件即内置自动检查更新，以后无需再手动操作**。

### 升级规则（重要）
- **绝对不要改动或删除** `用户数据/` 目录与 `resources/app/dist/fonts/` 目录。
- 下载 `https://github.com/dlyang5519-afk/mengbi-shenghua-updates/releases/latest/download/app-patch.zip`（直连超时可加 `https://gh-proxy.com/` 前缀），校验 `latest.json` 中的 `sha256`。
- 关闭 `梦笔生花.exe`，将 `resources/app/dist`（保留 `fonts`）、`resources/app/electron`、`package.json`、`build-meta.json` 替换为压缩包内的新文件，随后重启 `梦笔生花.exe`。