<#
manual_scan.ps1 — 从游戏实录(cliplog)里找出「已被手动测试过」的对话分支（标记法）。

设计（务必与口上里的格式严格一致，否则改写会出错）：
  每个需要手动测试的分支，在口上源码里都长这样（两行都必须是单行、格式规范）：
      ;@AT 待手动测试 K6_EV1_今日首问候        <- 状态标记行
      PRINTL [[MT K6_EV1_今日首问候]]          <- 测试语句行（游戏里真的会打印出来）
  TID 一律以 K<角色号>_ 开头，故从 TID 即可看出是哪个角色的口上。

本脚本两种用法：
  1) 扫描（默认）：
       powershell -File manual_scan.ps1 -CliLog .\cliplog.txt [-OutFile .\test_result.txt]
     从 cliplog 里抓出所有 [[MT <TID>]] 标记、去重，报告（可写入 OutFile）。
  2) 回写（-Apply，需指定 -KojoDir）：
       powershell -File manual_scan.ps1 -CliLog .\cliplog.txt -KojoDir "<口上文件夹>" -Apply
     对扫到的每个 TID，在该文件夹的 .ERB 里：
       · 把  ;@AT 待手动测试 <TID>  改成  ;@AT 测试通过 <TID>
       · 删除对应的  PRINTL [[MT <TID>]]  测试语句行
       · 若该行紧邻其上的一行是守护行  SIF K<id>_MT_ON()  ，一并删除
         （否则守护行会变孤儿，去守护下一行真台词——见 references/11 §11.8）
     只动完全匹配上述单行格式的行，UTF-8 BOM + CRLF 写回。
#>
param(
  [Parameter(Mandatory)][string]$CliLog,
  [string]$KojoDir,
  [string]$OutFile,
  [switch]$Apply
)

$read = New-Object System.Text.UTF8Encoding($false)
$bom  = New-Object System.Text.UTF8Encoding($true)

if (-not (Test-Path -LiteralPath $CliLog)) { Write-Host "找不到日志: $CliLog" -ForegroundColor Red; return }
$log = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $CliLog), $read)

# --- 扫描 cliplog 里所有 [[MT <TID>]] 标记，去重、保序 ---
$found = New-Object System.Collections.Specialized.OrderedDictionary
foreach ($m in [regex]::Matches($log, '\[\[MT\s+(K\d+_[^\]\s]+)\]\]')) {
  $tid = $m.Groups[1].Value
  if (-not $found.Contains($tid)) { $found[$tid] = $true }
}
$tids = @($found.Keys)

# 从 TID 推断涉及的角色号（K6_... -> 6）
$chars = @{}
foreach ($t in $tids) { if ($t -match '^K(\d+)_') { $chars[$Matches[1]] = $true } }

Write-Host ""
Write-Host ("手动测试扫描：cliplog 中共发现 {0} 处已触发的手动测试标记" -f $tids.Count) -ForegroundColor Cyan
if ($tids.Count) {
  Write-Host ("  涉及角色号：{0}" -f (($chars.Keys | Sort-Object | ForEach-Object { "K$_" }) -join ', '))
  Write-Host "  【已触发的分支 TID】"
  $tids | ForEach-Object { Write-Host "     $_" -ForegroundColor Green }
}

# --- 可选：把结果写入 OutFile（供用户/AI 查看）---
if ($OutFile) {
  $sb = @()
  $sb += "【手动测试 · 实录中已触发的分支】（去重，共 $($tids.Count) 处）"
  if ($tids.Count) { $tids | ForEach-Object { $sb += "  $_" } } else { $sb += "  （本次无）" }
  [System.IO.File]::WriteAllText($OutFile, (($sb -join "`r`n") + "`r`n"), $bom)
}

# --- 回写模式 ---
if ($Apply) {
  if (-not $tids.Count) { Write-Host "`n没有可回写的标记。" -ForegroundColor Yellow; return }
  if (-not $KojoDir -or -not (Test-Path -LiteralPath $KojoDir)) {
    Write-Host "`n[X] -Apply 需要有效的 -KojoDir。" -ForegroundColor Red; return
  }
  $want = @{}; $tids | ForEach-Object { $want[$_] = $true }
  $changed = 0; $deleted = 0; $guardsDel = 0; $filesTouched = 0
  foreach ($f in Get-ChildItem -LiteralPath $KojoDir -Filter *.ERB) {
    $arr = ([System.IO.File]::ReadAllText($f.FullName, $read)) -split "`r`n|`r|`n"
    $out = New-Object System.Collections.Generic.List[string]
    $dirty = $false
    foreach ($line in $arr) {
      # 删除：整行恰好是  PRINTL [[MT <TID>]]  且该 TID 已通过
      if ($line -match '^\s*PRINTL\s+\[\[MT\s+(K\d+_[^\]\s]+)\]\]\s*$' -and $want.ContainsKey($Matches[1])) {
        # 连带删除紧邻其上的守护行  SIF K<id>_MT_ON()（否则变孤儿守护下一行真台词）
        if ($out.Count -gt 0 -and $out[$out.Count-1] -match '^\s*SIF\s+K\d+_MT_ON\(\)\s*$') {
          $out.RemoveAt($out.Count-1); $guardsDel++
        }
        $deleted++; $dirty = $true; continue
      }
      # 改写：;@AT 待手动测试 <TID>  ->  ;@AT 测试通过 <TID>
      if ($line -match '^(\s*;@AT\s+)待手动测试(\s+)(K\d+_[^\s]+)(\s*)$' -and $want.ContainsKey($Matches[3])) {
        $out.Add($Matches[1] + '测试通过' + $Matches[2] + $Matches[3] + $Matches[4])
        $changed++; $dirty = $true; continue
      }
      $out.Add($line)
    }
    if ($dirty) {
      $filesTouched++
      [System.IO.File]::WriteAllText($f.FullName, ($out -join "`r`n"), $bom)
      Write-Host ("  改写 {0}" -f $f.Name)
    }
  }
  Write-Host ""
  Write-Host ("完成：{0} 处状态改为 测试通过，删除 {1} 行测试语句 + {2} 行 SIF 守护，涉及 {3} 个文件。" -f $changed, $deleted, $guardsDel, $filesTouched) -ForegroundColor Green
}
