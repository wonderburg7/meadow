<#
Watch for the recurring Godot "referenced memory at 0x58" crash and record
which launch it was.

Windows reports that crash as a System-log event 26 popup, not an
Application event 1000 (docs/known-pitfalls.md). While the popup is on
screen the crashed Godot is still alive, so this script can read its command
line, its parent and its module base, and turn the faulting address into an
RVA that is the same on every run. It also logs every Godot launch it sees,
so a crash can be matched to its launcher afterwards.

It only reads. It never kills or dismisses anything: leave the popup up
until the "CRASH" block has been written, then close it.

Run (Windows PowerShell 5.1, any directory):
    powershell -NoProfile -File C:\Users\dl13860\Documents\Meadow\meadow\tools\godot_crash_watch.ps1
Output goes to the console and to %TEMP%\godot-crash-watch.log.
#>
param(
    [string]$LogPath = (Join-Path $env:TEMP "godot-crash-watch.log"),
    [int]$PollMs = 500
)

$imageSize = 0xAC92000  # SizeOfImage of the official 4.7.1 win64 Godot.exe
$seen = @{}
$lastEventTime = Get-Date

function Write-Watch([string]$text) {
    $line = "{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $text
    Write-Host $line
    Add-Content -LiteralPath $LogPath -Value $line
}

function Get-GodotDetail($proc) {
    $base = $null
    try { $base = [int64]$proc.MainModule.BaseAddress } catch {}
    $cim = Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)" -ErrorAction SilentlyContinue
    $parent = $null
    if ($cim) {
        $parent = Get-CimInstance Win32_Process -Filter "ProcessId=$($cim.ParentProcessId)" -ErrorAction SilentlyContinue
    }
    [PSCustomObject]@{
        Id      = $proc.Id
        Base    = $base
        Command = if ($cim) { $cim.CommandLine } else { "?" }
        Parent  = if ($parent) { "$($parent.ProcessId) $($parent.CommandLine)" } else { "?" }
    }
}

Write-Watch "watching for Godot launches and event-26 crash popups (log: $LogPath)"
while ($true) {
    foreach ($proc in Get-Process -Name "Godot*" -ErrorAction SilentlyContinue) {
        $key = "$($proc.Id)/$($proc.StartTime.Ticks)"
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = Get-GodotDetail $proc
        $d = $seen[$key]
        Write-Watch ("launch pid {0} base {1:X} :: {2} :: parent {3}" -f $d.Id, $d.Base, $d.Command, $d.Parent)
    }

    $events = Get-WinEvent -FilterHashtable @{ LogName = "System"; Id = 26; StartTime = $lastEventTime } -ErrorAction SilentlyContinue |
        Where-Object { $_.Message -match "Godot" -and $_.TimeCreated -gt $lastEventTime }
    foreach ($evt in ($events | Sort-Object TimeCreated)) {
        $lastEventTime = $evt.TimeCreated
        $message = $evt.Message -replace "\s+", " "
        Write-Watch "CRASH event 26: $message"
        if ($message -notmatch "instruction at 0x([0-9A-Fa-f]+)") { continue }
        $address = [Convert]::ToInt64($Matches[1], 16)
        $matched = $false
        foreach ($proc in Get-Process -Name "Godot*" -ErrorAction SilentlyContinue) {
            $d = Get-GodotDetail $proc
            if ($null -eq $d.Base -or $address -lt $d.Base -or $address -ge $d.Base + $imageSize) { continue }
            $matched = $true
            Write-Watch ("CRASH  pid {0}  RVA 0x{1:X}  base {2:X}" -f $d.Id, ($address - $d.Base), $d.Base)
            Write-Watch "CRASH  command: $($d.Command)"
            Write-Watch "CRASH  parent:  $($d.Parent)"
        }
        if (-not $matched) { Write-Watch "CRASH  no live Godot process contains that address (popup already closed?)" }
    }
    Start-Sleep -Milliseconds $PollMs
}
