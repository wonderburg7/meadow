[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("start", "finish", "doctor")]
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
    $itemNumber = 0
    foreach ($chunk in $chunks) {
        $itemNumber++
        $trimmed = $chunk.Trim()
        $headMatch = [regex]::Match(
            $trimmed,
            '^\*\*\[(?<lane>\w+)\]\s+(?<id>[\w.-]+)\s+--\s+(?<title>.*?)\*\*',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
        if (-not $headMatch.Success) {
            continue
        }

        # Same multi-line capture as Files/Check below. A `Plan:` line that
        # wraps -- which it does whenever it names more than one section --
        # used to capture only its first physical line, so the heading handed
        # to the implementer read "section 11, Phase A step 3, with" and the
        # sections after the break were silently dropped.
        $planMatch = [regex]::Match(
            $chunk,
            '(?m)^\s*-\s*Plan:\s*(.*?)(?=^\s*-\s[A-Z]|\z)',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
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
        $proofLabelMatch = [regex]::Match($chunk, '(?m)^\s*-\s*Proof:\s*(.*?)\s*$')
        $proofMatch = [regex]::Match($chunk, '(?m)^\s*-\s*Proof:\s*`([^`]*)`\s*$')
        $nextAfterMatch = [regex]::Match(
            $chunk,
            '(?m)^\s*-\s*Next after:\s*(.*?)(?=^\s*-\s[A-Z]|\z)',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )

        $planLine = if ($planMatch.Success) { ($planMatch.Groups[1].Value -replace '\s+', ' ').Trim() } else { "" }
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
                Where-Object { $_.Trim() -ne "" }
        }

        $items += [PSCustomObject]@{
            ItemNumber = $itemNumber
            Lane    = $headMatch.Groups["lane"].Value
            Id      = $headMatch.Groups["id"].Value
            Title   = ($headMatch.Groups["title"].Value -replace '\s+', ' ').Trim()
            Plan    = $planFile
            Heading = $heading
            Files   = $files
            FilesRaw = if ($filesMatch.Success) { $filesMatch.Groups[1].Value.Trim() } else { "" }
            Check   = if ($checkMatch.Success) { ($checkMatch.Groups[1].Value -replace '\s+', ' ').Trim() } else { "" }
            Proof   = if ($proofMatch.Success) { $proofMatch.Groups[1].Value.Trim() } else { "" }
            HasProofLabel = $proofLabelMatch.Success
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

function Get-LaneTrailer {
    # `slice.ps1` runs in both lanes, so the co-author trailer follows the
    # lane rather than being hard-coded -- a Codex slice credited to Claude
    # makes `git log` useless for telling the two apart.
    param([string]$Lane)
    if ($Lane -eq "Codex") {
        return "Co-Authored-By: ChatGPT Codex <noreply@openai.com>"
    }
    return "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
}

function Test-RepositoryRelativePath {
    param([string]$Path)

    if (-not $Path -or [System.IO.Path]::IsPathRooted($Path)) {
        return $false
    }
    if ($Path.Contains('://') -or -not [System.IO.Path]::GetExtension($Path)) {
        return $false
    }
    return -not (($Path -split '[\\/]') -contains '..')
}

function Assert-CandidateDefinition {
    param(
        [string]$Root,
        [object]$Candidate
    )

    $itemNumber = $Candidate.ItemNumber
    if (-not $Candidate.Plan -or -not $Candidate.Heading) {
        throw "NEXTSTEPS.md item ${itemNumber}: Plan: must be ``<path>`` -- <heading>"
    }

    $filesResidue = [regex]::Replace($Candidate.FilesRaw, '`[^`]+`', '') -replace '[\s,]', ''
    $invalidFiles = @($Candidate.Files | Where-Object { -not (Test-RepositoryRelativePath -Path $_) })
    if (-not $Candidate.Files -or $filesResidue -or $invalidFiles) {
        throw "NEXTSTEPS.md item ${itemNumber}: Files: must contain only backticked repository-relative paths separated by commas; placeholder prose is not allowed"
    }

    if (-not $Candidate.Proof) {
        $detail = if ($Candidate.HasProofLabel) { "must be backticked" } else { "missing" }
        throw "NEXTSTEPS.md item ${itemNumber}: Proof: $detail; use ``present|absent: <path> :: <substring>``"
    }

    $parts = $Candidate.Proof.Split(":", 2)
    $mode = if ($parts.Count -gt 0) { $parts[0].Trim() } else { "" }
    if ($parts.Count -ne 2 -or $mode -notin @("present", "absent")) {
        throw "NEXTSTEPS.md item ${itemNumber}: Proof: must start with 'present:' or 'absent:', got ``$($Candidate.Proof)``"
    }

    $pathAndNeedle = $parts[1].Trim() -split '::', 2
    $relPath = if ($pathAndNeedle.Count -gt 0) { $pathAndNeedle[0].Trim() } else { "" }
    $needle = if ($pathAndNeedle.Count -gt 1) { $pathAndNeedle[1].Trim() } else { "" }
    if ($pathAndNeedle.Count -ne 2 -or -not $relPath -or -not $needle -or
        -not (Test-RepositoryRelativePath -Path $relPath)) {
        throw "NEXTSTEPS.md item ${itemNumber}: Proof: must be ``${mode}: <path> :: <substring>``, got ``$($Candidate.Proof)``"
    }

    $target = Join-Path $Root $relPath
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        throw "NEXTSTEPS.md item ${itemNumber}: Proof: names a file that does not exist: $relPath"
    }
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

function Get-SlicePreflight {
    param([string]$Lane)

    if (-not $Lane) {
        throw "the command requires -Lane Claude|Codex"
    }

    $root = Get-PrimaryRoot
    $items = Get-NextUpItems -Root $root
    $candidate = $items | Where-Object { $_.Lane -eq $Lane } | Select-Object -First 1
    if (-not $candidate) {
        throw "no unclaimed [$Lane] item in NEXTSTEPS.md"
    }

    Assert-CandidateDefinition -Root $root -Candidate $candidate
    if (-not (Test-Proof -Root $root -ProofLine $candidate.Proof)) {
        throw "NEXTSTEPS.md item $($candidate.ItemNumber): proof no longer holds -- this may already be built. Open $($candidate.Proof.Split(':', 2)[1].Split('::', 2)[0].Trim()) before requeuing it."
    }

    $ledgerRows = Get-LedgerLaneRows -Root $root
    $existingLaneRow = $ledgerRows | Where-Object { $_.Lane -eq $Lane }
    if ($existingLaneRow) {
        throw "$Lane lane already has an open worktree ($($existingLaneRow.Worktree)) -- finish or abandon it first"
    }

    $id = $candidate.Id
    $prefix = $Lane.ToLower()
    $branch = "$prefix/$id"
    $worktreeRelative = ".worktrees/$id"
    $worktreePath = Join-Path $root $worktreeRelative

    $branchExists = (git -C $root branch --list $branch)
    if ($branchExists) {
        throw "$id -- branch $branch already exists"
    }
    if (Test-Path -LiteralPath $worktreePath) {
        throw "$id -- worktree $worktreeRelative already exists"
    }

    return [PSCustomObject]@{
        Root = $root
        Candidate = $candidate
        Id = $id
        Branch = $branch
        WorktreeRelative = $worktreeRelative
        WorktreePath = $worktreePath
    }
}

function Invoke-SliceDoctor {
    param([string]$Lane)

    try {
        $preflight = Get-SlicePreflight -Lane $Lane
    }
    catch {
        Write-Error $_.Exception.Message
        exit 1
    }

    [ordered]@{
        status   = "ready"
        id       = $preflight.Id
        lane     = $Lane
        plan     = $preflight.Candidate.Plan
        heading  = $preflight.Candidate.Heading
        files    = $preflight.Candidate.Files
        check    = $preflight.Candidate.Check
        proof    = $preflight.Candidate.Proof
        branch   = $preflight.Branch
        worktree = $preflight.WorktreeRelative
    } | ConvertTo-Json -Compress
}

function Invoke-SliceStart {
    param([string]$Lane)

    try {
        $preflight = Get-SlicePreflight -Lane $Lane
    }
    catch {
        Write-Error $_.Exception.Message
        exit 1
    }

    $root = $preflight.Root
    $candidate = $preflight.Candidate
    $id = $preflight.Id
    $branch = $preflight.Branch
    $worktreeRelative = $preflight.WorktreeRelative

    $ledgerPath = Join-Path $root "plans\workstreams.md"
    $row = "| ``$worktreeRelative`` (``$branch``) | $Lane | $($candidate.Title) | $Lane | in progress | none | ``$($candidate.Plan)`` $($candidate.Heading) |"
    $ledgerContent = [System.IO.File]::ReadAllText($ledgerPath)
    if ($ledgerContent.Length -gt 0 -and -not ($ledgerContent.EndsWith("`n"))) {
        [System.IO.File]::AppendAllText($ledgerPath, "`r`n")
    }
    Add-Content -LiteralPath $ledgerPath -Value $row

    Push-Location $root
    try {
        git add "plans/workstreams.md"
        if ($LASTEXITCODE -ne 0) { throw "git add failed" }
        $commitMessage = "Register the $id worktree in the ledger`n`n$(Get-LaneTrailer -Lane $Lane)"
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
    $trailer = Get-LaneTrailer -Lane $lane
    $worktreeRelative = ".worktrees/$id"

    $verifyScript = Join-Path $worktreeRoot "tools\verify.ps1"
    $verifyCmd = Get-Command $verifyScript
    # A hashtable splat, not an array: array splatting passes its elements as
    # positional arguments, so "-Quiet" bound to verify.ps1's $PythonPath and
    # every closeout died on "the supplied Python interpreter does not exist".
    $verifyArgs = @{}
    if ($verifyCmd.Parameters.ContainsKey("Quiet")) {
        $verifyArgs["Quiet"] = $true
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
        $commitMessage = "$id -- finish outstanding work`n`n$trailer"
        git commit -m $commitMessage | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
    }

    Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    # `finish` deletes the worktree it is run from, so it must not depend
    # on returning to it. Push-Location left that path on the location
    # stack and the matching Pop-Location threw once the directory was
    # gone -- and, sitting in a `finally`, replaced whatever real error was
    # propagating, so a failed ledger commit surfaced as a path error.
    Set-Location -LiteralPath $root
    $primaryBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($primaryBranch -ne "master") {
        throw "primary checkout is on '$primaryBranch', not master -- switch it to master before finishing a slice"
    }

    $title = if ($item) { $item.Title } else { $branch }
    $mergeMessage = "Merge ${branch}: $title`n`n$trailer"
    # -F <file> rather than -m <string>: a Title containing a double quote
    # (FL-2's own did -- 'means "barely", not "not at all"') survives
    # PowerShell's native-argument re-quoting fine as string content, but
    # broke when handed to git as a command-line argument, failing the
    # merge with a mangled ref-like error ("not something we can merge").
    # A file sidesteps command-line quoting entirely.
    $mergeMessageFile = New-TemporaryFile
    try {
        # Set-Content's UTF8 always writes a BOM in Windows PowerShell 5.1
        # (no utf8NoBOM encoding exists here), which git would fold into
        # the commit message as a leading invisible character -- write
        # the file directly instead.
        [System.IO.File]::WriteAllText($mergeMessageFile, $mergeMessage, (New-Object System.Text.UTF8Encoding $false))
        git merge --no-ff $branch -F $mergeMessageFile
        if ($LASTEXITCODE -ne 0) { throw "git merge failed" }
    }
    finally {
        Remove-Item -LiteralPath $mergeMessageFile -ErrorAction SilentlyContinue
    }

    git push
    if ($LASTEXITCODE -ne 0) { throw "git push failed" }

    $worktreePath = Join-Path $root $worktreeRelative
    git worktree remove $worktreeRelative
    if ($LASTEXITCODE -ne 0) {
        # `git worktree remove` can deregister the worktree and still fail to
        # delete the directory (an external process briefly holding it open --
        # OneDrive and the Search Indexer both do this on a freshly emptied
        # folder, same as a running Godot instance can). Once git has let go
        # of it, re-running `git worktree remove` just fails with "is not a
        # working tree" -- retry the plain delete instead.
        $maxAttempts = 60
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            if (-not (Test-Path -LiteralPath $worktreePath)) { break }
            try {
                Remove-Item -LiteralPath $worktreePath -Recurse -Force -ErrorAction Stop
                break
            }
            catch {
                if ($attempt -eq $maxAttempts) { throw "could not remove $worktreeRelative -- $($_.Exception.Message)" }
                if ($attempt % 5 -eq 0) {
                    Write-Output "$id -- still waiting for something to release $worktreeRelative (attempt $attempt of $maxAttempts)"
                }
                Start-Sleep -Seconds 3
            }
        }
        git worktree prune
    }

    git branch -d $branch
    if ($LASTEXITCODE -ne 0) { throw "git branch -d failed" }

    git ls-remote --exit-code --heads origin $branch | Out-Null
    if ($LASTEXITCODE -eq 0) {
        git push origin --delete $branch
        if ($LASTEXITCODE -ne 0) { throw "git push origin --delete failed" }
    }

    $ledgerPath = Join-Path $root "plans\workstreams.md"
    # A ledger row wraps the worktree path in backticks, and a backtick is the
    # escape character in a PowerShell wildcard: "*`<path>`*" asks -like for a
    # *literal* asterisk, so no row ever matched, the file was rewritten
    # unchanged, and the commit below then died on "nothing to commit". Match
    # the row as an ordinal substring instead of a wildcard.
    $rowMarker = '`' + $worktreeRelative + '`'
    $lines = @(Get-Content -LiteralPath $ledgerPath)
    $keep = @($lines | Where-Object { $_.IndexOf($rowMarker, [System.StringComparison]::Ordinal) -lt 0 })
    if ($keep.Count -eq $lines.Count) {
        Write-Output "$id -- no ledger row names $worktreeRelative; leaving plans/workstreams.md alone"
    }
    else {
        Set-Content -LiteralPath $ledgerPath -Value $keep
    }

    git add "plans/workstreams.md"
    if ($LASTEXITCODE -ne 0) { throw "git add failed" }
    # An empty commit exits 1, so a ledger that is already clean -- a re-run
    # after a partial closeout -- must not fail the run. Ask what is staged.
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        $deleteMessage = "Remove the $id worktree row from the ledger`n`n$trailer"
        git commit -m $deleteMessage | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git commit failed" }

        git push
        if ($LASTEXITCODE -ne 0) { throw "git push failed" }
    }
    else {
        Write-Output "$id -- ledger already clean; nothing to commit"
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
    "doctor" { Invoke-SliceDoctor -Lane $Lane }
}
