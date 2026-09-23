<#
Builds the Windows alpha archive.
Run with PowerShell 5.1+ from any directory; this script changes to the repository root.
#>
[CmdletBinding()]
param(
    [string]$Godot = "godot"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$versionMatch = Select-String -Path "project.godot" -Pattern '^\s*config/version\s*=\s*"([^"]+)"\s*$' | Select-Object -First 1
if (-not $versionMatch) {
    throw "project.godot has no config/version."
}
$version = $versionMatch.Matches[0].Groups[1].Value

$outputDirectory = Join-Path $projectRoot "build/windows"
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$executable = Join-Path $outputDirectory "Meadow.exe"

& $Godot --headless --path $projectRoot --export-release "Windows Desktop" $executable
if ($LASTEXITCODE -ne 0) {
    throw "Godot export failed with exit code $LASTEXITCODE."
}

$zipPath = Join-Path $projectRoot "build/Meadow-$version-windows.zip"
Compress-Archive -Path (Join-Path $outputDirectory "*") -DestinationPath $zipPath -Force
$zip = Get-Item -LiteralPath $zipPath
Write-Output "$($zip.FullName) ($($zip.Length) bytes)"
