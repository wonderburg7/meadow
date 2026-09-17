# Append-only diagnostic event log, shared by every lifecycle script.
#
# One JSON object per line at <git-common-dir>/meadow-diagnostics.jsonl, which
# is the same place Invoke-WithLifecycleLock and Get-ClosingJournalPath already
# put their state: shared by every worktree of this repository, never
# committed, so the two lanes cannot conflict over it. The file is a
# measurement, not a contract -- nothing reads it during a run, and
# `python tools/session_cost.py --events` is the only reader.
#
# Writing a diagnostic never fails its caller. Every error is swallowed: a log
# that breaks `finish` would cost more than it ever measured.

$script:DiagnosticsMaxBytes = 1MB

function Get-DiagnosticsPath {
    param([string]$Root)
    try {
        if (-not $Root) { $Root = (Get-Location).Path }
        $commonDir = (git -C $Root rev-parse --git-common-dir 2>$null)
        if (-not $commonDir) { return $null }
        $commonDir = $commonDir.Trim()
        if (-not [System.IO.Path]::IsPathRooted($commonDir)) { $commonDir = Join-Path $Root $commonDir }
        return Join-Path $commonDir "meadow-diagnostics.jsonl"
    }
    catch { return $null }
}

function Write-Diagnostic {
    # Kind is the event vocabulary; Fields are the event's own values. `ts` and
    # `kind` are always present, everything else only when the caller has it.
    # Kinds in use: slice_claimed, slice_finished, slice_stop, verify_stage,
    # session_start, session_end.
    param(
        [Parameter(Mandatory = $true)][string]$Kind,
        [hashtable]$Fields = @{},
        [string]$Root
    )

    try {
        $path = Get-DiagnosticsPath -Root $Root
        if (-not $path) { return }

        # Rotation keeps one generation. A full file is ~200 bytes a line, so
        # 1 MB is several thousand events -- months of work at the current rate.
        try {
            $info = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
            if ($info -and $info.Length -gt $script:DiagnosticsMaxBytes) {
                Move-Item -LiteralPath $path -Destination "$path.1" -Force -ErrorAction SilentlyContinue
            }
        }
        catch { }

        $event = [ordered]@{
            ts   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            kind = $Kind
        }
        foreach ($key in ($Fields.Keys | Sort-Object)) {
            $value = $Fields[$key]
            if ($null -eq $value) { continue }
            if ($value -is [string] -and $value.Length -eq 0) { continue }
            if ($value -is [string] -and $value.Length -gt 300) { $value = $value.Substring(0, 300) }
            $event[$key] = $value
        }
        $line = ($event | ConvertTo-Json -Compress -Depth 4) + "`n"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($line)

        # An exclusive append, retried: the two lanes can both be closing out,
        # and a half-interleaved line would be unparseable. Events are rare
        # enough that five attempts never costs measurable time.
        for ($attempt = 0; $attempt -lt 5; $attempt++) {
            try {
                $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
                try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
                return
            }
            catch [System.IO.IOException] {
                Start-Sleep -Milliseconds 20
            }
        }
    }
    catch { }
}
