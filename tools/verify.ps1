[CmdletBinding()]
param(
    [string]$PythonPath
)

$ErrorActionPreference = "Stop"

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

$python = Resolve-Python $PythonPath
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
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
    Receive-Job -Job $job
    if ($job.State -ne "Completed") {
        Write-Error "$($job.Name) did not complete successfully."
        $failed = $true
    }
}
Remove-Job -Job $jobs -Force

if ($failed) {
    exit 1
}

& $python (Join-Path $repoRoot "tools/update_function_map.py") --check
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $python (Join-Path $repoRoot "tools/check_docs.py")
exit $LASTEXITCODE
