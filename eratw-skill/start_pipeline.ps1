<#
  eraTW 口上验证流水线 一键启动器（start_pipeline.ps1）
  双击同目录的 run_eratw_test.bat 即可运行。
  流程：选版本 → （提醒后）清理上次抓取器/归档旧日志 → 启动游戏 → 隐藏后台实时抓词到 cliplog.txt
        → 实时显示进度、自动抽出 AUTOTEST 段 → 关闭游戏后扫描手动测试标记、询问是否回写口上。
#>
$ErrorActionPreference = 'Stop'
# 顶层兜底：任何终止性错误都停下来显示信息并等回车，避免窗口秒关、崩溃信息丢失。
trap {
    Write-Host "`n  [X] 脚本出错：$($_.Exception.Message)" -ForegroundColor Red
    Write-Host ("     位置：{0}" -f $_.InvocationInfo.PositionMessage) -ForegroundColor DarkGray
    Read-Host "`n  （把上面这段红字截图发给 AI 可帮你排查）按回车退出"
    exit 1
}
try { chcp 936 > $null } catch {}
try { [Console]::OutputEncoding = [Text.Encoding]::GetEncoding(936) } catch {}

$skillDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$tap      = Join-Path $skillDir 'tools\clip_tap.ps1'
$scan     = Join-Path $skillDir 'tools\manual_scan.ps1'
$atup     = Join-Path $skillDir 'tools\at_update.ps1'
$log      = Join-Path $skillDir 'cliplog.txt'
$resFile  = Join-Path $skillDir 'test_result.txt'   # 交给 AI 看的结果文件（自动+手动）

$devName = 'Emuera_lazyloading_for_developer.exe'
$plyName = 'Emuera_lazyloading_for_player.exe'
$utf8n   = New-Object System.Text.UTF8Encoding($false)
$utf8b   = New-Object System.Text.UTF8Encoding($true)

# --- 定位游戏根目录 ---
$root = $null; $d = $skillDir
for ($i = 0; $i -lt 6; $i++) {
    if (Test-Path (Join-Path $d $devName)) { $root = $d; break }
    $p = Split-Path -Parent $d; if (-not $p -or $p -eq $d) { break }; $d = $p
}
if (-not $root)            { Write-Host "`n  [X] 没找到游戏 $devName。请把本 SKILL 文件夹放进 eraTW 游戏目录（或其子目录）。" -ForegroundColor Red; Read-Host "  回车退出"; exit 1 }
if (-not (Test-Path $tap)) { Write-Host "`n  [X] 没找到抓取器 $tap" -ForegroundColor Red; Read-Host "  回车退出"; exit 1 }

# ================= 选择游戏版本 =================
Clear-Host
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "        eraTW 口上验证流水线  ·  一键启动" -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "  游戏目录 : $root"
Write-Host "  记录文件 : $log"
Write-Host ""
Write-Host "  请选择要启动的游戏版本："
Write-Host "    [1] 开发者版(调试模式)  —— 想要Debug窗口与Debug信息用它）"
Write-Host "    [2] 普通玩家版          —— 平时游玩用它"
Write-Host "  两个版本均可以触发手动测试与自动测试功能"
Write-Host "  Debug窗口能输入作弊指令，具体可询问AI"
Write-Host ""
$choice = Read-Host "  输入 1 或 2 后回车"
if     ($choice -eq '1') { $exe = $devName; $exeArgs = @('-debug'); $modeName = '开发者版(调试)' }
elseif ($choice -eq '2') { $exe = $plyName; $exeArgs = @();         $modeName = '普通玩家版' }
else { Write-Host "  输入无效。" -ForegroundColor Red; Read-Host "  回车退出"; exit 1 }
if (-not (Test-Path (Join-Path $root $exe))) { Write-Host "  [X] 没找到 $exe" -ForegroundColor Red; Read-Host "  回车退出"; exit 1 }

# ================= 提醒后再清理（#1）=================
Write-Host ""
Write-Host "  ⚠ 继续将会：" -ForegroundColor Yellow
Write-Host "      · 结束当前正在运行的同款游戏与后台抓取器（若有）；"
Write-Host "      · 把上一份 cliplog.txt 归档备份（重命名，不会真删），然后开始全新记录。"
$go = Read-Host "  确认继续请输入 Y 回车（其它则取消）"
if ($go -notmatch '^[Yy]') { Write-Host "  已取消。" -ForegroundColor DarkGray; Read-Host "  回车退出"; exit 0 }

