# 相对上游 vscode 的全部修改

上游基线：`microsoft/vscode` commit **`4fa9fcf245ad90eb1f21fae5ed0511515e068b1d`**
（main 分支 1.139.0，2026-09；CI 通过 `VSCODE_UPSTREAM_COMMIT` 锁定同一提交）。
所有源码级修改均以 `patches/*.patch` 形式提供，`git apply` 即可复现；
新增文件（内置扩展、语言包、图标）不进 patch，单独列在文末。

## 1. `product.json` — 品牌、扩展市场、内置扩展清单

`patches/0001-product-branding-and-marketplace.patch`

- 产品名：`nameShort: 卅码`、`nameLong: 卅码 — 基于 VS Code 的中文编程开发环境`、
  `applicationName: shaoma`（Windows 进程/协议/数据目录全部随产品名，避免使用微软商标）
- **扩展市场**：新增 `extensionsGallery` 指向微软官方市场
  （开源版默认不配置，导致扩展面板无法搜索；个人自用场景接入）
- `builtInExtensions` 三个条目（js-debug-companion / js-debug / js-profile-table）
  增加 `"vsix": ".build/vsix/*.vsix"` 本地引用——规避构建期 GitHub API 限流
  （403），构建前把三个 vsix 手动下载到 `.build/vsix/` 即可
- 保留 `defaultChatAgent`：**不可删除**。上游 welcomeOnboarding 模块在加载期
  `assertDefined(product.defaultChatAgent, ...)`，删除会导致 workbench 启动即抛
  未捕获异常、窗口白屏（曾踩坑）

## 2. `src/main.ts` — 默认简体中文

`patches/0002-default-simplified-chinese-locale.patch`

`createDefaultArgvConfigSync()` 生成的默认 `argv.json` 模板中加入
`"locale": "zh-cn"`，首次启动即为中文界面（配合内置语言包）。

## 3. `gettingStarted.contribution.ts` — 关闭 Copilot 首启引导向导

`patches/0003-disable-copilot-onboarding-by-default.patch`

`workbench.welcomePage.experimentalOnboarding` 默认值 `true → false`。
该向导是 2026 新版首启时全屏挡住的 Copilot 登录/主题引导，对入门用户干扰大。
关闭后首启直接进入欢迎页；需要时在设置中打开，或命令面板执行
`开发人员: Welcome Onboarding 2026`。

## 4. 新增文件（不在 patch 中）

### `extensions/sahou/` — 卅语言内置扩展

独立源码在本仓库 `extension/` 目录，随产品打包时放入上游 `extensions/`，
并附带二进制 `bin/sahou.exe`（卅解释器，构建自 gwqwy/sahou）：

- 语言定义（`.saho` → id `sahou`）、TextMate 语法（双语关键字/内置函数/模块/插值）
- 代码片段、括号/注释配对（`#`）
- `sahou.run` 运行当前文件（`Alt+S`、编辑器标题栏 ▶、构建任务 `Ctrl+Shift+B`）
- 极简 LSP 客户端：spawn `sahou lsp`（stdio JSON-RPC）提供实时诊断
- 补全/悬停（关键字、30 个内置函数、11 个标准库模块，中英双语触发）
- 文档格式化（借临时文件调用 `sahou 格式`）
- 解释器解析顺序：用户设置 `sahou.path` → 内置 `bin/sahou.exe` → PATH

### `extensions/vscode-language-pack-zh-hans/` — 简体中文语言包

直接取自 [microsoft/vscode-loc](https://github.com/microsoft/vscode-loc)
仓库 `i18n/vscode-language-pack-zh-hans`（构建时版本 1.131.0，
`engines: ^1.131.0` 与上游 1.139 兼容；市场接通后可在线更新到最新）。

### 品牌图标 `resources/win32/code.ico`、`code_70x70.png`、`code_150x150.png`

朱红"卅"字形（几何线条，取自 sahou 官方 logo），仓库 `assets/branding/` 提供，
构建时覆盖上游同名文件。

## 未修改的部分

调试、Git、终端、远程开发、设置同步、扩展系统等核心功能全部保持上游原样。
Copilot 扩展保留（需要订阅；首启引导向导见第 3 条）。
