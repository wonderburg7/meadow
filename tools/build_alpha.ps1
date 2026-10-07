<#
Builds the Windows alpha archive.
Run with PowerShell 5.1+ from any directory; this script changes to the repository root.

Godot is found the way tools/godot_compile_check.py finds it: -Godot, then
MEADOW_GODOT_PATH, GODOT_PATH, the Windows default, then PATH. A GUI
Godot.exe is swapped for the Godot_console.exe beside it, because
PowerShell does not wait for a GUI program or see its exit code (until
7 Oct 2026 the script reported "exit code ." and stopped).
#>
[CmdletBinding()]
param(
    [string]$Godot = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

function Resolve-Godot {
    param([string]$Requested)
    $candidates = @($Requested, $env:MEADOW_GODOT_PATH, $env:GODOT_PATH, "C:\Program Files\Godot\Godot.exe")
    $found = $null
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) { $found = $candidate; break }
    }
    if (-not $found) {
        foreach ($name in @("godot", "godot4", "Godot")) {
            $command = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($command) { $found = $command.Source; break }
        }
    }
    if (-not $found) {
        throw "No Godot found. Pass -Godot <path to Godot_console.exe> or set MEADOW_GODOT_PATH."
    }
    $console = Join-Path (Split-Path -Parent $found) ([IO.Path]::GetFileNameWithoutExtension($found) + "_console.exe")
    if ($found -notmatch "_console\.exe$" -and (Test-Path -LiteralPath $console -PathType Leaf)) {
        return $console
    }
    return $found
}

$godotPath = Resolve-Godot $Godot

$versionMatch = Select-String -Path "project.godot" -Pattern '^\s*config/version\s*=\s*"([^"]+)"\s*$' | Select-Object -First 1
if (-not $versionMatch) {
    throw "project.godot has no config/version."
}
$version = $versionMatch.Matches[0].Groups[1].Value

# Godot names its template folder from its own version ("4.7.2.stable").
# Checking first turns a 30 s import ending in a buried error into one line.
$engineVersion = ((& $godotPath --version) | Out-String).Trim()
$templateFolder = ($engineVersion -split "\.")[0..3] -join "."
$template = Join-Path $env:APPDATA "Godot\export_templates\$templateFolder\windows_release_x86_64.exe"
if ($env:APPDATA -and -not (Test-Path -LiteralPath $template)) {
    throw "Godot $templateFolder has no Windows export templates ($template is missing). Install them once: open the Godot editor, Editor -> Manage Export Templates -> Download and Install."
}

$outputDirectory = Join-Path $projectRoot "build/windows"
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$executable = Join-Path $outputDirectory "Meadow.exe"

# Godot writes warnings to stderr; under "Stop", Windows PowerShell 5.1
# turns the first one into a terminating error, so only the exit code
# decides whether the export failed.
$ErrorActionPreference = "Continue"
$exportLog = & $godotPath --headless --path $projectRoot --export-release "Windows Desktop" $executable 2>&1 | ForEach-Object { "$_" }
$exportExit = $LASTEXITCODE
$ErrorActionPreference = "Stop"
if ($exportExit -ne 0) {
    $exportLog | Where-Object { $_ -match "ERROR|template" } | Select-Object -First 12 | ForEach-Object { Write-Output $_ }
    throw "Godot export failed with exit code $exportExit."
}

$zipPath = Join-Path $projectRoot "build/Meadow-$version-windows.zip"
Compress-Archive -Path (Join-Path $outputDirectory "*") -DestinationPath $zipPath -Force
$zip = Get-Item -LiteralPath $zipPath
Write-Output "$($zip.FullName) ($($zip.Length) bytes)"
