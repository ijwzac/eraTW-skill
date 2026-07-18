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
Write-Host "    [1] 开发者版(调试模式)  —— 想要 Debug 窗口与调试信息就用它"
Write-Host "    [2] 普通玩家版          —— 平时游玩用它"
Write-Host "  两个版本都能触发手动测试与自动测试（自动测试靠 autotest.txt 内容开关，与存档无关，不用调试台）。"
Write-Host "  Debug 窗口能输入作弊/调试指令，具体可询问 AI。"
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
$go = Read-Host "  确认继续请输入 Y 或 1 回车（其它则取消）"
if ($go -notmatch '^[Yy1]') { Write-Host "  已取消。" -ForegroundColor DarkGray; Read-Host "  回车退出"; exit 0 }

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

# ================= 自动测试开关：扫描本 skill 口上的 autotest.txt、询问是否启用 =================
# 本工具写的每个口上目录里放着 autotest.txt，【内容】= on(启用) / off(禁用)。扫出它即可发现哪些
# 口上是本工具写的、并读出当前开关。用户选启用/禁用则改写其【内容】（不是改文件名）。
# 会話时口上钩子 LOADTEXT 读它：内容含 on 就跑一次测试套件、结尾 SAVETEXT 写回 off（自动关）。
# 【与游戏存档完全无关】：任何存档只要 autotest.txt=on、会話一次就触发；跑完自动写回 off。
$kojoRoot = Join-Path $root 'ERB\口上・メッセージ関連\個人口上'
$sentinels = @()
if (Test-Path -LiteralPath $kojoRoot) {
    $sentinels = @(Get-ChildItem -LiteralPath $kojoRoot -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'autotest.txt' })
}
if ($sentinels.Count -gt 0) {
    Write-Host ""
    Write-Host "  ──────────────── 自动测试 AUTOTEST ────────────────" -ForegroundColor Cyan
    Write-Host "  发现 $($sentinels.Count) 个本工具写的口上带自动测试，当前开关（autotest.txt 内容）："
    foreach ($s in $sentinels) {
        $content = ''
        try { $content = ([System.IO.File]::ReadAllText($s.FullName)).Trim() } catch {}
        $on = ($content -match 'on')
        $kojo = Split-Path -Leaf (Split-Path -Parent $s.FullName)
        Write-Host ("     [{0}] {1}" -f $(if ($on) { '已启用' } else { '已禁用' }), $kojo) -ForegroundColor $(if ($on) { 'Green' } else { 'DarkGray' })
    }
    Write-Host "  启用后：读档进游戏、跟该角色【会話】一次即自动跑完整测试套件（与存档无关，跑完自动关）。"
    $atc = Read-Host "  [A 或 1]全部启用  [N 或 2]全部禁用  [回车]保持不变"
    if ($atc -match '^[Aa1]') {
        foreach ($s in $sentinels) { [System.IO.File]::WriteAllText($s.FullName, 'on') }
        Write-Host "  ✓ 已全部【启用】自动测试（autotest.txt 内容 -> on）。" -ForegroundColor Green
    } elseif ($atc -match '^[Nn2]') {
        foreach ($s in $sentinels) { [System.IO.File]::WriteAllText($s.FullName, 'off') }
        Write-Host "  ✓ 已全部【禁用】自动测试（autotest.txt 内容 -> off）。" -ForegroundColor DarkGray
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
    Write-Host "     跑完后测试套件会把 autotest.txt 写回 off（自动关），所以【与存档无关、不会重复触发】。"
    Write-Host "     想再跑一轮：关掉游戏、重开本启动器再选【启用】即可（任何存档都行）；或手动把 autotest.txt 内容改回 on。"
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
function Get-KojoRel([string]$blockText) {
    $km = [regex]::Match($blockText, '(?m)^\s*\[\[KOJODIR\s+(.+)\]\]\s*$')
    if ($km.Success) { return $km.Groups[1].Value.Trim() } else { return '' }
}
function Get-AutotestBlocks {
    # 返回本轮 cliplog 里【所有】口上的 AUTOTEST 块（可能多个角色同轮跑），按出现顺序。
    # 每项：@{ Cid=角色号; Raw=块文本; KojoRel=块内[[KOJODIR]]相对路径; Halted=有BEGIN无自己的END(崩溃) }
    if (-not (Test-Path $log)) { return @() }
    $txt = [System.IO.File]::ReadAllText($log, $utf8n)
    $res = [ordered]@{}
    # 完整块（BEGIN...自己的 END 成对）
    foreach ($m in [regex]::Matches($txt, '(?s)=====AUTOTEST_(\w+?)_BEGIN=====.*?=====AUTOTEST_\1_END=====')) {
        $cid = ($m.Groups[1].Value -replace '^[Kk]','')
        if ($res.Contains($cid)) { continue }
        $res[$cid] = @{ Cid = $cid; Raw = $m.Value; KojoRel = (Get-KojoRel $m.Value); Halted = $false }
    }
    # 崩溃块（有 BEGIN 但没有配对 END）——游戏崩溃会 halt，故它必是日志里最后的 AUTOTEST，取到尾即可
    foreach ($m in [regex]::Matches($txt, '=====AUTOTEST_(\w+?)_BEGIN=====')) {
        $tag = $m.Groups[1].Value; $cid = ($tag -replace '^[Kk]','')
        if ($res.Contains($cid)) { continue }
        $bg = [regex]::Match($txt, "(?s)=====AUTOTEST_${tag}_BEGIN=====.*")
        $raw = if ($bg.Success) { $bg.Value } else { '' }
        $res[$cid] = @{ Cid = $cid; Raw = $raw; KojoRel = (Get-KojoRel $raw); Halted = $true }
    }
    return @($res.Values)
}
function Write-SessionSummary($sum, $atBlocks, $mtTids) {
    # 把本轮会话小结追加到 cliplog 末尾：编译错误/运行崩溃/各口上自动测试结果+是否回写+【触发的每个TID及判定】/
    # 手动测试+是否回写+【触发的每个MT标记】。多写几十行无妨，方便 AI/用户复盘到底测了哪些分支。
    $L = @()
    $L += "===== [启动器附加] 本轮测试会话小结（$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')）====="
    $L += ("· 编译/脚本错误：{0}" -f $(if ($sum.CompileError) { '是 —— 游戏未能正常启动（见上）' } else { '否' }))
    $L += ("· 运行中崩溃：{0}"   -f $(if ($sum.RuntimeCrash) { '是 —— 见上方并入的 emuera.log 堆栈' } else { '否' }))
    $L += "· 自动测试 AUTOTEST："
    if (-not $sum.Auto -or $sum.Auto.Count -eq 0) { $L += "    （本轮未跑）" }
    else {
        foreach ($a in $sum.Auto) {
            $L += ("    - K{0}：{1}；回写：{2}" -f $a.Cid, $a.Result, $a.Written)
            # 列出该口上触发的每个 TID + 判定（END 在则全通过；halt 则最后一个 BEGIN 是崩溃点、失败）
            $blk = @($atBlocks | Where-Object { $_.Cid -eq $a.Cid }) | Select-Object -First 1
            if ($blk) {
                $bg = @([regex]::Matches($blk.Raw, '\[\[TID\s+(\S+)\s+BEGIN\]\]') | ForEach-Object { $_.Groups[1].Value })
                $last = if ($bg.Count) { $bg[$bg.Count - 1] } else { $null }
                foreach ($t in $bg) {
                    $vd = if (-not $blk.Halted) { '通过' } elseif ($t -eq $last) { '失败(崩溃点)' } else { '通过' }
                    $L += ("        · {0}  {1}" -f $t, $vd)
                }
            }
        }
    }
    $L += "· 手动测试："
    if (-not $mtTids -or @($mtTids).Count -eq 0) { $L += "    （本轮无触发的手动标记）" }
    else {
        # 按角色分组，列出每个触发的 MT 标记
        $byC = @{}
        foreach ($t in $mtTids) { if ($t -match '^K(\d+)_') { $c = $Matches[1]; if (-not $byC.ContainsKey($c)) { $byC[$c] = @() }; $byC[$c] += $t } }
        foreach ($h in $sum.Manual) {
            $L += ("    - K{0}：触发 {1} 个标记；回写：{2}" -f $h.Cid, $h.Count, $h.Written)
            foreach ($t in $byC[$h.Cid]) { $L += ("        · {0}" -f $t) }
        }
    }
    $L += "===== 小结结束 ====="
    [System.IO.File]::AppendAllText($log, "`r`n" + ($L -join "`r`n") + "`r`n", $utf8n)
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
function Write-Result([array]$atBlocks, [string[]]$tids, [bool]$final) {
    $s = @()
    $s += "=== eraTW 测试结果（自动生成；把本文件整段发给 AI 即可评审）==="
    $s += ("生成时间：" + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    $s += ""
    $s += "【一、自动测试 AUTOTEST 输出】"
    if ($atBlocks -and $atBlocks.Count) {
        foreach ($b in $atBlocks) {
            $s += ("---- 口上 K{0}{1} ----" -f $b.Cid, $(if ($b.Halted) { '（中途崩溃 halt！）' } else { '' }))
            $s += $b.Raw
            $s += ""
        }
    } else { $s += "  （本次运行未包含 AUTOTEST）" }
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
    if ($choice -eq '1') { Write-Host "  │ 跑自动测试（如有）：启动前选了【启用】就直接点「会話」，跑完自动关；要再跑重开启动器选启用即可（不用调试台）。" -ForegroundColor DarkGray }
    else                 { Write-Host "  │ 正常游玩即可；触发到需手动测试的对话时看到 [[MT ...]] 测试语句是正常的。" -ForegroundColor DarkGray }
    if ($atShown) { Write-Host "  │ ✓ 已抽出 AUTOTEST 结果 -> test_result.txt" -ForegroundColor Green }
    Write-Host "  └───────────── 游戏输出的最后 20 行 ──────────────" -ForegroundColor Cyan
    if (Test-Path $log) {
        $sz = (Get-Item $log).Length
        if ($sz -ne $lastSize) {
            $lastSize = $sz
            $at = Get-AutotestBlocks
            if ($at.Count) { $atShown = $true }
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
    Write-SessionSummary @{ CompileError = $true; RuntimeCrash = $false; Auto = @(); Manual = @() } @() @()
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

$atBlocks = Get-AutotestBlocks
$mtTids   = Get-ManualTids
Write-Result $atBlocks $mtTids $true
Write-Host ""
if ($atBlocks.Count) { Write-Host ("  ✓ AUTOTEST 结果已写入 test_result.txt（{0} 个口上）" -f $atBlocks.Count) -ForegroundColor Green } else { Write-Host "  · 本次无 AUTOTEST 段。" }
Write-Host ("  ✓ 手动测试：实录中共发现 {0} 处已触发的对话标记。" -f $mtTids.Count) -ForegroundColor Green
Write-Host "     结果文件（可发给 AI）：$resFile" -ForegroundColor Yellow

# 本轮小结累积器（最后写进 cliplog 末尾）。编译错误已在前面 exit，不会到这里；$emuHasCrash 是运行中崩溃。
$sum = @{ CompileError = $false; RuntimeCrash = $emuHasCrash; Auto = @(); Manual = @() }

# ================= 自动测试 AUTOTEST 回写（逐口上，调 at_update.ps1 -Cid 隔离）=================
Write-Host ""
Write-Host "  ──────────────── 自动测试 AUTOTEST 结果 ────────────────" -ForegroundColor Cyan
if ($atBlocks.Count -eq 0) {
    Write-Host "  · 本轮没有跑自动测试（可能只做了手动测试），跳过自动测试回写。" -ForegroundColor DarkGray
} else {
    if ($atBlocks.Count -gt 1) { Write-Host ("  本轮有 {0} 个口上跑了自动测试，将逐个处理、互不干扰。" -f $atBlocks.Count) -ForegroundColor Cyan }
    foreach ($blk in $atBlocks) {
        $cid = $blk.Cid
        $begins = ([regex]::Matches($blk.Raw, '\[\[TID\s+\S+\s+BEGIN\]\]')).Count
        Write-Host ""
        Write-Host ("  === 自动测试 K$cid ===") -ForegroundColor Cyan
        if ($blk.Halted) {
            Write-Host "  [!] 看到 BEGIN 哨兵、却没看到本口上的 END 哨兵 —— 测试套件中途崩溃(halt)。" -ForegroundColor Red
            Write-Host "      test_result.txt 里本口上最后一条 [[TID ... BEGIN]] 之后的分支即崩溃点。仍可回写（其余分支判通过、崩的那条判失败）。" -ForegroundColor Yellow
            $result = "中途崩溃(halt)，$begins 个分支到达"
        } else {
            Write-Host ("  END 哨兵已捕获 → 测试套件完整跑完、无中途崩溃；共 {0} 个分支，全部通过。" -f $begins) -ForegroundColor Green
            Write-Host "  （个别 OK 若被剪贴板边界丢掉也不算失败——END 在就说明整段都跑到了。）" -ForegroundColor DarkGray
            $result = "完整跑完，$begins 个分支通过"
        }
        Write-Host ("  是否把 K$cid 的自动测试结果回写口上代码？（;@AT -> 测试通过/失败）") -ForegroundColor Cyan
        $doAt = Read-Host "  输入 Y 或 1 回车执行；其它则跳过"
        $written = '已跳过'
        if ($doAt -match '^[Yy1]') {
            $rel = $blk.KojoRel
            $atDef = if ($rel) { Join-Path $root ($rel -replace '/','\') } else { '' }
            if ($atDef) { Write-Host ("  从 AUTOTEST 首行识别到 K$cid 的口上文件夹：`n     {0}" -f $atDef) }
            else        { Write-Host "  没能从日志自动识别口上文件夹（该 AUTOTEST 未打印 [[KOJODIR]] 行）。" -ForegroundColor Yellow }
            Write-Host "  （若上面识别错了，请粘贴口上文件夹的【绝对路径】——里面装着 .ERB 文件、路径用 \ 分段）" -ForegroundColor DarkGray
            $ans = Read-Host "  确认就改这个文件夹吗？(Y 或 1=是 / P 或 2=打开文件夹选择窗口 / 或粘贴绝对路径)"
            $atTgt = $null
            if     ($ans -match '^[Yy1]$' -and $atDef) { $atTgt = $atDef }
            elseif ($ans -match '^[Pp2]$') { $atTgt = Pick-Folder }
            elseif ($ans -and $ans -notmatch '^[Yy1]$') { $atTgt = $ans.Trim('"').Trim() }
            if     (-not $atTgt) { Write-Host "  已跳过 K$cid 的自动测试回写。" -ForegroundColor DarkGray }
            elseif (-not (Test-Path -LiteralPath $atTgt)) { Write-Host "  路径不存在，跳过：$atTgt" -ForegroundColor Red; $written = '路径不存在' }
            else {
                Write-Host "  回写 K$cid 自动测试结果中 ..." -ForegroundColor Cyan
                & powershell -NoProfile -ExecutionPolicy Bypass -File $atup -CliLog $log -KojoDir $atTgt -Cid $cid
                $written = "已回写 -> $atTgt"
            }
        } else { Write-Host "  已跳过 K$cid 的自动测试回写。" -ForegroundColor DarkGray }
        $sum.Auto += @{ Cid = $cid; Result = $result; Written = $written }
        Write-Host ("  提醒(K$cid)：测试套件跑完已把 autotest.txt 写回 off（不会重复触发、与存档无关）；想再跑重开启动器选启用即可。发布前记得删 AUTOTEST 钩子+AUTOTEST.ERB+autotest.txt。") -ForegroundColor DarkGray
    }
}

# ================= 手动测试 回写（逐角色，调 manual_scan.ps1）=================
Write-Host ""
Write-Host "  ──────────────── 手动测试 结果 ────────────────" -ForegroundColor Cyan
if ($mtTids.Count -eq 0) {
    Write-Host "  没有手动测试标记可回写。" -ForegroundColor DarkGray
} else {
    $cids = @{}; $mtTids | ForEach-Object { if ($_ -match '^K(\d+)_') { $cids[$Matches[1]] = ($cids[$Matches[1]] + 1) } }
    Write-Host ("`n  涉及角色：{0}" -f (($cids.Keys | Sort-Object | ForEach-Object { "K$_" }) -join ', '))
    $mtTids | ForEach-Object { Write-Host "     $_" -ForegroundColor Green }
    Write-Host ""
    Write-Host "  是否把这些【已触发】的分支回写进口上代码？" -ForegroundColor Cyan
    Write-Host "    （会把对应的  ;@AT 待手动测试 -> 测试通过，并删除那行  PRINTL [[MT ...]]  测试语句）"
    $doApply = Read-Host "  输入 Y 或 1 回车执行；其它则跳过"
    if ($doApply -notmatch '^[Yy1]') {
        Write-Host "  已跳过回写（口上代码未改动）。" -ForegroundColor DarkGray
        foreach ($cid in $cids.Keys) { $sum.Manual += @{ Cid = $cid; Count = $cids[$cid]; Written = '已跳过' } }
    } else {
        $kojoRoot = Join-Path $root 'ERB\口上・メッセージ関連\個人口上'
        foreach ($cid in ($cids.Keys | Sort-Object)) {
            $needle = "[[MT K$cid" + "_"
            $dirs = @()
            if (Test-Path $kojoRoot) {
                $dirs = @(Get-ChildItem -LiteralPath $kojoRoot -Recurse -Filter *.ERB -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "M_KOJO_K$cid`_*" } |
                    Where-Object { ([System.IO.File]::ReadAllText($_.FullName, $utf8n)).Contains($needle) } |
                    Select-Object -ExpandProperty DirectoryName -Unique)
            }
            Write-Host ""
            Write-Host ("  === 角色 K$cid ===") -ForegroundColor Cyan
            $target = $null
            $pathHint = "（请粘贴口上文件夹的【绝对路径】——就是里面装着 .ERB 文件的那个文件夹，路径用 \ 分段）"
            if ($dirs.Count -eq 1) {
                Write-Host ("  检测到含这些测试语句的口上文件夹：`n     {0}" -f $dirs[0])
                $ok = Read-Host "  确认就改这个文件夹吗？(Y 或 1=是 / P 或 2=打开文件夹选择窗口 / 或粘贴绝对路径)"
                if     ($ok -match '^[Yy1]$') { $target = $dirs[0] }
                elseif ($ok -match '^[Pp2]$') { $target = Pick-Folder }
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
            if (-not $target) { Write-Host "  跳过 K$cid。" -ForegroundColor DarkGray; $sum.Manual += @{ Cid = $cid; Count = $cids[$cid]; Written = '已跳过(未定位)' }; continue }
            if (-not (Test-Path -LiteralPath $target)) { Write-Host "  路径不存在，跳过：$target" -ForegroundColor Red; $sum.Manual += @{ Cid = $cid; Count = $cids[$cid]; Written = '路径不存在' }; continue }
            Write-Host "  回写中 ..." -ForegroundColor Cyan
            & powershell -NoProfile -ExecutionPolicy Bypass -File $scan -CliLog $log -KojoDir $target -Apply
            $sum.Manual += @{ Cid = $cid; Count = $cids[$cid]; Written = "已回写 -> $target" }
        }
    }
}

# ================= 写本轮小结到 cliplog 末尾 =================
Write-SessionSummary $sum $atBlocks $mtTids

Write-Host ""
Write-Host "  全部完成。test_result.txt 已更新；本轮小结已附到 cliplog.txt 末尾。" -ForegroundColor Green
Read-Host "  按回车关闭本窗口"
