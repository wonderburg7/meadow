[CmdletBinding(PositionalBinding = $false)]
param(
    [string]$PythonPath,
    [switch]$Route,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ScenarioArguments
)

$ErrorActionPreference = "Stop"
$runner = if ($Route) {
    Join-Path $PSScriptRoot "headless\route.py"
} else {
    Join-Path $PSScriptRoot "run_scenario.py"
}

if ($PythonPath) {
    if (-not (Test-Path -LiteralPath $PythonPath -PathType Leaf)) {
        throw "-PythonPath does not name a file: $PythonPath"
    }
    $pythonCommand = $PythonPath
    $pythonPrefix = @()
} else {
    $pythonCommand = $null
    $pythonPrefix = @()
    foreach ($candidate in @("python", "python3", "py")) {
        $found = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($found) {
            $pythonCommand = $found.Source
            if ($candidate -eq "py") {
                $pythonPrefix = @("-3")
            }
            break
        }
    }
    if (-not $pythonCommand) {
        throw "No Python interpreter found. Install Python, make python/python3/py available, or pass -PythonPath."
    }
}

& $pythonCommand @pythonPrefix $runner @ScenarioArguments
exit $LASTEXITCODE
