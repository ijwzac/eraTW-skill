<#
clip_tap.ps1 — real-time clipboard transcript for eraTW.

Emuera auto-copies newly-displayed text to the system clipboard (this install
has 表示したテキストをクリップボードにコピーする:YES / 新しい行のみコピーする:YES,
refresh ~800ms, 25-line cap). Unlike emuera.log / debug/console.log (which only
update at load/error/explicit-save), the clipboard is the live stream of what the
player sees. This script polls it, and whenever the content changes, appends a
timestamped block to a log file (UTF-8, no BOM). That file is the real-time
transcript an AI session can Read on demand to debug a kojo while the user plays.

USAGE (run in its own STA PowerShell so clipboard access is reliable):
  powershell -STA -ExecutionPolicy Bypass -File clip_tap.ps1 `
      -LogFile .\autotest_cliplog.txt -WatchPid 28736 -IntervalMs 400

STOPS WHEN: the -WatchPid process exits, the -StopFile appears, or -MaxSeconds
elapses. Leave -WatchPid 0 to ignore process lifetime (then use -StopFile).

CAVEATS:
  * One clipboard per Windows session — run a SINGLE Emuera instance while
    capturing, or streams from multiple games interleave.
  * The game caps each copy at 25 lines / 800ms; faster text bursts lose lines
    at the game layer (raise クリップボードに貼り付ける行数 / lower the interval in
    emuera.config to mitigate). Click-to-advance dialogue is well within budget.
  * Two truly-identical consecutive clipboard values are de-duped (treated as
    one); this is rare and low-stakes for dialogue testing.
#>
param(
  [string]$LogFile    = ".\autotest_cliplog.txt",
  [int]   $WatchPid   = 0,
  [int]   $IntervalMs = 400,
  [string]$StopFile   = "",
  [int]   $MaxSeconds = 3600
)

# --- single-instance guard ---------------------------------------------
# Two clip_tap processes polling the same clipboard both append to the log,
# producing duplicated (same-timestamp) blocks. A named mutex guarantees
# only one instance ever writes; a second launch exits immediately.
$createdNew = $false
$singleton = New-Object System.Threading.Mutex($true, "Global\eratw_clip_tap_singleton", [ref]$createdNew)
if (-not $createdNew) {
    Write-Host "clip_tap: another instance is already running - exiting."
    exit 0
}

$enc   = New-Object System.Text.UTF8Encoding($false)   # UTF-8, no BOM (safe to append)
$last  = $null
$start = Get-Date

function Append([string]$s) { [System.IO.File]::AppendAllText($LogFile, $s, $enc) }

Append(("===== clip_tap started {0}  watchPid={1}  interval={2}ms =====`r`n" -f `
        (Get-Date -Format o), $WatchPid, $IntervalMs))

while ($true) {
    if ($WatchPid -gt 0 -and -not (Get-Process -Id $WatchPid -ErrorAction SilentlyContinue)) { break }
    if ($StopFile -and (Test-Path $StopFile)) { break }
    if (((Get-Date) - $start).TotalSeconds -gt $MaxSeconds) { break }

    $txt = $null
    try { $txt = Get-Clipboard -Raw -ErrorAction Stop } catch { $txt = $null }

    if ($txt -and $txt -ne $last) {
        Append((("`r`n----- {0} -----`r`n" -f (Get-Date -Format "HH:mm:ss.fff")) + $txt + "`r`n"))
        $last = $txt
    }
    Start-Sleep -Milliseconds $IntervalMs
}
Append("`r`n===== clip_tap stopped =====`r`n")
