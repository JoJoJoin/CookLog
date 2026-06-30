<#
.SYNOPSIS
    Create a stable release signing key and configure local key.properties + GitHub Secrets.

.DESCRIPTION
    Fixes "update package signature does not match installed app": local and CI builds
    will both sign with the same release key.
    1. Generate android/app/release.keystore (if missing).
    2. Write android/key.properties (already gitignored, never committed).
    3. Upload keystore (base64) + passwords + alias to repo GitHub Secrets for CI:
       KEYSTORE_BASE64 / KEYSTORE_STORE_PASSWORD / KEYSTORE_KEY_PASSWORD / KEYSTORE_KEY_ALIAS.

    Requires gh CLI logged in (gh auth status). Password is read securely (no echo).
    IMPORTANT: back up release.keystore and the password. Losing them means you can no
    longer ship upgradable builds.

.EXAMPLE
    ./scripts/setup-signing.ps1
#>
param(
    [string]$Repo = "JoJoJoin/CookLog",
    [string]$Alias = "cooklog"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# Locate keytool
if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME "bin\keytool.exe"))) {
    $keytool = Join-Path $env:JAVA_HOME "bin\keytool.exe"
} else {
    $keytool = "keytool"
}

# Locate gh
$ghCmd = Get-Command gh -ErrorAction SilentlyContinue
if ($ghCmd) {
    $gh = $ghCmd.Source
} else {
    $gh = @(
        "$env:ProgramFiles\GitHub CLI\gh.exe",
        "$env:LOCALAPPDATA\Programs\GitHub CLI\gh.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $gh) { throw "gh CLI not found. Install it and run: gh auth login" }

$keystore = "android/app/release.keystore"

# Read password securely (no echo)
$sec = Read-Host "Enter/Set keystore password (remember and back it up!)" -AsSecureString
$plain = [System.Net.NetworkCredential]::new("", $sec).Password
if ([string]::IsNullOrWhiteSpace($plain)) { throw "Password must not be empty" }

if (Test-Path $keystore) {
    Write-Host "Reusing existing $keystore (make sure the password above matches it)." -ForegroundColor Yellow
} else {
    Write-Host "Generating new release key: $keystore" -ForegroundColor Cyan
    & $keytool -genkeypair -v `
        -keystore $keystore -alias $Alias `
        -keyalg RSA -keysize 2048 -validity 10000 `
        -storepass $plain -keypass $plain `
        -dname "CN=CookLog, O=airsh, C=CN"
    if ($LASTEXITCODE -ne 0) { throw "keytool generation failed" }
    Write-Host "Generated $keystore" -ForegroundColor Green
}

# Write local key.properties (storeFile is relative to the android/app module dir)
@"
storeFile=release.keystore
storePassword=$plain
keyPassword=$plain
keyAlias=$Alias
"@ | Set-Content -Path "android/key.properties" -Encoding ASCII
Write-Host "Wrote android/key.properties" -ForegroundColor Green

# Configure GitHub Secrets (values via stdin, not as command-line args)
Write-Host "Setting GitHub Secrets on $Repo ..." -ForegroundColor Cyan
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path $keystore)))
$b64    | & $gh secret set KEYSTORE_BASE64         -R $Repo
$plain  | & $gh secret set KEYSTORE_STORE_PASSWORD -R $Repo
$plain  | & $gh secret set KEYSTORE_KEY_PASSWORD   -R $Repo
$Alias  | & $gh secret set KEYSTORE_KEY_ALIAS      -R $Repo

Write-Host "Done. Future v* tags will be signed with this same key." -ForegroundColor Green
Write-Host "REMINDER: back up android/app/release.keystore and the password." -ForegroundColor Yellow
