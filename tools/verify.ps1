[CmdletBinding()]
param(
    [string]$PythonPath,
    [switch]$Quiet,
    [switch]$Docs,
    [switch]$ResolvePythonOnly,
    [ValidateSet("branch", "primary", "all")]
    [string]$Scope = "all"
)

$ErrorActionPreference = "Stop"

# Stage results are recorded to the shared diagnostic log so that "which check
# fails, how often, and how long it takes" is a query rather than an
# impression. Write-Diagnostic never fails its caller -- see tools/diagnostics.ps1.
. (Join-Path $PSScriptRoot "diagnostics.ps1")

# A failed stage only names itself when a switch was passed; the plain
# no-switch run prints exactly what it always has.
$labelFailures = $Quiet.IsPresent -or $Docs.IsPresent

function Resolve-Python {
    param([string]$RequestedPath)

    if ($RequestedPath) {
        if (-not (Test-Path -LiteralPath $RequestedPath -PathType Leaf)) {
            throw "The supplied Python interpreter does not exist: $RequestedPath"
        }
        return (Resolve-Path -LiteralPath $RequestedPath).Path
    }

    foreach ($candidate in @("python", "python3", "py")) {
        $command = Get-Command $candidate -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) {
            return $command.Source
        }
    }

    # Codex's primary runtime keeps Python beside the native tools whose
    # directories are injected into the task's PATH. Python itself is not on
    # PATH, so use those running-shell dependency paths to find its sibling.
    # Walk command sources too: a caller may have trimmed PATH after this
    # PowerShell process resolved Git or Node from the bundle.
    $seeds = @()
    if ($env:PATH) {
        $seeds += @($env:PATH -split [System.IO.Path]::PathSeparator)
    }
    $seeds += @($PSHOME)
    foreach ($commandName in @("git", "node", "powershell", "pwsh")) {
        $seeds += @(Get-Command $commandName -All -CommandType Application -ErrorAction SilentlyContinue |
            ForEach-Object { $_.Source })
    }

    $dependencyRoots = @()
    foreach ($seed in $seeds | Where-Object { $_ } | Select-Object -Unique) {
        try {
            $current = [System.IO.Path]::GetFullPath($seed.Trim('"'))
            if ([System.IO.Path]::HasExtension($current)) {
                $current = Split-Path -Parent $current
            }
            while ($current) {
                $leaf = Split-Path -Leaf $current
                $parent = Split-Path -Parent $current
                if ($leaf -eq "dependencies" -and
                    (Split-Path -Leaf $parent) -eq "codex-primary-runtime") {
                    $dependencyRoots += $current
                    break
                }
                if (-not $parent -or $parent -eq $current) { break }
                $current = $parent
            }
        }
        catch {
            # Ignore malformed or transient PATH entries and keep looking.
        }
    }

    foreach ($dependencyRoot in $dependencyRoots | Select-Object -Unique) {
        $candidate = Join-Path $dependencyRoot "python\python.exe"
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "Python was not found on PATH or in the codex-primary-runtime dependency tree. Install Python, or rerun with -PythonPath <path-to-python.exe>."
}

# The branch and the first failing line ride on each stage event, so a failure
# in the log can be classified without rerunning it (V-2: five lifecycle
# failures in seven days could not be told apart).
$stageBranch = ""
try { $stageBranch = (& git -C $PSScriptRoot branch --show-current 2>$null | Out-String).Trim() } catch { }

function Get-FailureLine {
    param([object[]]$Output)
    foreach ($line in $Output) {
        $text = "$line".Trim()
        if ($text -match '^(FAIL:|ERROR:|Traceback|.*Error:|.*exited with code)') {
            return $text
        }
    }
    return ""
}

# The lifecycle suite runs on a branch only when its diff against master can
# reach it, and always in the primary scope (V-2). The list is the tooling the
# suite drives.
function Test-LifecycleTouched {
    $paths = @("tools/slice.ps1", "tools/hook_log.py", "tools/archive_slice.py", "tools/refill_lane.py", "tools/check_docs.py", "tools/verify.ps1", "NEXTSTEPS.md", "tests/")
    try {
        $changed = @(& git -C $PSScriptRoot diff --name-only "$(if ($env:MEADOW_VERIFY_BASE) { $env:MEADOW_VERIFY_BASE } else { "master" })...HEAD" 2>$null)
        $changed += @(& git -C $PSScriptRoot diff --name-only HEAD 2>$null)
        if ($LASTEXITCODE -ne 0) { return $true }
    }
    catch { return $true }
    foreach ($file in $changed) {
        foreach ($path in $paths) {
            if ($file -eq $path -or ($path.EndsWith("/") -and $file.StartsWith($path))) { return $true }
        }
    }
    return $false
}

function Start-LifecycleJob {
    param($Interpreter, $Root)
    Start-Job -Name "lifecycle tests" -ArgumentList $Interpreter, $Root -ScriptBlock {
        param($interpreter, $root)
        Set-Location $root
        & $interpreter -m unittest tests.test_source_checks tests.test_slice_lifecycle tests.test_two_lane_closeout tests.test_codex_environment tests.test_verify_generated tests.test_alpha_build
        if ($LASTEXITCODE -ne 0) {
            throw "workflow unittest modules exited with code $LASTEXITCODE"
        }
    }
}

