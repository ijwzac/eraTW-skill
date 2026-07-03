<#
at_update.ps1 — rewrite ;@AT test-status flags in kojo files from an autotest run log.

The autotest battery (@M_KOJO_K{id}_AUTOTEST) brackets each exercised branch with
  [[TID <id> BEGIN]]  ... CALL ...  [[TID <id> OK]]
and clip_tap captures that into a transcript. This script reads the transcript,
decides a verdict per TID, and rewrites the matching  ;@AT <status> <TID>  line
in the kojo source — so flag updates cost zero AI tokens.

Verdict:
  BEGIN + OK present -> 测试通过   (branch reached, ran without halt)
  BEGIN, no OK       -> 测试失败   (Emuera halted inside; the last un-OK'd TID is the culprit)
  TID absent in log  -> left unchanged

Only rewrites tags whose CURRENT status is one of the four enum values
(待自动测试 / 待手动测试 / 测试通过 / 测试失败); convention-doc lines like
";@AT <状态> <TID>" are ignored. Files are rewritten UTF-8 **with BOM** (as kojo
files require) and CRLF.

USAGE:
  powershell -File at_update.ps1 -CliLog .\autotest_cliplog.txt `
      -KojoDir "ERB\...\006 Luna [ルナ]\露娜切露德_重制" [-DryRun]

  -DryRun   report what would change, write nothing.
#>
param(
  [Parameter(Mandatory)][string]$CliLog,
  [Parameter(Mandatory)][string]$KojoDir,
  [switch]$DryRun
)

$read = New-Object System.Text.UTF8Encoding($false)   # decoder tolerates a BOM if present
$bom  = New-Object System.Text.UTF8Encoding($true)     # kojo files must be written WITH BOM
$valid = @('待自动测试','待手动测试','测试通过','测试失败')

# --- 1. parse the transcript for BEGIN/OK markers ---
$log = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $CliLog), $read)
$begin = @{}; $ok = @{}
foreach ($m in [regex]::Matches($log, '\[\[TID\s+(\S+)\s+(BEGIN|OK)\]\]')) {
  if ($m.Groups[2].Value -eq 'BEGIN') { $begin[$m.Groups[1].Value] = $true }
  else                                { $ok[$m.Groups[1].Value]    = $true }
}
$verdict = @{}
foreach ($tid in $begin.Keys) {
  $verdict[$tid] = if ($ok.ContainsKey($tid)) { '测试通过' } else { '测试失败' }
}
if ($verdict.Count -eq 0) { Write-Host "No [[TID ...]] markers found in $CliLog — nothing to do."; return }

# --- 2. rewrite matching ;@AT lines in each kojo file ---
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

# --- 3. report; flag TIDs seen in the log that have no source tag ---
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
Write-Host ("{0} {1} tag(s) across {2} file(s).  TIDs in log: {3}." -f $mode, $changed, $filesTouched, $verdict.Count)
if ($fails)   { Write-Host ("FAILURES (测试失败): {0}" -f ($fails -join ', ')) -ForegroundColor Red }
if ($orphans) { Write-Host ("WARN: TIDs in log with no source ;@AT tag: {0}" -f ($orphans -join ', ')) -ForegroundColor Yellow }
