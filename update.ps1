param([string]$AppRoot = "")
$ErrorActionPreference = "Stop"

# Auto-locate 梦笔生花.exe if not passed
if (-not $AppRoot) {
  $candidates = @()
  foreach ($drive in @("D:","C:","E:","F:")) {
    if (Test-Path "$drive\") {
      $found = Get-ChildItem -Path "$drive\" -Filter "梦笔生花.exe" -Recurse -Depth 3 -ErrorAction SilentlyContinue | Select-Object -First 3
      foreach ($f in $found) { $candidates += $f.DirectoryName }
    }
  }
  if ($candidates.Count -gt 0) { $AppRoot = $candidates[0] }
}
if (-not $AppRoot -or -not (Test-Path (Join-Path $AppRoot "resources\app"))) {
  throw "未自动找到梦笔生花目录，请传入路径：.\update.ps1 -AppRoot 'D:\AI\梦笔生花-0.1.0-便携版'"
}

Write-Host "[梦笔生花] 目标目录: $AppRoot"
$appDir = Join-Path $AppRoot "resources\app"
$manifestUrl = "https://github.com/dlyang5519-afk/mengbi-shenghua-updates/releases/latest/download/latest.json"
$mirrors = @("", "https://gh-proxy.com/", "https://ghfast.top/")

$manifest = $null
$usedPrefix = ""
foreach ($p in $mirrors) {
  try {
    $u = "$p$manifestUrl"
    Write-Host "[梦笔生花] 读取版本清单: $u"
    $manifest = Invoke-RestMethod -Uri $u -TimeoutSec 15
    if ($manifest.patch.url -and $manifest.patch.sha256) { $usedPrefix = $p; break }
  } catch {}
}
if (-not $manifest) { throw "无法连接更新服务器，请检查网络后重试。" }

$staging = Join-Path $AppRoot "_bootstrap_update"
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging -Force | Out-Null
$zipPath = Join-Path $staging "app-patch.zip"
$extDir = Join-Path $staging "extracted"

$downloaded = $false
foreach ($p in @($usedPrefix, "", "https://gh-proxy.com/", "https://ghfast.top/") | Select-Object -Unique) {
  try {
    $dlUrl = "$p$($manifest.patch.url)"
    Write-Host "[梦笔生花] 下载更新包 ($($manifest.build)): $dlUrl"
    Invoke-WebRequest -Uri $dlUrl -OutFile $zipPath -TimeoutSec 60
    $sha = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.IO.File]::ReadAllBytes($zipPath))).Replace("-","").ToLower()
    if ($sha -eq $manifest.patch.sha256.ToLower()) { $downloaded = $true; break }
    Write-Warning "校验码不匹配，切换线路重试..."
  } catch {}
}
if (-not $downloaded) { throw "下载更新包失败或校验未通过。" }

Write-Host "[梦笔生花] 校验通过，正在关闭旧进程并替换程序文件（保留 fonts 与 用户数据）..."
Get-Process -Name "梦笔生花" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extDir)

$bakDir = Join-Path $AppRoot ("程序更新备份\bootstrap-" + (Get-Date -Format "yyyyMMddHHmmss"))
New-Item -ItemType Directory -Path $bakDir -Force | Out-Null
$curDist = Join-Path $appDir "dist"
if (Test-Path $curDist) {
  New-Item -ItemType Directory -Path (Join-Path $bakDir "dist") -Force | Out-Null
  Get-ChildItem $curDist -Force | Where-Object { $_.Name -ne "fonts" } | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $bakDir "dist\$($_.Name)") -Recurse -Force
    Remove-Item $_.FullName -Recurse -Force
  }
}
$curElec = Join-Path $appDir "electron"
if (Test-Path $curElec) {
  Copy-Item $curElec (Join-Path $bakDir "electron") -Recurse -Force
  Remove-Item $curElec -Recurse -Force
}

Get-ChildItem (Join-Path $extDir "dist") -Force | ForEach-Object {
  Copy-Item $_.FullName (Join-Path $curDist $_.Name) -Recurse -Force
}
Copy-Item (Join-Path $extDir "electron") $curElec -Recurse -Force
Copy-Item (Join-Path $extDir "package.json") (Join-Path $appDir "package.json") -Force
Copy-Item (Join-Path $extDir "build-meta.json") (Join-Path $appDir "build-meta.json") -Force

Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "[梦笔生花] 已成功更新至 $($manifest.version) ($($manifest.build))，正在启动..."
Start-Process -FilePath (Join-Path $AppRoot "梦笔生花.exe") -WorkingDirectory $AppRoot