Write-Host "`n  [1/4] 清理上次的后台抓取器 / 上一局游戏 ..."
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like '*clip_tap.ps1*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($devName)),
                  ([IO.Path]::GetFileNameWithoutExtension($plyName)) -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 1200

Write-Host "  [2/4] 归档上一份 cliplog.txt + 清除 lazyloading 缓存/旧日志 ..."
if (Test-Path $log) { Move-Item $log (Join-Path $skillDir ("cliplog_" + (Get-Date -Format 'MMdd_HHmmss') + ".txt")) -Force }
# ★清除 lazyloading.dat：它是引擎「标签→文件」索引缓存。若不删，本次【新增】的口上标签
#   （新命令/派生/事件 handler）不会被索引到 → 引擎当它们不存在、TRYCALLFORM 落空 → 走通用文本。
#   这正是"新写的指令/掏耳朵派生口上在游戏里不触发"的最常见元凶。删掉后引擎下次启动全量重建。
#   （注：已存在标签的正文改动会在按需载入时读到最新文件，故正文改动一般照常生效——但新标签必须删缓存。）
#   顺带清 emuera.log（halt-only 旧报错会误导）。
Remove-Item (Join-Path $root 'lazyloading.dat') -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $root 'emuera.log')       -Force -ErrorAction SilentlyContinue

# ================= 自动测试哨兵：扫描本 skill 口上、询问是否启用 =================
# 本工具写的口上目录里放着哨兵文件 autotest.on(启用)/autotest.off(禁用)。扫出它们即可
# 发现哪些口上是本工具写的、且当前 arm 状态；按玩家选择在 .on/.off 间改名切换。
# 读档时各口上的 @M_KOJO_FLAGSETTING 会 EXISTFILE 检查 autotest.on 来置待命位 CFLAG:{id}:1099=1，
# 于是玩家不必在调试台打字：读档进游戏、跟该角色【会話】一次即自动跑测试套件。
$kojoRoot = Join-Path $root 'ERB\口上・メッセージ関連\個人口上'
$sentinels = @()
if (Test-Path -LiteralPath $kojoRoot) {
    $sentinels = @(Get-ChildItem -LiteralPath $kojoRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'autotest.on' -or $_.Name -eq 'autotest.off' })
}
if ($sentinels.Count -gt 0) {
    Write-Host ""
    Write-Host "  ──────────────── 自动测试 AUTOTEST ────────────────" -ForegroundColor Cyan
    Write-Host "  发现 $($sentinels.Count) 个本工具写的口上带自动测试套件，当前状态："
    foreach ($s in $sentinels) {
        $on = ($s.Name -eq 'autotest.on')
        $kojo = Split-Path -Leaf (Split-Path -Parent $s.FullName)
        Write-Host ("     [{0}] {1}" -f $(if ($on) { '已启用' } else { '已禁用' }), $kojo) -ForegroundColor $(if ($on) { 'Green' } else { 'DarkGray' })
    }
    Write-Host "  启用后：读档进游戏、跟该角色【会話】一次即自动跑完整测试套件（无需在调试台打字）。"
    $atc = Read-Host "  [A]全部启用  [N]全部禁用  [回车]保持不变"
    if ($atc -match '^[Aa]') {
        foreach ($s in $sentinels) { if ($s.Name -eq 'autotest.off') { Rename-Item -LiteralPath $s.FullName -NewName 'autotest.on' -Force -ErrorAction SilentlyContinue } }
        Write-Host "  ✓ 已全部【启用】自动测试。" -ForegroundColor Green
    } elseif ($atc -match '^[Nn]') {
        foreach ($s in $sentinels) { if ($s.Name -eq 'autotest.on') { Rename-Item -LiteralPath $s.FullName -NewName 'autotest.off' -Force -ErrorAction SilentlyContinue } }
        Write-Host "  ✓ 已全部【禁用】自动测试。" -ForegroundColor DarkGray
    } else {
        Write-Host "  · 保持不变。" -ForegroundColor DarkGray
    }
}

Write-Host "  [3/4] 启动游戏：$modeName ..."
# 注意：普通玩家版 $exeArgs=@()（空数组），而 Start-Process -ArgumentList 不接受空数组
# （ValidateNotNullOrEmpty），在 $ErrorActionPreference='Stop' 下会直接抛错、窗口秒关。
# 故用 splat，只有非空时才带 -ArgumentList。
$spArgs = @{ FilePath = (Join-Path $root $exe); WorkingDirectory = $root; PassThru = $true }
if ($exeArgs.Count -gt 0) { $spArgs['ArgumentList'] = $exeArgs }
$game = Start-Process @spArgs
Start-Sleep -Milliseconds 900
if ($game.HasExited) { Write-Host "  [X] 游戏启动后立即退出，请检查游戏能否正常打开。" -ForegroundColor Red; Read-Host "  回车退出"; exit 1 }

