[CmdletBinding()]
param(
    [string]$PythonPath,
    [switch]$Quiet,
    [switch]$Docs
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
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    throw "Python was not found. Install Python, or rerun with -PythonPath <path-to-python.exe>."
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
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

# -Docs skips the source, balance and function-map stages: a documentation-only
# slice does not need the code suites.
if (-not $Docs) {
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
            Receive-Job -Job $job
            if ($job.State -ne "Completed") {
                Write-Error "$($job.Name) did not complete successfully."
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
}

# The doc stage's failures are planning bookkeeping, not a code failure, and
# say so -- the code suites' passes stay visible above them.
Invoke-PythonStage -Name "doc checks" -ScriptPath (Join-Path $repoRoot "tools/check_docs.py") -FailureNote "planning/ledger, not code"
exit $lastStageExit