# One line per stage under -Quiet; a stage that fails replays everything it
# printed, so nothing is lost by being quiet on success.
function Write-StageResult {
    param(
        [string]$Name,
        [bool]$Ok,
        [object[]]$Output,
        [string]$FailureNote,
        [int]$Ms = 0
    )

    $fields = @{
        stage  = $Name
        ok     = $Ok
        ms     = $Ms
        scope  = $Scope
        branch = $stageBranch
    }
    if (-not $Ok) {
        $fields.failure = Get-FailureLine -Output $Output
    }
    Write-Diagnostic -Kind "verify_stage" -Fields $fields

    if ($Ok) {
        if ($Quiet) {
            Write-Output "${Name}: OK"
        }
        return
    }

    if ($labelFailures) {
        $heading = "${Name}: FAILED"
        if ($FailureNote) {
            $heading = "$heading ($FailureNote)"
        }
        Write-Output $heading
    }
    if ($Quiet -and $Output) {
        $Output | ForEach-Object { Write-Output $_ }
    }
}

# Runs one Python check and reports it. Under -Quiet the output is captured so
# a passing stage collapses to a single line; otherwise it streams as before.
# Sets $script:lastStageExit to the stage's exit code.
function Invoke-PythonStage {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [string[]]$ScriptArgs = @(),
        [string]$FailureNote,
        [switch]$RegenerateNote
    )

    $captured = @()
    $stageTimer = [System.Diagnostics.Stopwatch]::StartNew()
    if ($Quiet) {
        # A native command's stderr becomes a terminating error under "Stop",
        # so capture with errors demoted to ordinary output lines.
        $ErrorActionPreference = "Continue"
        $captured = @(& $python $ScriptPath @ScriptArgs 2>&1 | ForEach-Object { $_.ToString() })
        $exit = $LASTEXITCODE
    }
    else {
        & $python $ScriptPath @ScriptArgs
        $exit = $LASTEXITCODE
    }

    $stageTimer.Stop()
    Write-StageResult -Name $Name -Ok ($exit -eq 0) -Output $captured -FailureNote $FailureNote -Ms ([int]$stageTimer.ElapsedMilliseconds)
    if ($RegenerateNote -and $exit -eq 0) {
        # Never silent: say what the generator did, whether or not -Quiet hid it.
        $captured | Where-Object { $_ -like "regenerated *" } | ForEach-Object { Write-Output "${Name}: $_" }
    }
    $script:lastStageExit = $exit
}

# Runs a generator in write mode, then re-asserts with --check so a generator
# that cannot reproduce its own output still fails. A regeneration is reported
# in the stage output (even under -Quiet) and left uncommitted in the tree.
function Invoke-RegenerateStage {
    param([string]$Name, [string]$ScriptPath)

    Invoke-PythonStage -Name $Name -ScriptPath $ScriptPath -RegenerateNote
    if ($script:lastStageExit -ne 0) { return }
    Invoke-PythonStage -Name "$Name (recheck)" -ScriptPath $ScriptPath -ScriptArgs @("--check")
}

$python = Resolve-Python $PythonPath
if ($ResolvePythonOnly) {
    Write-Output $python
    exit 0
}
$env:PYTHONDONTWRITEBYTECODE = "1"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

# -Scope separates the branch's own suites from the primary checkout's
# planning/ledger check, so a stale row left by the other lane's worktree
# cannot fail a branch that never touched it. -Docs still skips the source,
# balance and function-map stages within the branch scope: a
# documentation-only slice does not need the code suites.
$runBranchScope = $Scope -in @("branch", "all")
$runPrimaryScope = $Scope -in @("primary", "all")