Write-Host "  [4/4] 启动后台实时抓取器（窗口已隐藏）..."
# clip_tap 默认 -MaxSeconds=3600（60 分钟）会自动停，之前长时间游玩会静默丢抓取。
# 这里给个很大的上限(24h)，真正的结束仍由 -WatchPid（游戏进程退出）决定。
# 用函数封装并 -PassThru，供监控循环自愈重启。
function Start-Tap {
    $a = '-STA -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}" -LogFile "{1}" -WatchPid {2} -IntervalMs 150 -MaxSeconds 86400' -f $tap, $log, $game.Id
    return Start-Process -FilePath 'powershell.exe' -ArgumentList $a -WindowStyle Hidden -PassThru
}
$tapProc = Start-Tap

# ================= 说明面板 =================
Clear-Host
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "   已启动！这个窗口是「验证控制台」" -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  · 游戏窗口：$modeName，已单独打开。"
Write-Host "  · 后台有一个【隐藏】小程序在实时监控剪贴板——游戏每显示一段文字都会自动记录，"
Write-Host "    你【不需要手动复制】。全部写入本文件夹里的：$log" -ForegroundColor Yellow
Write-Host ""
if ($choice -eq '1') {
    Write-Host "  【调试窗口】游戏左上角会多出 Debug 菜单，点开是一个很小的『调试控制台』小窗；" -ForegroundColor Cyan
    Write-Host "     它没有尺寸设置，请手动拖右下角放大；输入框在最底部（被『总在最前面』按钮挡住时往下点空行）。"
    Write-Host ""
    Write-Host "  【跑自动测试 AUTOTEST（仅当该角色的口上装了自动测试套件时才需要）】" -ForegroundColor Cyan
    Write-Host "     若刚才在启动前选了【启用】：直接读档、对该角色点一次「会話」就会自动跑一轮，【不用输入任何东西】。"
    Write-Host "     例外——该存档【以前已经跑过】一轮时（待命位已置 2，哨兵只让没跑过的存档待命、不会重复触发）："
    Write-Host "     想用同一个存档再跑一轮，就在调试控制台输入下面这行重新待命，再点「会話」："
    Write-Host "           CFLAG:<角色号>:1099 = 1     （把 <角色号> 换成你要测的角色号；不依赖 DEBUGGERR）" -ForegroundColor Yellow
    Write-Host "     若你不是在做自动测试，忽略本段、照常游玩即可。"
} else {
    Write-Host "  普通玩家版：照平时游玩即可，事件/约会等只能实际游玩触发的对话会被记录，供稍后统计。" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "  【手动测试会看到测试语句，属正常现象】" -ForegroundColor Cyan
Write-Host "     触发某段需要手动测试的对话时，它前面会先打印一行形如  [[MT ...]]  的"
Write-Host "     『测试语句』——这是给本工具做记号用的，说明这段成功显示了。测试通过后会被自动从代码里删掉。"
Write-Host ""
Write-Host "  · AUTOTEST 跑完会自动抽出结果到：$resFile" -ForegroundColor Yellow
Write-Host "  · 请【保持本窗口开着】。关掉游戏后，我会自动统计手动测试结果并询问是否回写。" -ForegroundColor Green
Write-Host ""
Write-Host "  （几秒后自动进入实时监控界面，无需按键；关键提示会一直显示在上方。）" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Green
Write-Host "   请享受游戏，游戏结束后请回到本窗口查看测试结果。" -ForegroundColor Green
Write-Host "  ============================================================" -ForegroundColor Green
Start-Sleep -Seconds 4

# ================= 工具函数 =================
function Get-AutotestBlock {
    if (-not (Test-Path $log)) { return $null }
    $txt = [System.IO.File]::ReadAllText($log, $utf8n)
    $m = [regex]::Matches($txt, '(?s)=====AUTOTEST_(\w+?)_BEGIN=====.*?=====AUTOTEST_\1_END=====')
    if ($m.Count -gt 0) { return $m[$m.Count - 1].Value } else { return $null }
}
function Get-ManualTids {
    if (-not (Test-Path $log)) { return @() }
    $txt = [System.IO.File]::ReadAllText($log, $utf8n)
    $seen = New-Object System.Collections.Specialized.OrderedDictionary
    foreach ($m in [regex]::Matches($txt, '\[\[MT\s+(K\d+_[^\]\s]+)\]\]')) {
        $t = $m.Groups[1].Value; if (-not $seen.Contains($t)) { $seen[$t] = $true }
    }
    return @($seen.Keys)
}
function Write-Result([string]$at, [string[]]$tids, [bool]$final) {
    $s = @()
    $s += "=== eraTW 测试结果（自动生成；把本文件整段发给 AI 即可评审）==="
    $s += ("生成时间：" + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    $s += ""
    $s += "【一、自动测试 AUTOTEST 输出】"
    if ($at) { $s += $at } else { $s += "  （本次运行未包含 AUTOTEST）" }
    $s += ""
    $s += "【二、手动测试 · 实录中已触发的分支】（去重，共 $($tids.Count) 处）"
    if ($tids.Count) { $tids | ForEach-Object { $s += "  $_" } } else { $s += "  （本次无）" }
    if (-not $final) { $s += ""; $s += "（游戏还开着，手动测试结果会在关闭游戏后再统计一次。）" }
    [System.IO.File]::WriteAllText($resFile, (($s -join "`r`n") + "`r`n"), $utf8b)
}
# 弹出 Windows「选择文件夹」对话框，返回所选绝对路径（取消则返回空）。用独立 STA 子进程以确保对话框可靠。
function Pick-Folder {
    # 进程内直接弹 Windows 文件夹选择框（run_eratw_test.bat 以 -STA 启动，故 ShowDialog 可用）。
    # SelectedPath 是 .NET Unicode 字符串，直接返回——不经过子进程 stdout 的控制台代码页，
    # 因此像「・」这种非 GBK 字符不会被转成「?」（这是上一版子进程方案的残留 bug）。
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $f = New-Object System.Windows.Forms.FolderBrowserDialog
        $f.Description = '选择要回写的口上文件夹（里面应含 M_KOJO_K*.ERB 文件）'
        $f.ShowNewFolderButton = $false
        if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $f.SelectedPath }
        return ''
    } catch {
        Write-Host ("  （打不开文件夹选择窗口：{0}）请直接粘贴口上文件夹的绝对路径。" -f $_.Exception.Message) -ForegroundColor Yellow
        return ''
    }
}

