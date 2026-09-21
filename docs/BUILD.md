# 构建指南（Windows x64）

从 microsoft/vscode 上游源码 + 本仓库补丁，构建出"卅码"便携版。

## 环境要求

| 工具 | 版本 | 说明 |
|---|---|---|
| Node.js | 24.x（与上游 `.nvmrc` 同大版本） | 官方 [vscode 构建要求](https://github.com/microsoft/vscode/blob/main/wiki/How-to-Contribute.md) |
| Python | 3.8+ | node-gyp 需要 |
| Git | 任意近期版本 | |
| Go | 1.23+ | 仅构建卅解释器需要 |
| Visual Studio 2022 Build Tools | 17.x | 工作负载 `Microsoft.VisualStudio.Workload.VCTools`（含 MSVC + Windows SDK） |
| **Spectre 缓解库** | 与 MSVC 工具集同版本 | 组件 ID 形如 `Microsoft.VisualStudio.Component.VC.14.44.17.14.x86.x64.Spectre`，**缺失会在编译原生模块时报 MSB8040** |
| signtool | 随 Windows SDK | 打包末尾的 rcedit 步骤会调用 `signtool.exe`（只做签名探测，不要求真签名），确保其在 PATH |

> 中国网络建议设置：
> `$env:ELECTRON_MIRROR='https://npmmirror.com/mirrors/electron/'`、
> `$env:npm_config_registry='https://registry.npmmirror.com'`；
> 企业代理/证书拦截环境给 Node 加 `--use-system-ca`（信任系统证书库）。

## 步骤

### 1. 卅解释器（若 Release 未提供）

```powershell
git clone --depth 1 https://github.com/gwqwy/sahou.git
cd sahou
GOOS=js GOARCH=wasm go build -o sahou.wasm ./cmd/sahouwasm
go build -o sahou.exe .
```

### 2. VS Code 源码 + 补丁 + 内置扩展

```powershell
git clone --depth 1 https://github.com/microsoft/vscode.git
cd vscode

# 应用全部源码补丁（品牌/市场、默认中文、关闭 onboarding）
git apply ..\sahou-code\patches\*.patch

# 内置扩展：卅语言（解释器二进制随包分发）
Copy-Item -Recurse ..\sahou-code\extension extensions\sahou
New-Item -ItemType Directory -Force extensions\sahou\bin | Out-Null
Copy-Item <卅解释器路径>\sahou.exe extensions\sahou\bin\sahou.exe

# 内置扩展：简体中文语言包（来源 microsoft/vscode-loc 仓库 i18n/vscode-language-pack-zh-hans）
git clone --depth 1 --filter=blob:none --sparse https://github.com/microsoft/vscode-loc.git
Push-Location vscode-loc
git sparse-checkout set i18n/vscode-language-pack-zh-hans
Pop-Location
Copy-Item -Recurse vscode-loc\i18n\vscode-language-pack-zh-hans extensions\

# 品牌图标（可选，替换默认微软图标）
Copy-Force ..\sahou-code\assets\branding\shaoma.ico        resources\win32\code.ico
Copy-Force ..\sahou-code\assets\branding\shaoma_70x70.png  resources\win32\code_70x70.png
Copy-Force ..\sahou-code\assets\branding\shaoma_150x150.png resources\win32\code_150x150.png
```

### 3. 安装依赖并打包

```powershell
npm install        # 首次编译原生模块约 10~30 分钟
npm run gulp vscode-win32-x64
```

产物输出在上层目录 `VSCode-win32-x64\`，双击其中的 `卅码.exe` 即可运行。

> 若 `npm install` 中途失败（例如某原生模块编译报错），修复后直接重跑；
> 注意个别包可能因此**漏跑 install 脚本**，用
> `npm rebuild native-keymap @vscode/policy-watcher @vscode/windows-process-tree @vscode/spdlog node-pty native-is-elevated @vscode/deviceid @vscode/sqlite3 @vscode/windows-mutex @vscode/windows-registry kerberos`
> 强制补编译。`@vscode/fs-copyfile` 在 Windows 上无原生产物属正常现象。

### 4. 一键脚本

`scripts/build.ps1` 封装了 2~3 步，路径按脚本位置自动推导（默认取仓库同级的 `sahou code build\vscode`）：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build.ps1
```

源码在别处时用 `-SourcePath` 指定。

## 常见问题

| 症状 | 原因与处理 |
|---|---|
| `MSB8040: 需要 Spectre 缓解库` | 安装对应版本 Spectre 组件（见环境要求）；用 [vscode-loc 的方法](https://aka.ms/Ofhn4c) 从 VS 安装器单个组件安装 |
| `Cannot find module ...\bindings` 启动即退 | 某原生模块漏编译，见上文 `npm rebuild` 清单 |
| 打包末尾 `spawn signtool.exe ENOENT` | Windows SDK 的 signtool 不在 PATH；把 `C:\Program Files (x86)\Windows Kits\10\bin\<版本>\x64` 加入 PATH 重跑 |
| 下载扩展 403（GitHub API 限流） | product.json 的 `builtInExtensions` 支持 `"vsix": "本地路径"` 字段，手动下载 vsix 后本地引用 |
| 界面不是中文 | 便携 `data/argv.json` 需含 `"locale": "zh-cn"`（首次启动自动生成）；删除 `data\user-data` 后重启可重建 |

## 发布新版本

日常发布**不需要本地构建**。把改动合并到 `main` 并推送后，打标签即可自动发布：

```powershell
git tag v1.0.x
git push origin main v1.0.x
```

GitHub Actions 会自动构建便携版、创建 Release 并上传 `ShaomaCode-win32-x64-portable.zip`。
Actions 页手动触发（Run workflow）只构建并上传 artifact，不发布 Release。
