# 卅码（Shaoma Code）构建脚本
# 用法：powershell -ExecutionPolicy Bypass -File build.ps1 [-SourcePath <vscode 源码目录>] [-RepoPath <本仓库目录>]
param(
    [string]$SourcePath = '',
    [string]$RepoPath = ''
)

$ErrorActionPreference = 'Stop'
# 默认路径按脚本位置推导：仓库 = scripts\..，构建工作区 = 仓库同级的 "sahou code build\vscode"
if (-not $RepoPath) { $RepoPath = Split-Path $PSScriptRoot -Parent }
if (-not $SourcePath) {
    $workspace = Split-Path $RepoPath -Parent
    $SourcePath = Join-Path $workspace 'sahou code build\vscode'
}

$ErrorActionPreference = 'Stop'
$git = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $git) { $git = 'E:\Git\cmd\git.exe' }

if (-not (Test-Path $SourcePath)) { throw "vscode source not found: $SourcePath" }
Set-Location $SourcePath

Write-Host '==> [1/5] applying patches (branding/marketplace, zh-cn locale, onboarding off)'
& $git apply --check "$RepoPath\patches\*.patch" 2>$null
if ($LASTEXITCODE -eq 0) {
    & $git apply "$RepoPath\patches\*.patch"
    Write-Host '    patches applied'
} else {
    Write-Host '    patches already applied (or conflict), skipping'
}

Write-Host '==> [2/5] syncing builtin extension: sahou'
Copy-Item -Recurse -Force "$RepoPath\extension\*" "$SourcePath\extensions\sahou\"

Write-Host '==> [3/5] preparing marketplace vsix cache (.build/vsix)'
New-Item -ItemType Directory -Force -Path "$SourcePath\.build\vsix" | Out-Null

Write-Host '==> [4/5] npm install (skip if node_modules ready and no source change)'
if (-not (Test-Path "$SourcePath\node_modules\.install-finished")) {
    $env:ELECTRON_MIRROR = 'https://npmmirror.com/mirrors/electron/'
    $env:npm_config_registry = 'https://registry.npmmirror.com'
    $env:NODE_OPTIONS = '--use-system-ca'
    npm install
    if ($LASTEXITCODE -ne 0) { throw 'npm install failed' }
    New-Item "$SourcePath\node_modules\.install-finished" | Out-Null
}

Write-Host '==> [5/5] gulp vscode-win32-x64'
$env:ELECTRON_MIRROR = 'https://npmmirror.com/mirrors/electron/'
$env:NODE_OPTIONS = '--use-system-ca --max-old-space-size=8192'
# signtool (from Windows SDK) is required by the packaging tail step
$signtool = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($signtool) { $env:PATH = "$($signtool.DirectoryName);$env:PATH" }
npm run gulp vscode-win32-x64
if ($LASTEXITCODE -ne 0) { throw 'build failed' }

$out = Join-Path (Split-Path $SourcePath -Parent) 'VSCode-win32-x64'
Write-Host "DONE. Portable build at: $out"