# ================= 实时监控循环 =================
$lastSize = -1; $atShown = $false; $tapRestarts = 0
while (-not $game.HasExited) {
    # 自愈：clip_tap 若意外退出（超时/崩溃）而游戏还开着，就重新拉起，避免长时间游玩静默丢抓取。
    if ($tapProc.HasExited) { $tapProc = Start-Tap; $tapRestarts++ }
    Clear-Host
    Write-Host "  ┌─ eraTW 验证控制台 · 实时监控中 ($modeName) ────────────────" -ForegroundColor Cyan
    Write-Host "  │ 正在实时记录游戏文字到 cliplog.txt（无需手动复制）。保持本窗口开着，关掉游戏后自动统计。"
    if ($tapRestarts -gt 0) { Write-Host ("  │ （抓取器曾自动重启 {0} 次——属正常自愈，不影响记录）" -f $tapRestarts) -ForegroundColor DarkGray }
    if ($choice -eq '1') { Write-Host "  │ 跑自动测试（如有）：启动前选了【启用】就直接点「会話」；已跑过的存档要重跑才需调试台输 CFLAG:<角色号>:1099 = 1。" -ForegroundColor DarkGray }
    else                 { Write-Host "  │ 正常游玩即可；触发到需手动测试的对话时看到 [[MT ...]] 测试语句是正常的。" -ForegroundColor DarkGray }
    if ($atShown) { Write-Host "  │ ✓ 已抽出 AUTOTEST 结果 -> test_result.txt" -ForegroundColor Green }
    Write-Host "  └───────────── 游戏输出的最后 20 行 ──────────────" -ForegroundColor Cyan
    if (Test-Path $log) {
        $sz = (Get-Item $log).Length
        if ($sz -ne $lastSize) {
            $lastSize = $sz
            $at = Get-AutotestBlock
            if ($at) { $atShown = $true }
            Write-Result $at (Get-ManualTids) $false
        }
        foreach ($ln in (Get-Content $log -Tail 20 -Encoding UTF8)) {
            $sLine = $ln; if ($sLine.Length -gt 96) { $sLine = $sLine.Substring(0,95) + '…' }
            Write-Host "    $sLine"
        }
    } else { Write-Host "    （还没有内容，等游戏里出现文字…）" -ForegroundColor DarkGray }
    Write-Host ""
    Write-Host "  关掉游戏即结束监控并统计手动测试结果 …" -ForegroundColor DarkGray
    Start-Sleep -Seconds 2
}

