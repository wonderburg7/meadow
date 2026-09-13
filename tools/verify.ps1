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

# One line per stage under -Quiet; a stage that fails replays everything it
# printed, so nothing is lost by being quiet on success.
function Write-StageResult {
    param(
        [string]$Name,
        [bool]$Ok,
        [object[]]$Output,
        [string]$FailureNote
    )

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
        [string]$FailureNote
    )

    $captured = @()
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

    Write-StageResult -Name $Name -Ok ($exit -eq 0) -Output $captured -FailureNote $FailureNote
    $script:lastStageExit = $exit
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
        (Start-Job -Name "lifecycle tests" -ArgumentList $python, $repoRoot -ScriptBlock {
            param($interpreter, $root)
            Set-Location $root
            & $interpreter -m unittest tests.test_source_checks
            if ($LASTEXITCODE -ne 0) {
                throw "tests.test_source_checks exited with code $LASTEXITCODE"
            }
        })
    )

    Wait-Job -Job $jobs | Out-Null
    $failed = $false
    foreach ($job in $jobs) {
        if ($Quiet) {
            $captured = @(Receive-Job -Job $job -ErrorAction SilentlyContinue 2>&1 | ForEach-Object { $_.ToString() })
            $ok = ($job.State -eq "Completed")
            Write-StageResult -Name $job.Name -Ok $ok -Output $captured
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
            Receive-Job -Job $job -ErrorAction SilentlyContinue 2>&1 | ForEach-Object { Write-Output $_.ToString() }
            if ($job.State -ne "Completed") {
                Write-Output "$($job.Name): FAILED"
                $failed = $true
            }
        }
    }
    Remove-Job -Job $jobs -Force

    if ($failed) {
        exit 1
    }

    Invoke-PythonStage -Name "function map" -ScriptPath (Join-Path $repoRoot "tools/update_function_map.py") -ScriptArgs @("--check")
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
    Invoke-PythonStage -Name "stage reference" -ScriptPath (Join-Path $repoRoot "tools/stage_reference.py") -ScriptArgs @("--check") -FailureNote "run python tools/stage_reference.py"
    if ($lastStageExit -ne 0) {
        exit $lastStageExit
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
