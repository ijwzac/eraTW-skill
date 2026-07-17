<#
disarm_autotest.ps1 — comment out (or restore) the AUTOTEST trigger hook in a kojo.

The hook is a standardized, delimited block at the top of the 会話 handler:
    ;=== AUTOTEST 钩子（临时，交付前必须删除；见 M_KOJO_K{id}_AUTOTEST.ERB）===
    IF !TCVAR:{id}:399
        CALL M_KOJO_K{id}_AUTOTEST
        RETURN 1
    ENDIF
    ;=== end AUTOTEST 钩子 ===

Because the guard defaults to 0 (= armed) — which is also a fresh player's state — a
left-in hook makes a player's first 会話 dump the test. Once you've finished autotesting,
disarming stops 会話 from ever triggering it again.

This script only touches the lines BETWEEN the two `;=== … 钩子 …` marker comments, and
only toggles a leading `;` on them, so it is safe and reversible.

USAGE:
  powershell -File disarm_autotest.ps1 -KojoDir "<kojo folder>"          # comment out (disarm)
  powershell -File disarm_autotest.ps1 -KojoDir "<kojo folder>" -Rearm   # restore (re-arm)
#>
param(
  [Parameter(Mandatory)][string]$KojoDir,
  [switch]$Rearm
)

$read = New-Object System.Text.UTF8Encoding($false)
$bom  = New-Object System.Text.UTF8Encoding($true)

if (-not (Test-Path -LiteralPath $KojoDir)) { Write-Host "Kojo folder not found: $KojoDir" -ForegroundColor Red; return }

# region markers
$startPat = '^\s*;===\s*AUTOTEST\s*钩子'      # start marker ("AUTOTEST 钩子…")
$endPat   = '^\s*;===\s*end\s*AUTOTEST\s*钩子' # end marker  ("end AUTOTEST 钩子…")
# lines inside the region that are (commented) hook code — used to recognise what to re-arm
$codePat  = '^\s*;\s*(IF\b|CALL\b|RETURN\b|ENDIF\b)'

$hitFiles = 0; $touched = 0
foreach ($f in Get-ChildItem -LiteralPath $KojoDir -Filter *.ERB) {
  $lines = ([System.IO.File]::ReadAllText($f.FullName, $read)) -split "`r`n|`r|`n"
  $inRegion = $false; $changed = $false; $sawHook = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $ln = $lines[$i]
    if ($ln -match $endPat)   { $inRegion = $false; continue }
    if ($ln -match $startPat) { $inRegion = $true;  $sawHook = $true; continue }
    if (-not $inRegion) { continue }
    if (-not $Rearm) {
      # disarm: prefix ; to any not-yet-commented line
      if ($ln.TrimStart() -notmatch '^;') { $lines[$i] = ';' + $ln; $changed = $true }
    } else {
      # re-arm: strip the leading ; from commented hook code
      if ($ln -match $codePat) { $lines[$i] = ($ln -replace '^(\s*);', '$1'); $changed = $true }
    }
  }
  if ($sawHook) { $hitFiles++ }
  if ($changed) {
    $touched++
    [System.IO.File]::WriteAllText($f.FullName, ($lines -join "`r`n"), $bom)
    Write-Host ("  {0} {1}" -f ($(if($Rearm){'重新启用钩子'}else{'注释掉钩子'}), $f.Name))
  }
}

Write-Host ""
if ($hitFiles -eq 0) {
  Write-Host "没找到 AUTOTEST 钩子标记（;=== AUTOTEST 钩子 …）。可能钩子已被删除。" -ForegroundColor Yellow
} elseif ($touched -eq 0) {
  Write-Host ($(if($Rearm){'钩子本来就是启用状态，无需改动。'}else{'钩子本来就是注释掉的状态，无需改动。'})) -ForegroundColor DarkGray
} else {
  Write-Host ($(if($Rearm){'已重新启用 AUTOTEST 钩子（会話 会再次触发自动测试）。'}else{'已注释掉 AUTOTEST 钩子（以后 会話 不再触发自动测试）。想恢复请加 -Rearm 再跑一次。'})) -ForegroundColor Green
}
