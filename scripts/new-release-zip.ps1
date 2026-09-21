# Build the portable release zip into release-assets/
# Usage: powershell -ExecutionPolicy Bypass -File new-release-zip.ps1
# NOTE: pass paths without CJK characters on Windows PowerShell 5.1 (script files are
#       read as ANSI when no BOM is present); pipe Chinese paths in via parameters of
#       an inline -Command if needed.
param(
    [string]$BuildDir = 'E:\shaoma-pkg-tmp',
    [string]$OutDir = '..\release-assets',
    [string]$ExcludeData = 'data'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (-not (Test-Path $BuildDir)) { throw "BuildDir not found: $BuildDir" }
$name = "ShaomaCode-win32-x64-portable.zip"
$dst = Join-Path $OutDir $name
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

if (Test-Path $dst) { Remove-Item -Force $dst }
[System.IO.Compression.ZipFile]::CreateFromDirectory($BuildDir, $dst, [System.IO.Compression.CompressionLevel]::Optimal, $false)
$size = [math]::Round((Get-Item $dst).Length / 1MB, 1)
Write-Host "DONE: $dst ($size MB)"
