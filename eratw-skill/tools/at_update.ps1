<#
at_update.ps1 — rewrite ;@AT test-status flags in kojo files from an AUTOTEST run log.

The autotest battery (@M_KOJO_K{id}_AUTOTEST) brackets each exercised branch with
  [[TID <id> BEGIN]]  ... CALL ...  [[TID <id> OK]]
and, as its first output line, prints its own kojo folder relative to the game root:
  [[KOJODIR <path-relative-to-game-root>]]
clip_tap captures all of that into a transcript. This script reads the transcript,
decides a verdict per TID, and rewrites the matching  ;@AT <status> <TID>  line
in the kojo source — so flag updates cost zero AI tokens.

Verdict (END-sentinel gated, so a lost OK marker does NOT cause a false failure):
  If the battery's END sentinel (=====AUTOTEST_K{id}_END=====) is in the log, the whole
  battery ran to completion with no halt -> every TID that printed a BEGIN is 测试通过,
  even if its OK line was dropped by the clipboard at a screen boundary.
  If the END sentinel is ABSENT, execution halted somewhere -> the culprit is the block
  whose BEGIN is the LAST marker in the log (nothing ran after it). Every earlier BEGIN
  has a later marker, so it completed -> 测试通过; only that last-BEGIN block is 测试失败.
  (BEGIN alone is NOT enough on its own: BEGIN is printed *before* the CALL, so a body that
  halts still shows its BEGIN — the END sentinel / later-marker check is what proves it ran.)
  TID absent in log  -> left unchanged

Only rewrites tags whose CURRENT status is one of the four enum values
(待自动测试 / 待手动测试 / 测试通过 / 测试失败); convention-doc lines are ignored.
Files are rewritten UTF-8 **with BOM** (as kojo files require) and CRLF.

KojoDir resolution (no need to pass it when the log carries a [[KOJODIR]] line):
  -KojoDir given            -> use it verbatim (explicit override).
  else [[KOJODIR rel]] found -> resolve against -GameRoot (or use as-is if absolute).
  else                       -> error out.

USAGE:
  powershell -File at_update.ps1 -CliLog .\cliplog.txt -GameRoot "<game root>" [-DryRun]
  powershell -File at_update.ps1 -CliLog .\cliplog.txt -KojoDir "<kojo folder>" [-DryRun]

  -DryRun   report what would change, write nothing.
#>
param(
  [Parameter(Mandatory)][string]$CliLog,
  [string]$KojoDir,
  [string]$GameRoot,
  [switch]$DryRun
)

$read = New-Object System.Text.UTF8Encoding($false)   # decoder tolerates a BOM if present
$bom  = New-Object System.Text.UTF8Encoding($true)     # kojo files must be written WITH BOM
$valid = @('待自动测试','待手动测试','测试通过','测试失败')

# --- 1. read transcript ---
if (-not (Test-Path -LiteralPath $CliLog)) { Write-Host "Log not found: $CliLog" -ForegroundColor Red; return }
$log = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $CliLog), $read)

