#Requires -Version 5.1
<#
.SYNOPSIS
  Remove Studee local data and Credential Manager secrets on Windows.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\scripts\uninstall_windows.ps1
  powershell -ExecutionPolicy Bypass -File .\scripts\uninstall_windows.ps1 -Yes
#>

param(
  [switch]$Yes
)

$ErrorActionPreference = 'Continue'

function Remove-DirSafe([string]$Path) {
  if (Test-Path $Path) {
    Write-Host "Removing $Path"
    Remove-Item -Recurse -Force $Path -ErrorAction SilentlyContinue
  }
}

if (-not $Yes) {
  $answer = Read-Host 'Xóa dữ liệu Studee trên máy này (AppData + khóa API)? [y/N]'
  if ($answer -notin @('y', 'Y', 'yes', 'YES')) {
    Write-Host 'Đã hủy.'
    exit 0
  }
}

Write-Host '==> Closing Studee if running...'
Get-Process -Name 'studee_pc','Studee' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$LocalAppData = [Environment]::GetFolderPath('LocalApplicationData')
$RoamingAppData = [Environment]::GetFolderPath('ApplicationData')

# Flutter / path_provider common layouts for com.studee / studee_pc
$candidates = @(
  (Join-Path $LocalAppData 'com.studee\studee_pc'),
  (Join-Path $LocalAppData 'com.studee'),
  (Join-Path $RoamingAppData 'com.studee\studee_pc'),
  (Join-Path $RoamingAppData 'com.studee'),
  (Join-Path $LocalAppData 'Studee'),
  (Join-Path $RoamingAppData 'Studee')
) | Select-Object -Unique

foreach ($dir in $candidates) {
  Remove-DirSafe $dir
}

Write-Host '==> Removing Credential Manager entries matching Studee / FlutterSecureStorage...'
try {
  $creds = cmdkey /list 2>$null
  $targets = @()
  foreach ($line in $creds) {
    if ($line -match 'Target:\s*(.+)$') {
      $target = $Matches[1].Trim()
      if ($target -match '(?i)studee|FlutterSecureStorage|com\.studee') {
        $targets += $target
      }
    }
  }
  foreach ($t in ($targets | Select-Object -Unique)) {
    Write-Host "Deleting credential target: $t"
    cmdkey /delete:$t | Out-Null
  }
} catch {
  Write-Host "Credential cleanup skipped: $_"
}

Write-Host 'Done. Xóa thủ công thư mục chứa studee_pc.exe nếu bạn còn giữ bản portable.'