if ($runBranchScope -and -not $Docs) {
    $jobs = @(
        (Start-Job -Name "source checks" -ArgumentList $python, $repoRoot -ScriptBlock {
            param($interpreter, $root)
            Set-Location $root
            & $interpreter tests/source_checks.py
            if ($LASTEXITCODE -ne 0) {
                throw "source_checks.py exited with code $LASTEXITCODE"
            }
        })
        (Start-Job -Name "balance tests" -ArgumentList $python, $repoRoot -ScriptBlock {
            param($interpreter, $root)
            Set-Location $root
            & $interpreter tests/balance_tests.py
            if ($LASTEXITCODE -ne 0) {
                throw "balance_tests.py exited with code $LASTEXITCODE"
            }
        })
    )
    # The lifecycle suite itself drives finish/resume in temporary
    # repositories. Running it from the finish verifier recursively starts
    # another finish verifier, so the outer closeout can never return. It
    # remains part of ordinary verification; closeout runs the non-recursive
    # branch checks here instead.
    if ($env:MEADOW_FINISH_VERIFY -ne "1") {
        if (Test-LifecycleTouched) {
            $jobs += (Start-LifecycleJob -Interpreter $python -Root $repoRoot)
        }
        else {
            Write-Output "lifecycle tests: skipped -- branch touches no lifecycle tooling"
            Write-Diagnostic -Kind "verify_stage" -Fields @{ stage = "lifecycle tests"; skipped = $true; scope = $Scope; branch = $stageBranch }
        }
    }

    Wait-Job -Job $jobs | Out-Null
    $failed = $false
    foreach ($job in $jobs) {
        # A job records its own start and end, so the three parallel stages --
        # the slowest in the run -- are measured without a stopwatch each.
        $jobMs = 0
        if ($job.PSBeginTime -and $job.PSEndTime) {
            $jobMs = [int](($job.PSEndTime - $job.PSBeginTime).TotalMilliseconds)
        }
        if ($Quiet) {
            $captured = @(Receive-Job -Job $job -ErrorAction SilentlyContinue 2>&1 | ForEach-Object { $_.ToString() })
            $ok = ($job.State -eq "Completed")
            Write-StageResult -Name $job.Name -Ok $ok -Output $captured -Ms $jobMs
            if (-not $ok) {
                $failed = $true
            }
        }
        else {
            # unittest writes its progress dots to stderr. Under Windows
            # PowerShell 5.1 with ErrorActionPreference Stop, Receive-Job
            # re-emits that as a NativeCommandError and aborts a passing run,
            # so print stderr as text and judge the job by its State: the job
            # throws on a non-zero exit code.
            $plainOutput = @(Receive-Job -Job $job -ErrorAction SilentlyContinue 2>&1 | ForEach-Object { $_.ToString() })
            $plainOutput | ForEach-Object { Write-Output $_ }
            $ok = ($job.State -eq "Completed")
            # The -Quiet branch above records its stages through
            # Write-StageResult; this branch prints directly, so it records
            # its own or the plain run would be missing from the log.
            $plainFields = @{ stage = $job.Name; ok = $ok; ms = $jobMs; scope = $Scope; branch = $stageBranch }
            if (-not $ok) { $plainFields.failure = Get-FailureLine -Output $plainOutput }
            Write-Diagnostic -Kind "verify_stage" -Fields $plainFields
            if (-not $ok) {
                Write-Output "$($job.Name): FAILED"
                $failed = $true
            }
        }
    }
    Remove-Job -Job $jobs -Force

    if ($failed) {
        exit 1
    }

    Invoke-RegenerateStage -Name "function map" -ScriptPath (Join-Path $repoRoot "tools/update_function_map.py")
    if ($lastStageExit -ne 0) {
        exit $lastStageExit
    }

    # The Python suites cannot see a GDScript parse error. One headless boot
    # can: on 12 Sep 2026 a call to a Rect2 method that does not exist in
    # Godot 4 failed hud.gd's compile, took main.gd down with it and shipped
    # a game with no HUD at all. Skips itself, passing, where no Godot
    # binary is installed.
    Invoke-PythonStage -Name "godot boot" -ScriptPath (Join-Path $repoRoot "tools/godot_compile_check.py") -FailureNote "the project does not boot"
    if ($lastStageExit -ne 0) {
        exit $lastStageExit
    }
}

if ($runBranchScope) {
    # docs/challenge-stages.md is generated from scripts/challenge_stages.gd,
    # so a stage edit that does not regenerate it fails here rather than
    # leaving a reference nobody can trust (Dave, 8 Sep 2026).
    Invoke-RegenerateStage -Name "stage reference" -ScriptPath (Join-Path $repoRoot "tools/stage_reference.py")
    if ($lastStageExit -ne 0) {
        exit $lastStageExit
    }
}

if ($Scope -eq "primary" -and $env:MEADOW_FINISH_VERIFY -ne "1") {
    # The post-merge run: the suite runs here whatever the diff was.
    $lifecycleTimer = [System.Diagnostics.Stopwatch]::StartNew()
    $lifecycleJob = Start-LifecycleJob -Interpreter $python -Root $repoRoot
    Wait-Job -Job $lifecycleJob | Out-Null
    $lifecycleOutput = @(Receive-Job -Job $lifecycleJob -ErrorAction SilentlyContinue 2>&1 | ForEach-Object { $_.ToString() })
    $lifecycleOk = ($lifecycleJob.State -eq "Completed")
    Remove-Job -Job $lifecycleJob -Force
    Write-StageResult -Name "lifecycle tests" -Ok $lifecycleOk -Output $lifecycleOutput -Ms ([int]$lifecycleTimer.ElapsedMilliseconds)
    if (-not $lifecycleOk) {
        if (-not $Quiet) { $lifecycleOutput | ForEach-Object { Write-Output $_ } }
        Write-Output "lifecycle tests: FAILED"
        exit 1
    }
}

if ($runPrimaryScope) {
    # The doc stage's failures are planning bookkeeping, not a code failure,
    # and say so -- the code suites' passes stay visible above them.
    Invoke-PythonStage -Name "doc checks" -ScriptPath (Join-Path $repoRoot "tools/check_docs.py") -FailureNote "planning/ledger, not code"
    if ($lastStageExit -ne 0) {
        exit $lastStageExit
    }
}

exit 0