# ================= 游戏结束：收尾 =================
# 游戏运行时它抢走了前台焦点；游戏一关就把本控制台窗口拉回最前，免得用户找不到它。
try {
    Add-Type -Namespace Win32 -Name Fg -MemberDefinition '[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);' -ErrorAction SilentlyContinue
    $hCon = [Win32.Fg]::GetConsoleWindow()
    if ($hCon -ne [IntPtr]::Zero) { [Win32.Fg]::ShowWindow($hCon, 9) | Out-Null; [Win32.Fg]::SetForegroundWindow($hCon) | Out-Null }
} catch {}
Clear-Host
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "   游戏已关闭 —— 正在统计结果" -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor Cyan
Start-Sleep -Milliseconds 400

# ============================================================
#  崩溃 / 错误诊断 —— 区分两种情况，处置不同
#    A. 编译 / 脚本错误：cliplog 很短(<50行)且含「Emuera停止运行」→ 游戏【没真正跑起来】。
#       → 提示 + 把 emuera.log 尾部并进 cliplog 供 AI 定位，然后【直接结束、不显示 autotest/mt】
#         （游戏没跑，那些统计全是空/误导）。
#    B. 运行中崩溃：emuera.log 新鲜(几分钟内)且末尾含「错误发生/错误内容/函数调用栈」→ 游戏【跑到一半崩了】。
#       剪贴板抓取(cliplog)常抓不到引擎抛的异常堆栈——它是引擎异常处理器直接写屏/写 emuera.log 的，
#       不走 PRINT→剪贴板那条路，故 clip_tap 轮询不到。这里从 emuera.log 把它捞出来并进 cliplog + 提示玩家。
#       这种情况 autotest/mt 【照常显示】（测试套件可能已跑完一部分，结果有价值）。
#  说明：emuera.log 由引擎写在【游戏根目录】，本脚本启动时已删过一次，故存在即本次会话；只在
#        加载/运行时错误/显式保存时更新（不像剪贴板是实时流），所以拿它专门兜「运行中崩溃」这个盲区。
# ============================================================
$emuLog  = Join-Path $root 'emuera.log'
$crashRe = '错误发生|错误内容|函数调用栈'

# 取 emuera.log 尾部（仅当新鲜：5 分钟内），两种情况都用得上
$emuTail = $null; $emuHasCrash = $false
if (Test-Path $emuLog) {
    $ageMin = ((Get-Date) - (Get-Item $emuLog).LastWriteTime).TotalMinutes
    if ($ageMin -le 5) {
        try {
            $emuAll  = [System.IO.File]::ReadAllText($emuLog, $utf8n) -split "`r?`n"
            $emuTail = $emuAll[[Math]::Max(0, $emuAll.Count - 20)..($emuAll.Count - 1)]
            if ($emuTail -match $crashRe) { $emuHasCrash = $true }
        } catch {}
    }
}

# 把 emuera.log 尾部并进 cliplog（带醒目分界，供 AI 直接读到）
function Add-EmuTailToCliplog($why) {
    if (-not $emuTail) { return }
    $sep = "`r`n===== [启动器附加] emuera.log 末尾 20 行（$why；剪贴板未必抓到引擎异常堆栈）=====`r`n"
    [System.IO.File]::AppendAllText($log, $sep + (($emuTail -join "`r`n")) + "`r`n", $utf8n)
}

