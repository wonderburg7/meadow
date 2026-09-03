[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("start", "finish")]
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
        $nextAfterMatch = [regex]::Match(
            $chunk,
            '(?m)^\s*-\s*Next after:\s*(.*?)(?=^\s*-\s[A-Z]|\z)',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

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
            NextAfter = if ($nextAfterMatch.Success) { ($nextAfterMatch.Groups[1].Value -replace '\s+', ' ').Trim() } else { "" }
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

function Invoke-SliceFinish {
    $worktreeRoot = (Get-Location).Path
    $root = Get-PrimaryRoot

    if ((Resolve-Path -LiteralPath $worktreeRoot).Path -eq (Resolve-Path -LiteralPath $root).Path) {
        Write-Error "run 'slice.ps1 finish' from inside a slice worktree, not the primary checkout"
        exit 1
    }

    $branch = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($LASTEXITCODE -ne 0) {
        Write-Error "not inside a git branch"
        exit 1
    }
    $branchMatch = [regex]::Match($branch, '^(?<prefix>claude|codex)/(?<id>.+)$')
    if (-not $branchMatch.Success) {
        Write-Error "not on a slice branch (claude/<id> or codex/<id>): current branch is $branch"
        exit 1
    }
    $id = $branchMatch.Groups["id"].Value
    $lane = if ($branchMatch.Groups["prefix"].Value -eq "claude") { "Claude" } else { "Codex" }
    $worktreeRelative = ".worktrees/$id"

    $verifyScript = Join-Path $worktreeRoot "tools\verify.ps1"
    $verifyCmd = Get-Command $verifyScript
    $verifyArgs = @()
    if ($verifyCmd.Parameters.ContainsKey("Quiet")) {
        $verifyArgs += "-Quiet"
    }
    try {
        $verifyOutput = & $verifyScript @verifyArgs 2>&1
        $verifyExit = $LASTEXITCODE
    }
    catch {
        $verifyOutput = $_ | Out-String
        $verifyExit = 1
    }
    $verifyOutput | ForEach-Object { Write-Output $_ }
    if ($verifyExit -ne 0) {
        Write-Error "$id -- tools/verify.ps1 failed; branch left untouched"
        exit 1
    }

    $items = Get-NextUpItems -Root $worktreeRoot
    $item = $items | Where-Object { $_.Id -eq $id } | Select-Object -First 1
    $handsOnNote = "none needed"
    if ($item -and $item.Check -match '(?i)hands-on check') {
        $readyPath = Join-Path $worktreeRoot "checks\ready.md"
        $currentReady = if (Test-Path -LiteralPath $readyPath) { Get-Content -Raw -LiteralPath $readyPath } else { "" }
        $masterReady = git -C $root show "master:checks/ready.md"
        if ($LASTEXITCODE -ne 0) { throw "could not read checks/ready.md from master" }
        $currentEntries = [regex]::Matches($currentReady, '(?m)^### (C-\d+)') | ForEach-Object { $_.Groups[1].Value }
        $masterEntries = [regex]::Matches($masterReady, '(?m)^### (C-\d+)') | ForEach-Object { $_.Groups[1].Value }
        $newEntries = $currentEntries | Where-Object { $masterEntries -notcontains $_ }
        if (-not $newEntries) {
            Write-Error "$id -- Check: names a hands-on check but checks/ready.md gained no entry -- file it before finishing"
            exit 1
        }
        $handsOnNote = "checks/ready.md gained $($newEntries -join ', ')"
    }
    elseif (-not $item) {
        Write-Output "$id -- no NEXTSTEPS.md entry found; skipping the hands-on-check gate"
    }

    git add -A
    if ($LASTEXITCODE -ne 0) { throw "git add failed" }
    $staged = git diff --cached --name-only
    if ($staged) {
        $commitMessage = "$id -- finish outstanding work`n`nCo-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
        git commit -m $commitMessage | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
    }

    Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    Push-Location $root
    try {
        $primaryBranch = (git rev-parse --abbrev-ref HEAD).Trim()
        if ($primaryBranch -ne "master") {
            throw "primary checkout is on '$primaryBranch', not master -- switch it to master before finishing a slice"
        }

        $title = if ($item) { $item.Title } else { $branch }
        $mergeMessage = "Merge ${branch}: $title`n`nCo-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
        git merge --no-ff $branch -m $mergeMessage
        if ($LASTEXITCODE -ne 0) { throw "git merge failed" }

        git push
        if ($LASTEXITCODE -ne 0) { throw "git push failed" }

        $maxAttempts = 30
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            git worktree remove $worktreeRelative
            if ($LASTEXITCODE -eq 0) { break }
            if ($attempt -eq $maxAttempts) { throw "git worktree remove failed" }
            if ($attempt % 5 -eq 0) {
                Write-Output "$id -- still waiting for something to release $worktreeRelative (attempt $attempt of $maxAttempts)"
            }
            Start-Sleep -Seconds 3
        }

        git branch -d $branch
        if ($LASTEXITCODE -ne 0) { throw "git branch -d failed" }

        git ls-remote --exit-code --heads origin $branch | Out-Null
        if ($LASTEXITCODE -eq 0) {
            git push origin --delete $branch
            if ($LASTEXITCODE -ne 0) { throw "git push origin --delete failed" }
        }

        $ledgerPath = Join-Path $root "plans\workstreams.md"
        $lines = Get-Content -LiteralPath $ledgerPath
        $keep = $lines | Where-Object { $_ -notlike "*``$worktreeRelative``*" }
        Set-Content -LiteralPath $ledgerPath -Value $keep

        git add "plans/workstreams.md"
        if ($LASTEXITCODE -ne 0) { throw "git add failed" }
        $deleteMessage = "Remove the $id worktree row from the ledger`n`nCo-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
        git commit -m $deleteMessage | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git commit failed" }

        git push
        if ($LASTEXITCODE -ne 0) { throw "git push failed" }
    }
    finally {
        Pop-Location
    }

    $queueLine = "queue not refilled by 'finish' -- check NEXTSTEPS.md by hand"
    if ($item -and $item.NextAfter) {
        $queueLine = "$lane lane now leads with $($item.NextAfter)"
    }

    Write-Output ""
    Write-Output "Slice landed: $id -- $title"
    Write-Output "Branch:       $branch  |  verify.ps1: green"
    Write-Output "Merged:       yes, to master now"
    Write-Output "Hands-on:     $handsOnNote"
    Write-Output "Queue:        $queueLine"
    Write-Output "Next slice:   see 'Next after:' on the item above, or the owning plan in plans/now/"
    Write-Output "Other lane:   check NEXTSTEPS.md -- untouched by this merge"
    Write-Output "Start it with: tools/slice.ps1 start -Lane <lane with a free head>"
}

switch ($Command) {
    "start"  { Invoke-SliceStart -Lane $Lane }
    "finish" { Invoke-SliceFinish }
}
