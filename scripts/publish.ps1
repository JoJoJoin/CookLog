<#
.SYNOPSIS
    构建 release APK 并生成自更新所需的 version.json。

.DESCRIPTION
    1. 从 pubspec.yaml 读取 version（versionName+versionCode）。
    2. flutter build apk --release 生成 APK。
    3. 复制为 cooklog-<versionName>.apk，计算 sha256 与文件大小。
    4. 生成 release/version.json。
    随后把 cooklog-<versionName>.apk 与 version.json 作为 GitHub Release 的 asset 上传即可。

.PARAMETER Owner
    GitHub 仓库 owner（用于拼接 apkUrl），默认 airsh。

.PARAMETER Repo
    GitHub 仓库名，默认 CookLog。

.PARAMETER Changelog
    本次更新日志，支持 \n 换行。

.PARAMETER Force
    是否强制更新（forceUpdate=true）。

.EXAMPLE
    ./scripts/publish.ps1 -Changelog "- 新增做菜评分`n- 修复导入合并"
#>
param(
    [string]$Owner = "airsh",
    [string]$Repo = "CookLog",
    [string]$Changelog = "- 例行更新",
    [int]$MinSupportedVersionCode = 1,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# 1. 解析 pubspec version: x.y.z+code
$versionLine = (Select-String -Path "pubspec.yaml" -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
if ($versionLine -notmatch '^(?<name>\d+\.\d+\.\d+)\+(?<code>\d+)$') {
    throw "pubspec.yaml 的 version 格式应为 x.y.z+code，当前为：$versionLine"
}
$versionName = $Matches['name']
$versionCode = [int]$Matches['code']
Write-Host "版本：$versionName ($versionCode)" -ForegroundColor Cyan

# 2. 构建 release APK
Write-Host "构建 release APK..." -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw "flutter build apk 失败" }

$builtApk = "build/app/outputs/flutter-apk/app-release.apk"
if (-not (Test-Path $builtApk)) { throw "未找到构建产物：$builtApk" }

# 3. 复制并计算 sha256 / 大小
if (-not (Test-Path "release")) { New-Item -ItemType Directory -Path "release" | Out-Null }
$apkName = "cooklog-$versionName.apk"
$apkPath = "release/$apkName"
Copy-Item $builtApk $apkPath -Force

$sha256 = (Get-FileHash -Path $apkPath -Algorithm SHA256).Hash.ToLower()
$fileSize = (Get-Item $apkPath).Length
Write-Host "sha256：$sha256" -ForegroundColor Green
Write-Host "大小：$fileSize bytes" -ForegroundColor Green

# 4. 生成 version.json
$apkUrl = "https://github.com/$Owner/$Repo/releases/latest/download/$apkName"
$manifest = [ordered]@{
    versionName             = $versionName
    versionCode             = $versionCode
    minSupportedVersionCode = $MinSupportedVersionCode
    apkUrl                  = $apkUrl
    fileSize                = $fileSize
    sha256                  = $sha256
    forceUpdate             = [bool]$Force
    changelog               = $Changelog
    publishedAt             = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -Path "release/version.json" -Encoding UTF8

Write-Host "已生成 release/version.json 与 $apkPath" -ForegroundColor Green
Write-Host "下一步：把这两个文件作为 GitHub Release（tag v$versionName）的 asset 上传。" -ForegroundColor Yellow