# --- 2. resolve KojoDir (explicit override, else the [[KOJODIR]] line from the log) ---
if (-not $KojoDir) {
  $mk = [regex]::Match($log, '(?m)^\s*\[\[KOJODIR\s+(.+)\]\]\s*$')
  if ($mk.Success) {
    $rel = $mk.Groups[1].Value.Trim()
    if ([System.IO.Path]::IsPathRooted($rel)) { $KojoDir = $rel }
    elseif ($GameRoot)                        { $KojoDir = Join-Path $GameRoot ($rel -replace '/','\') }
    else                                      { $KojoDir = $rel }
  }
}
if (-not $KojoDir)                        { Write-Host "No -KojoDir and no [[KOJODIR]] line in the log — cannot locate the kojo." -ForegroundColor Red; return }
if (-not (Test-Path -LiteralPath $KojoDir)) { Write-Host "Kojo folder not found: $KojoDir" -ForegroundColor Red; return }

# --- 3. parse the transcript for BEGIN/OK markers (in order) ---
$begin = @{}; $ok = @{}
$lastTid = $null; $lastKind = $null
foreach ($m in [regex]::Matches($log, '\[\[TID\s+(\S+)\s+(BEGIN|OK)\]\]')) {
  $tid = $m.Groups[1].Value; $kind = $m.Groups[2].Value
  if ($kind -eq 'BEGIN') { $begin[$tid] = $true } else { $ok[$tid] = $true }
  $lastTid = $tid; $lastKind = $kind      # Matches() yields in document order; keep the final one
}

# END sentinel present => the whole battery ran to completion (no halt anywhere).
# In that case a missing OK is pure clipboard loss, NOT a failure — so every BEGIN'd TID passes.
$endSeen = [regex]::IsMatch($log, 'AUTOTEST_\w+_END')

$verdict = @{}
foreach ($tid in $begin.Keys) {
  if ($endSeen -or $ok.ContainsKey($tid)) {
    $verdict[$tid] = '测试通过'
  } elseif ($tid -eq $lastTid -and $lastKind -eq 'BEGIN') {
    $verdict[$tid] = '测试失败'   # no END, and this BEGIN is the last marker => execution halted here
  } else {
    $verdict[$tid] = '测试通过'   # no OK, but a later marker exists => this block completed; OK was just lost
  }
}
if ($verdict.Count -eq 0) { Write-Host "No [[TID ...]] markers found in $CliLog — nothing to do."; return }
if ($endSeen) { Write-Host "END sentinel present: battery ran to completion; missing-OK TIDs treated as pass (clipboard loss)." -ForegroundColor DarkGray }
else          { Write-Host "END sentinel ABSENT: battery halted; culprit = last BEGIN without a successor." -ForegroundColor Yellow }

# --- 4. rewrite matching ;@AT lines in each kojo file ---
$changed = 0; $filesTouched = 0
foreach ($f in Get-ChildItem -LiteralPath $KojoDir -Filter *.ERB) {
  $text  = [System.IO.File]::ReadAllText($f.FullName, $read)
  $lines = $text -split "`r`n|`r|`n"
  $fileChanged = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^(\s*;@AT\s+)(\S+)(\s+)(\S+)(\s*)$') {
      $status = $Matches[2]; $tid = $Matches[4]
      if (($valid -contains $status) -and $verdict.ContainsKey($tid) -and ($verdict[$tid] -ne $status)) {
        Write-Host ("  {0,-28} {1,-20} {2} -> {3}" -f $f.Name, $tid, $status, $verdict[$tid])
        $lines[$i] = $Matches[1] + $verdict[$tid] + $Matches[3] + $tid + $Matches[5]
        $fileChanged = $true; $changed++
      }
    }
  }
  if ($fileChanged) {
    $filesTouched++
    if (-not $DryRun) { [System.IO.File]::WriteAllText($f.FullName, ($lines -join "`r`n"), $bom) }
  }
}

# --- 5. report; flag TIDs seen in the log that have no source tag ---
$tagged = @{}
foreach ($f in Get-ChildItem -LiteralPath $KojoDir -Filter *.ERB) {
  foreach ($m in [regex]::Matches([System.IO.File]::ReadAllText($f.FullName, $read), '(?m)^\s*;@AT\s+\S+\s+(\S+)\s*$')) {
    $tagged[$m.Groups[1].Value] = $true
  }
}
$orphans = $verdict.Keys | Where-Object { -not $tagged.ContainsKey($_) } | Sort-Object
$fails   = $verdict.Keys | Where-Object { $verdict[$_] -eq '测试失败' } | Sort-Object

$mode = if ($DryRun) { "[DRY-RUN] would update" } else { "updated" }
Write-Host ""
Write-Host ("KojoDir: {0}" -f $KojoDir)
Write-Host ("{0} {1} tag(s) across {2} file(s).  TIDs in log: {3}." -f $mode, $changed, $filesTouched, $verdict.Count)
if ($fails)   { Write-Host ("FAILURES (测试失败): {0}" -f ($fails -join ', ')) -ForegroundColor Red }
if ($orphans) { Write-Host ("WARN: TIDs in log with no source ;@AT tag: {0}" -f ($orphans -join ', ')) -ForegroundColor Yellow }
