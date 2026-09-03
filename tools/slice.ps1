[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("start")]
    [string]$Command,

    [ValidateSet("Claude", "Codex")]
    [string]$Lane
)

$ErrorActionPreference = "Stop"

function Get-PrimaryRoot {
    $commonDir = (git rev-parse --git-common-dir).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "not inside a git repository"
    }
    if (-not [System.IO.Path]::IsPathRooted($commonDir)) {
        $commonDir = Join-Path (Get-Location) $commonDir
    }
    $commonDir = (Resolve-Path -LiteralPath $commonDir).Path
    return (Split-Path -Parent $commonDir)
}

function Get-NextUpItems {
    param([string]$Root)

    $text = Get-Content -Raw -LiteralPath (Join-Path $Root "NEXTSTEPS.md")
    $sectionMatch = [regex]::Match(
        $text,
        '^## Next up\s*$(.*?)(?=^## |\z)',
        [System.Text.RegularExpressions.RegexOptions]::Multiline -bor
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if (-not $sectionMatch.Success) {
        throw "NEXTSTEPS.md: missing a '## Next up' section"
    }
    $section = $sectionMatch.Groups[1].Value

    $chunks = [regex]::Split($section, '(?m)^\d+\.\s+') | Where-Object { $_.Trim() -ne "" }

    $items = @()
    foreach ($chunk in $chunks) {
        $trimmed = $chunk.Trim()
        $headMatch = [regex]::Match(
            $trimmed,
            '^\*\*\[(?<lane>\w+)\]\s+(?<id>[\w.-]+)\s+--\s+(?<title>.*?)\*\*',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
        if (-not $headMatch.Success) {
            continue
        }

        $planMatch = [regex]::Match($chunk, '(?m)^\s*-\s*Plan:\s*(.+)$')
        $filesMatch = [regex]::Match(
            $chunk,
            '(?m)^\s*-\s*Files:\s*(.*?)(?=^\s*-\s[A-Z]|\z)',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
        $checkMatch = [regex]::Match(
            $chunk,
            '(?m)^\s*-\s*Check:\s*(.*?)(?=^\s*-\s[A-Z]|\z)',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
        $proofMatch = [regex]::Match($chunk, '(?m)^\s*-\s*Proof:\s*`([^`]*)`')

        $planLine = if ($planMatch.Success) { $planMatch.Groups[1].Value.Trim() } else { "" }
        $planFile = ""
        $heading = ""
        $planSplit = [regex]::Match($planLine, '^`([^`]+)`\s*--\s*(.+?)\.?$')
        if ($planSplit.Success) {
            $planFile = $planSplit.Groups[1].Value
            $heading = $planSplit.Groups[2].Value.Trim()
        }

        $files = @()
        if ($filesMatch.Success) {
            $files = [regex]::Matches($filesMatch.Groups[1].Value, '`([^`]+)`') |
                ForEach-Object { $_.Groups[1].Value } |
                Where-Object { $_ -match "/" }
        }

        $items += [PSCustomObject]@{
            Lane    = $headMatch.Groups["lane"].Value
            Id      = $headMatch.Groups["id"].Value
            Title   = ($headMatch.Groups["title"].Value -replace '\s+', ' ').Trim()
            Plan    = $planFile
            Heading = $heading
            Files   = $files
            Check   = if ($checkMatch.Success) { ($checkMatch.Groups[1].Value -replace '\s+', ' ').Trim() } else { "" }
            Proof   = if ($proofMatch.Success) { $proofMatch.Groups[1].Value.Trim() } else { "" }
        }
    }
    return $items
}

function Get-LedgerLaneRows {
    param([string]$Root)

    $ledgerPath = Join-Path $Root "plans\workstreams.md"
    $lines = Get-Content -LiteralPath $ledgerPath
    $rows = @()
    foreach ($line in $lines) {
        if (-not $line.StartsWith("|")) { continue }
        $cells = $line.Split("|")
        if ($cells.Count -lt 3) { continue }
        $first = $cells[1].Trim()
        if ($first -eq "" -or $first -eq "Worktree path (branch)" -or $first -match '^-+$') { continue }
        $rows += [PSCustomObject]@{
            Worktree = $first
            Lane     = $cells[2].Trim()
        }
    }
    return $rows
}

function Test-Proof {
    param([string]$Root, [string]$ProofLine)

    $parts = $ProofLine.Split(":", 2)
    if ($parts.Count -ne 2) {
        throw "Proof: line is malformed: $ProofLine"
    }
    $mode = $parts[0].Trim()
    $rest = $parts[1].Trim()
    $pathAndNeedle = $rest -split '::', 2
    if ($pathAndNeedle.Count -ne 2) {
        throw "Proof: line is malformed: $ProofLine"
    }
    $relPath = $pathAndNeedle[0].Trim()
    $needle = $pathAndNeedle[1].Trim()

    $target = Join-Path $Root $relPath
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        return $false
    }
    $content = Get-Content -Raw -LiteralPath $target
    $found = $content.Contains($needle)
    if ($mode -eq "present") {
        return $found
    }
    elseif ($mode -eq "absent") {
        return -not $found
    }
    else {
        throw "Proof: mode must be 'present' or 'absent', got '$mode'"
    }
}

function Invoke-SliceStart {
    param([string]$Lane)

    if (-not $Lane) {
        Write-Error "start requires -Lane Claude|Codex"
        exit 1
    }

    $root = Get-PrimaryRoot

    $ledgerRows = Get-LedgerLaneRows -Root $root
    $existingLaneRow = $ledgerRows | Where-Object { $_.Lane -eq $Lane }
    if ($existingLaneRow) {
        Write-Error "$Lane lane already has an open worktree ($($existingLaneRow.Worktree)) -- finish or abandon it first"
        exit 1
    }

    $items = Get-NextUpItems -Root $root
    $candidate = $items | Where-Object { $_.Lane -eq $Lane } | Select-Object -First 1
    if (-not $candidate) {
        Write-Error "no unclaimed [$Lane] item in NEXTSTEPS.md"
        exit 1
    }

    $id = $candidate.Id
    $prefix = $Lane.ToLower()
    $branch = "$prefix/$id"
    $worktreeRelative = ".worktrees/$id"
    $worktreePath = Join-Path $root $worktreeRelative

    $branchExists = (git -C $root branch --list $branch)
    if ($branchExists) {
        Write-Error "$id -- branch $branch already exists"
        exit 1
    }
    if (Test-Path -LiteralPath $worktreePath) {
        Write-Error "$id -- worktree $worktreeRelative already exists"
        exit 1
    }

    if (-not (Test-Proof -Root $root -ProofLine $candidate.Proof)) {
        Write-Error "$id -- proof no longer holds -- open $($candidate.Plan); do not start this slice"
        exit 1
    }

    $ledgerPath = Join-Path $root "plans\workstreams.md"
    $row = "| ``$worktreeRelative`` (``$branch``) | $Lane | $($candidate.Title) | $Lane | in progress | none | ``$($candidate.Plan)`` $($candidate.Heading) |"
    Add-Content -LiteralPath $ledgerPath -Value $row

    Push-Location $root
    try {
        git add "plans/workstreams.md"
        if ($LASTEXITCODE -ne 0) { throw "git add failed" }
        $commitMessage = "Register the $id worktree in the ledger`n`nCo-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
        git commit -m $commitMessage | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git commit failed" }

        git worktree add $worktreeRelative -b $branch | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git worktree add failed" }
    }
    finally {
        Pop-Location
    }

    $result = [ordered]@{
        id       = $id
        plan     = $candidate.Plan
        heading  = $candidate.Heading
        files    = $candidate.Files
        check    = $candidate.Check
        proof    = $candidate.Proof
        branch   = $branch
        worktree = $worktreeRelative
    }
    $result | ConvertTo-Json -Compress
}

switch ($Command) {
    "start" { Invoke-SliceStart -Lane $Lane }
}