# ---- A. 编译 / 脚本错误：游戏没真正跑起来 → 提示后直接结束，不显示 autotest/mt ----
$compileError = $false
if (Test-Path $log) {
    $clLines = @(Get-Content $log -Encoding UTF8)
    if ($clLines.Count -lt 50 -and ($clLines -match 'Emuera停止运行')) { $compileError = $true }
}
if ($compileError) {
    Add-EmuTailToCliplog '编译/脚本错误'
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Red
    Write-Host "   [!!] 检测到疑似【编译 / 脚本错误】——游戏刚启动就停止运行了。" -ForegroundColor Red
    Write-Host "  ============================================================" -ForegroundColor Red
    Write-Host "   实录 cliplog.txt 很短（$($clLines.Count) 行）且出现「Emuera停止运行」，" -ForegroundColor Yellow
    Write-Host "   通常是某个口上文件有编译错误（警告Lv2 / 无法解释的行）导致 halt。" -ForegroundColor Yellow
    if ($emuTail) { Write-Host "   已把 emuera.log 末尾（含具体文件/行号）并进 cliplog.txt 末尾，方便 AI 直接定位。" -ForegroundColor Yellow }
    Write-Host "   请把 cliplog.txt 发给 AI，让它查看并修正错误，然后重新启动本工具。" -ForegroundColor Yellow
    Write-Host "   文件：$log" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   （游戏没有真正跑起来，故跳过自动/手动测试统计——那些结果此时是空的、只会误导。）" -ForegroundColor DarkGray
    Read-Host "`n  按回车关闭"
    exit 0
}

# ---- B. 运行中崩溃：游戏跑到一半崩了 → 并进 emuera.log + 提示玩家，autotest/mt 照常 ----
if ($emuHasCrash) {
    Add-EmuTailToCliplog '游戏运行中崩溃'
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Red
    Write-Host "   [!!] 检测到【游戏运行中崩溃】——玩到一半触发了某个 bug 导致游戏停止运行。" -ForegroundColor Red
    Write-Host "  ============================================================" -ForegroundColor Red
    Write-Host "   引擎的错误堆栈剪贴板抓不到，已从 emuera.log 捞出末尾 20 行并进 cliplog.txt 末尾。" -ForegroundColor Yellow
    Write-Host "   请把 cliplog.txt 发给 AI 让它据此修正，然后重新启动本工具。" -ForegroundColor Yellow
    Write-Host "   崩溃堆栈（emuera.log 末尾）：" -ForegroundColor Yellow
    foreach ($ln in $emuTail) {
        $sLine = $ln; if ($sLine.Length -gt 100) { $sLine = $sLine.Substring(0,99) + '…' }
        if ($sLine.Trim()) { Write-Host "     $sLine" -ForegroundColor DarkGray }
    }
    Write-Host ""
}

$atBlock = Get-AutotestBlock
$mtTids  = Get-ManualTids
Write-Result $atBlock $mtTids $true
Write-Host ""
if ($atBlock) { Write-Host "  ✓ AUTOTEST 结果已写入 test_result.txt" -ForegroundColor Green } else { Write-Host "  · 本次无 AUTOTEST 段。" }
Write-Host ("  ✓ 手动测试：实录中共发现 {0} 处已触发的对话标记。" -f $mtTids.Count) -ForegroundColor Green
Write-Host "     结果文件（可发给 AI）：$resFile" -ForegroundColor Yellow

