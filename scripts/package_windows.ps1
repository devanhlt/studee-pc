#Requires -Version 5.1
<#
.SYNOPSIS
  Build a portable Windows release ZIP for Studee.

.DESCRIPTION
  Runs `flutter build windows --release`, copies the Release folder into dist/,
  and adds install/uninstall notes. Must be run on Windows with Flutter + VS
  C++ desktop workload installed.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\scripts\package_windows.ps1
#>

$ErrorActionPreference = 'Stop'

$Root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $Root

function Get-PubspecVersion {
  $line = Get-Content (Join-Path $Root 'pubspec.yaml') |
    Where-Object { $_ -match '^\s*version:\s*' } |
    Select-Object -First 1
  if (-not $line) { return '0.0.0' }
  $raw = ($line -replace '^\s*version:\s*', '').Trim()
  return ($raw -split '\+')[0]
}

$Version = Get-PubspecVersion
$Stamp = Get-Date -Format 'yyyyMMdd-HHmm'
$OutName = "Studee-$Version-windows"
$DistDir = Join-Path $Root 'dist'
$StageDir = Join-Path $DistDir $OutName
$ZipPath = Join-Path $DistDir "$OutName.zip"
$ReleaseDir = Join-Path $Root 'build\windows\x64\runner\Release'

Write-Host "==> Building Windows release (v$Version)..."
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }

if (-not $env:SKIP_BUILD) {
  flutter build windows --release
  if ($LASTEXITCODE -ne 0) { throw 'flutter build windows failed' }
} else {
  Write-Host 'SKIP_BUILD=1 — reusing existing Release folder'
}

if (-not (Test-Path (Join-Path $ReleaseDir 'studee_pc.exe'))) {
  throw "Missing release binary at $ReleaseDir\studee_pc.exe"
}

Write-Host '==> Staging portable package...'
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
if (Test-Path $StageDir) { Remove-Item -Recurse -Force $StageDir }
New-Item -ItemType Directory -Force -Path $StageDir | Out-Null
Copy-Item -Path (Join-Path $ReleaseDir '*') -Destination $StageDir -Recurse -Force

$InstallTxt = @"
STUDEE — Cài đặt trên Windows
=============================

1) Giải nén toàn bộ thư mục này ra một nơi cố định, ví dụ:
   C:\Users\<Bạn>\Apps\Studee\

2) Chạy studee_pc.exe

3) (Tuỳ chọn) Tạo lối tắt trên Desktop / Start Menu trỏ tới studee_pc.exe

Yêu cầu:
- Windows 10/11 64-bit
- Kết nối mạng để dùng DeepSeek / Mathpix (nhập khóa trong Cài đặt)

Quyền riêng tư:
- Camera: Cài đặt Windows → Quyền riêng tư → Camera → bật cho Studee nếu cần
- Chụp màn hình: cho phép khi hệ thống hỏi / kiểm tra Quyền riêng tư

Dữ liệu môn học lưu cục bộ trong thư mục AppData của Windows.
Khóa API lưu trong Windows Credential Manager.
"@

$UninstallTxt = @"
STUDEE — Gỡ cài đặt trên Windows
================================

1) Đóng Studee nếu đang chạy.

2) Xóa thư mục chứa studee_pc.exe (bản portable bạn đã giải nén).

3) Chạy script uninstall_windows.ps1 trong cùng thư mục này
   (hoặc từ repo: scripts\uninstall_windows.ps1) để xóa dữ liệu AppData
   và mục Credential Manager (khóa API).

   powershell -ExecutionPolicy Bypass -File .\uninstall_windows.ps1
"@

Set-Content -Path (Join-Path $StageDir 'HOW_TO_INSTALL.txt') -Value $InstallTxt -Encoding UTF8
Set-Content -Path (Join-Path $StageDir 'HOW_TO_UNINSTALL.txt') -Value $UninstallTxt -Encoding UTF8
Copy-Item (Join-Path $Root 'scripts\uninstall_windows.ps1') (Join-Path $StageDir 'uninstall_windows.ps1') -Force

if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }
Write-Host "==> Creating $ZipPath"
Compress-Archive -Path $StageDir -DestinationPath $ZipPath -Force

Write-Host "Done."
Write-Host "Portable folder: $StageDir"
Write-Host "ZIP:             $ZipPath"
Write-Host "Built:           $Stamp"