# ================= 自动测试 AUTOTEST 回写（调用 at_update.ps1）=================
Write-Host ""
Write-Host "  ──────────────── 自动测试 AUTOTEST 结果 ────────────────" -ForegroundColor Cyan
# 判定按 END 哨兵门控（与 at_update.ps1 一致）：
#   $atBlock 有   → BEGIN 与 END 哨兵成对捕获 → 测试套件完整跑完没崩 → 每个打了 BEGIN 的分支都算通过（OK 丢了也无妨）。
#   $atBlock 无但日志出现过 BEGIN 哨兵 → 测试套件中途崩溃(halt)。
#   两者皆无 → 本轮压根没跑自动测试。
$logTxt   = if (Test-Path $log) { [System.IO.File]::ReadAllText($log, $utf8n) } else { '' }
$atStarted = [regex]::IsMatch($logTxt, '=====AUTOTEST_\w+_BEGIN=====')
if (-not $atBlock) {
    if ($atStarted) {
        Write-Host "  [!] 看到自动测试开始了(BEGIN 哨兵)，却没看到结束(END 哨兵) —— 测试套件很可能中途崩溃(halt)。" -ForegroundColor Red
        Write-Host "      请看 test_result.txt 正文，最后一条 [[TID ... BEGIN]] 之后的分支即崩溃点。本次跳过回写。" -ForegroundColor Yellow
    } else {
        Write-Host "  · 本轮没有跑自动测试（可能只做了手动测试），跳过自动测试回写。" -ForegroundColor DarkGray
    }
} else {
    $bset = @{}
    foreach ($m in [regex]::Matches($atBlock, '\[\[TID\s+(\S+)\s+BEGIN\]\]')) { $bset[$m.Groups[1].Value] = $true }
    $atCid = ''
    foreach ($k in $bset.Keys) { if ($k -match '^K(\d+)_') { $atCid = $Matches[1]; break } }
    Write-Host ("  END 哨兵已捕获 → 测试套件完整跑完、无中途崩溃；共 {0} 个分支，全部通过。" -f $bset.Count) -ForegroundColor Green
    Write-Host "  （个别 OK 若被剪贴板边界丢掉也不算失败——END 在就说明整段都跑到了。）" -ForegroundColor DarkGray
    Write-Host "  是否把自动测试结果回写口上代码？（;@AT -> 测试通过）" -ForegroundColor Cyan
    $doAt = Read-Host "  输入 Y 回车执行；其它则跳过"
    if ($doAt -match '^[Yy]') {
        $rel = $null
        $mk = [regex]::Match($atBlock, '(?m)^\s*\[\[KOJODIR\s+(.+)\]\]\s*$')
        if ($mk.Success) { $rel = $mk.Groups[1].Value.Trim() }
        $atDef = if ($rel) { Join-Path $root ($rel -replace '/','\') } else { '' }
        if ($atDef) { Write-Host ("  从 AUTOTEST 首行识别到口上文件夹：`n     {0}" -f $atDef) }
        else        { Write-Host "  没能从日志自动识别口上文件夹（AUTOTEST 未打印 [[KOJODIR]] 行）。" -ForegroundColor Yellow }
        Write-Host "  （若上面识别错了，请粘贴口上文件夹的【绝对路径】——里面装着 .ERB 文件、路径用 \ 分段）" -ForegroundColor DarkGray
        $ans = Read-Host "  确认就改这个文件夹吗？(Y=是 / P=打开文件夹选择窗口 / 或粘贴绝对路径)"
        $atTgt = $null
        if     ($ans -match '^[Yy]$' -and $atDef) { $atTgt = $atDef }
        elseif ($ans -match '^[Pp]$') { $atTgt = Pick-Folder }
        elseif ($ans -and $ans -notmatch '^[Yy]$') { $atTgt = $ans.Trim('"').Trim() }
        if     (-not $atTgt) { Write-Host "  已跳过自动测试回写。" -ForegroundColor DarkGray }
        elseif (-not (Test-Path -LiteralPath $atTgt)) { Write-Host "  路径不存在，跳过：$atTgt" -ForegroundColor Red }
        else {
            Write-Host "  回写自动测试结果中 ..." -ForegroundColor Cyan
            & powershell -NoProfile -ExecutionPolicy Bypass -File $atup -CliLog $log -KojoDir $atTgt
        }
    } else { Write-Host "  已跳过自动测试回写。" -ForegroundColor DarkGray }
    # 【不再自动注释钩子】：本工具并不检查那些【尚未被测试套件覆盖】的 待自动测试 分支，
    # 贸然关钩子会让人误以为全部测过了。改成提醒用户自行决定。
    $armCid = if ($atCid) { $atCid } else { '{角色号}' }
    Write-Host ""
    Write-Host "  提醒：" -ForegroundColor Cyan
    Write-Host ("    · 本存档里自动测试不会再自动触发了（已跑过，待命位 CFLAG:{0}:1099 已置 2）。哨兵文件只让【还没跑过】的存档待命，不会重复触发。" -f $armCid)
    Write-Host ("      想用同一个存档再跑一轮：调试控制台输入  CFLAG:{0}:1099 = 1  再点「会話」；换一个没跑过的存档则下次启动照样选【启用】即可。" -f $armCid)
    Write-Host "    · 口上里可能还有【没被这次测试套件覆盖到】的 待自动测试 分支，本工具不检查这些，请勿以为已全部测完。"
    Write-Host "    · 发布口上前，请记得手动注释掉 日常系コマンド.ERB 里那段 AUTOTEST 钩子、并删除 AUTOTEST.ERB（也可以直接让 AI 帮你处理）。" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  ──────────────── 手动测试 结果 ────────────────" -ForegroundColor Cyan
if ($mtTids.Count -eq 0) { Write-Host "  没有手动测试标记可回写。全部完成。" -ForegroundColor DarkGray; Read-Host "`n  按回车关闭"; exit 0 }

# 列出涉及的角色号
$cids = @{}; $mtTids | ForEach-Object { if ($_ -match '^K(\d+)_') { $cids[$Matches[1]] = $true } }
Write-Host ("`n  涉及角色：{0}" -f (($cids.Keys | Sort-Object | ForEach-Object { "K$_" }) -join ', '))
$mtTids | ForEach-Object { Write-Host "     $_" -ForegroundColor Green }

Write-Host ""
Write-Host "  是否把这些【已触发】的分支回写进口上代码？" -ForegroundColor Cyan
Write-Host "    （会把对应的  ;@AT 待手动测试 -> 测试通过，并删除那行  PRINTL [[MT ...]]  测试语句）"
$doApply = Read-Host "  输入 Y 回车执行；其它则跳过"
if ($doApply -notmatch '^[Yy]') { Write-Host "  已跳过回写（口上代码未改动）。" -ForegroundColor DarkGray; Read-Host "`n  按回车关闭"; exit 0 }

# 对每个角色号，定位「真正含这些标记」的口上文件夹，并请用户确认后回写
$kojoRoot = Join-Path $root 'ERB\口上・メッセージ関連\個人口上'
foreach ($cid in ($cids.Keys | Sort-Object)) {
    $needle = "[[MT K$cid" + "_"
    $dirs = @()
    if (Test-Path $kojoRoot) {
        # 注意：必须用 @() 包住，否则单个结果会变成标量字符串，$dirs[0] 就取成首字符（比如只显示 "D"）
        $dirs = @(Get-ChildItem -LiteralPath $kojoRoot -Recurse -Filter *.ERB -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "M_KOJO_K$cid`_*" } |
            Where-Object { ([System.IO.File]::ReadAllText($_.FullName, $utf8n)).Contains($needle) } |
            Select-Object -ExpandProperty DirectoryName -Unique)
    }
    Write-Host ""
    Write-Host ("  === 角色 K$cid ===") -ForegroundColor Cyan
    $target = $null
    $pathHint = "（请粘贴口上文件夹的【绝对路径】——就是里面装着 .ERB 文件的那个文件夹，路径用 \ 分段，例如 D:\游戏\ERB\...\角色名）"
    if ($dirs.Count -eq 1) {
        Write-Host ("  检测到含这些测试语句的口上文件夹：`n     {0}" -f $dirs[0])
        $ok = Read-Host "  确认就改这个文件夹吗？(Y=是 / P=打开文件夹选择窗口 / 或粘贴绝对路径)"
        if     ($ok -match '^[Yy]$') { $target = $dirs[0] }
        elseif ($ok -match '^[Pp]$') { $target = Pick-Folder }
        elseif ($ok) { $target = $ok.Trim('"').Trim() }
    } elseif ($dirs.Count -gt 1) {
        Write-Host "  检测到多个可能的文件夹（可能你在同时开发多个变体），请确认要改哪个：" -ForegroundColor Yellow
        for ($k=0; $k -lt $dirs.Count; $k++) { Write-Host ("     [{0}] {1}" -f $k, $dirs[$k]) }
        Write-Host "  $pathHint" -ForegroundColor DarkGray
        $sel = Read-Host "  输入序号选择 / P=打开文件夹选择窗口 / 或粘贴绝对路径 / 回车跳过"
        if     ($sel -match '^\d+$' -and [int]$sel -lt $dirs.Count) { $target = $dirs[[int]$sel] }
        elseif ($sel -match '^[Pp]$') { $target = Pick-Folder }
        elseif ($sel) { $target = $sel.Trim('"').Trim() }
    } else {
        Write-Host "  没能自动找到含这些标记的 K$cid 口上文件夹，即将弹出文件夹选择窗口……" -ForegroundColor Yellow
        $target = Pick-Folder
        if (-not $target) {
            Write-Host "  $pathHint" -ForegroundColor DarkGray
            $sel = Read-Host "  （或直接粘贴该口上文件夹的绝对路径，回车跳过 K$cid）"
            if ($sel) { $target = $sel.Trim('"').Trim() }
        }
    }
    if (-not $target) { Write-Host "  跳过 K$cid。" -ForegroundColor DarkGray; continue }
    if (-not (Test-Path -LiteralPath $target)) { Write-Host "  路径不存在，跳过：$target" -ForegroundColor Red; continue }
    Write-Host "  回写中 ..." -ForegroundColor Cyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File $scan -CliLog $log -KojoDir $target -Apply
}

Write-Host ""
Write-Host "  全部完成。test_result.txt 已更新；已回写的分支状态变为 测试通过、测试语句已删除。" -ForegroundColor Green
Read-Host "  按回车关闭本窗口"
