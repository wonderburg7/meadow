[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("start", "finish", "doctor", "status", "resume", "abort", "owner")]
    [string]$Command,

    [ValidateSet("Claude", "Codex")]
    [string]$Lane,

    [string]$PythonPath,

    # `owner` only: the repository-relative paths an ad-hoc session means to edit.
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Path
)

$ErrorActionPreference = "Stop"

# Git's stdout is UTF-8. Without this, capturing it through a pipeline (e.g.
# `git show ... | Out-String`) decodes via the console's OEM/ANSI codepage on
# Windows PowerShell 5.1, silently corrupting non-ASCII bytes (an em dash
# became three garbage codepoints) before any string comparison runs.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# The diagnostic log (tools/diagnostics.ps1) is a measurement only: it never
# gates a command, and Write-Diagnostic swallows its own errors.
. (Join-Path $PSScriptRoot "diagnostics.ps1")
$script:SliceStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Index -- grep a name rather than reading this file (1,400 lines):
#   grep -n "^function <Name>" tools/slice.ps1, then read only that function.
#   --- failure reporting ---   Stop-Slice, Set-SliceStep, Write-SliceFailure, Add-SliceStopRecord
#   --- lock and journal ---    Invoke-WithLifecycleLock, *-ClosingJournal, pending deletions
#   --- queue parsing ---       Get-NextUpItems(FromText), Assert-CandidateDefinition, Test-Proof
#   --- briefing ---            Get-SliceReadCommand, Get-SliceAdvice, Get-SlicePreflight
#   --- environment ---         Get-GodotCapability, Get-DoctorEnvironmentFailures
#   --- commands ---            Invoke-SliceDoctor/Start/Status/Resume/Abort/Finish, Invoke-SliceArchiveAndRefill
#   --- post-merge ---          Invoke-SlicePostMergeCleanup
# A failing command prints one "slice <command> stopped" block naming the
# step, cause, fix and how to retry. That block is the diagnosis.

# --- failure reporting ---

$script:SliceContext = [ordered]@{ Command = $Command; Id = ""; Lane = $Lane; Step = "" }

function Set-SliceStep {
    param([string]$Step)
    $script:SliceContext.Step = $Step
}

function Stop-Slice {
    # A known stop with its remedy. It throws, so the top-level handler prints
    # it in the standard block instead of PowerShell's script-position dump,
    # which pointed sessions into this file to work out what went wrong.
    param([string]$Cause, [string]$Fix)
    $exception = New-Object System.Exception $Cause
    $exception.Data["Fix"] = $Fix
    throw $exception
}

function Add-SliceStopRecord {
    # One line per stop, appended to a ledger beside the other lifecycle state
    # in the git common directory, so `tools/session_cost.py --stops` can say
    # which phase actually costs the retries. Before this, that was guesswork:
    # a session sees its own stop and no others, and the 39 lifecycle_failure
    # outcomes a week carried no phase with them.
    #
    # Never throws. It runs from the top-level catch handler, where an error
    # of its own would replace the real failure -- the same way Pop-Location
    # once masked a failed ledger commit (see Invoke-SliceFinish).
    param([string]$Cause)
    try {
        # No 2>$null: redirecting a native command's stderr under
        # $ErrorActionPreference = "Stop" turns git's own message into a
        # terminating error, which is exactly what this must not raise.
        $commonDir = git rev-parse --git-common-dir
        if ($LASTEXITCODE -ne 0 -or -not $commonDir) { return }
        $commonDir = ([string]$commonDir).Trim()
        if (-not [System.IO.Path]::IsPathRooted($commonDir)) {
            $commonDir = Join-Path (Get-Location).Path $commonDir
        }
        $context = $script:SliceContext
        $record = [ordered]@{
            at      = (Get-Date).ToString("s")
            command = $context.Command
            id      = $context.Id
            lane    = $context.Lane
            step    = $context.Step
            cause   = $Cause
        }
        # Windows PowerShell 5.1's Add-Content default is the active ANSI
        # code page.  The shared JSONL ledger needs a stable encoding because
        # session_cost.py reads it after the originating console is gone.
        $line = ($record | ConvertTo-Json -Compress) + "`n"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($line)
        $path = Join-Path $commonDir "meadow-slice-stops.jsonl"
        $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
        try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
    }
    catch {
        # A measurement is never a reason to lose the diagnosis.
    }
}

function Get-DefaultSliceFix {
    param([string]$Cause)
    if ($Cause -match 'lifecycle is busy') {
        return "the command named in the cause is still running -- often your own earlier call, whose shell returned before it finished. Wait for it to end rather than retrying, then read its outcome with tools/slice.ps1 status (last_run)"
    }
    if ($Cause -match 'git (merge|pull)') {
        return "git's own message is printed above. Resolve the conflict in the primary checkout (edit, git add, git commit); a conflict between lanes means a Files: line in NEXTSTEPS.md was wrong -- fix it in the same pass"
    }
    if ($Cause -match 'git push') {
        return "git's own message is printed above. If the remote is ahead, run git pull --no-rebase in the primary checkout, then retry; if it is an auth or network error, retry once it is fixed"
    }
    if ($Cause -match '^git |git \w+ failed') {
        return "git's own message is printed above; run git status where the step ran, fix what it names, then retry"
    }
    if ($Cause -match 'injected lifecycle failure') {
        return "a test injected this stop (MEADOW_SLICE_FAIL_AFTER); unset it and retry"
    }
    return "act on the cause above; if it names no file, run tools/slice.ps1 status -Lane <lane> to see the lifecycle state"
}

function Get-SliceRetryLine {
    $context = $script:SliceContext
    $laneArg = if ($context.Lane) { $context.Lane } else { "<lane>" }
    switch ($context.Command) {
        "finish" { return "rerun tools/slice.ps1 finish from the slice worktree (phases already done are skipped); once merged, use tools/slice.ps1 resume -Lane $laneArg from the primary checkout" }
        "start"  { return "rerun tools/slice.ps1 start -Lane $laneArg" }
        "resume" { return "rerun tools/slice.ps1 resume -Lane $laneArg" }
        default  { return "rerun tools/slice.ps1 $($context.Command) -Lane $laneArg" }
    }
}

function Write-SliceFailure {
    param([System.Management.Automation.ErrorRecord]$Record)
    $context = $script:SliceContext
    $cause = $Record.Exception.Message
    $fix = $Record.Exception.Data["Fix"]
    if (-not $fix) { $fix = Get-DefaultSliceFix -Cause $cause }
    $lines = @("", "slice $($context.Command) stopped -- nothing after this step ran")
    if ($context.Id) { $lines += "  Slice:  $($context.Id) ($($context.Lane) lane)" }
    if ($context.Step) { $lines += "  Step:   $($context.Step)" }
    $lines += "  Cause:  $cause"
    $lines += "  Fix:    $fix"
    $lines += "  Retry:  $(Get-SliceRetryLine)"
    $lines += "  This block is the whole diagnosis -- there is no need to read tools/slice.ps1."
    foreach ($line in $lines) { [Console]::Error.WriteLine($line) }
    Add-SliceStopRecord -Cause $cause
}

# --- lock and journal ---

# Tests (and an operator diagnosing a real interruption) can stop immediately
# after a durable lifecycle phase.  Nothing reads this value during normal
# operation, and `resume` derives its work from Git and the ledger rather than
# assuming that the preceding command reached its final line.
function Invoke-InjectedLifecycleFailure {
    param([string]$Phase)
    if ($env:MEADOW_SLICE_FAIL_AFTER -eq $Phase) {
        throw "injected lifecycle failure after $Phase"
    }
}

function Get-LifecycleFilePath {
    param([string]$Root, [string]$Name)
    $commonDir = (git -C $Root rev-parse --git-common-dir).Trim()
    if (-not [System.IO.Path]::IsPathRooted($commonDir)) { $commonDir = Join-Path $Root $commonDir }
    return Join-Path $commonDir $Name
}

# A finish takes 8-11 minutes since the primary verify began running the
# lifecycle suite. On 27 Sep 2026 a Codex shell call returned while FB-3's
# finish was still verifying; the session read that as "stopped without a
# diagnosis", retried twice into its own lock, and was told only "busy". The
# lock now says who holds it, and every locked command leaves its outcome in
# meadow-slice-last-run.json for `status` to show, so a caller that lost the
# console still learns what happened.
function Get-LifecycleHolder {
    # The holder's record, or $null if the lock is free or unreadable. A
    # record whose process is gone -- or whose PID now belongs to a process
    # started after the record -- is a stale file, not a holder.
    param([string]$LockPath)
    try {
        if (-not (Test-Path -LiteralPath $LockPath)) { return $null }
        $reader = [System.IO.File]::Open($LockPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try { $text = (New-Object System.IO.StreamReader($reader)).ReadToEnd() } finally { $reader.Dispose() }
        if (-not $text.Trim()) { return $null }
        $holder = $text | ConvertFrom-Json
        $process = Get-Process -Id ([int]$holder.pid) -ErrorAction SilentlyContinue
        if (-not $process) { return $null }
        if ($process.StartTime -gt ([datetime]$holder.started).AddSeconds(5)) { return $null }
        return $holder
    }
    catch {
        return $null
    }
}

function Get-LifecycleBusyCause {
    param([string]$LockPath)
    $holder = Get-LifecycleHolder -LockPath $LockPath
    if (-not $holder) {
        return "slice lifecycle is busy; retry this command after the other lifecycle command completes"
    }
    $minutes = [int]((Get-Date) - [datetime]$holder.started).TotalMinutes
    return "slice lifecycle is busy: ``slice.ps1 $($holder.command)`` (PID $($holder.pid), run from $($holder.cwd)) has held it since $($holder.started), $minutes min ago. If that is your own earlier call, it has not stopped -- wait for it (PowerShell: Wait-Process -Id $($holder.pid)) instead of starting another"
}

function Write-LifecycleOutcome {
    # Never throws: like Add-SliceStopRecord, a record must not replace the
    # failure it describes.
    param([string]$Root, [datetime]$Started, [string]$Outcome, [string]$Cause)
    try {
        $context = $script:SliceContext
        $record = [ordered]@{
            command = $context.Command
            id      = $context.Id
            lane    = $context.Lane
            pid     = $PID
            cwd     = (Get-Location).Path
            started = $Started.ToString("s")
            ended   = (Get-Date).ToString("s")
            outcome = $Outcome
            step    = $context.Step
            cause   = $Cause
        }
        $path = Get-LifecycleFilePath -Root $Root -Name "meadow-slice-last-run.json"
        [System.IO.File]::WriteAllText($path, ($record | ConvertTo-Json -Compress), (New-Object System.Text.UTF8Encoding $false))
    }
    catch {
    }
}

function Save-VerifyLog {
    # A failed verify's output, kept where a session that lost the console
    # can still read it. Returns the path, or a note if it could not write.
    param([string]$Root, [object[]]$Output)
    try {
        $path = Get-LifecycleFilePath -Root $Root -Name "meadow-slice-verify.log"
        $text = (@($Output) | ForEach-Object { "$_" }) -join [Environment]::NewLine
        [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding $false))
        return $path
    }
    catch {
        return "(nowhere: the log could not be written)"
    }
}

function Invoke-WithLifecycleLock {
    param([string]$Root, [scriptblock]$Action)

    $lockPath = Get-LifecycleFilePath -Root $Root -Name "meadow-slice-lifecycle.lock"
    $stream = $null
    try {
        try {
            # OpenOrCreate makes a lock left behind by a killed PowerShell
            # process recoverable: the OS releases its exclusive handle, so a
            # later lifecycle command can take that same file. CreateNew
            # instead made the stale name itself a permanent manual-repair
            # problem. FileShare.Read lets a command that finds the lock busy
            # read who holds it; every writer stays excluded.
            $stream = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
        }
        catch [System.IO.IOException] {
            throw (Get-LifecycleBusyCause -LockPath $lockPath)
        }
        $started = Get-Date
        try {
            $holder = [ordered]@{ command = $script:SliceContext.Command; pid = $PID; cwd = (Get-Location).Path; started = $started.ToString("s") }
            $bytes = (New-Object System.Text.UTF8Encoding $false).GetBytes(($holder | ConvertTo-Json -Compress))
            $stream.SetLength(0)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush()
        }
        catch {
            # The holder note only improves a busy message; the lock is held.
        }
        # The finally, not the catch, records it: start's preflight leaves
        # through `exit`, which skips a catch.
        $outcome = "stopped"
        $cause = "exited early; its own message is on the console"
        try {
            & $Action
            $outcome = "done"
            $cause = ""
        }
        catch {
            $cause = $_.Exception.Message
            throw
        }
        finally {
            Write-LifecycleOutcome -Root $Root -Started $started -Outcome $outcome -Cause $cause
        }
    }
    finally {
        if ($stream) { $stream.Dispose(); Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    }
}

# The order closeout phases happen in. A phase journal only ever records one
# of these; "done through phase X" means every phase up to and including X's
# index. Post-merge phases (worktree-removed, branch-deleted, ledger-deleted,
# pushed) are shared with Invoke-SlicePostMergeCleanup, which resume already
# reaches once Test-SliceBranchMerged is true -- ground truth, not the
# journal, is what makes that leg resumable, so it is not re-litigated here.
#
# "actions-committed" (L-13) was inserted between "branch-committed" and
# "archived". A journal only ever holds a phase *name*, and every name the
# previous order used keeps its relative position, so a journal written by
# the old order still means what it meant: "branch-committed" resumes into
# the new action; "archived" or "refilled" skip it, which is safe because
# the action only produces what those gates already proved present. Never
# rename or reorder an existing phase -- that, not an insertion, is what
# would change an in-flight journal's meaning. A name this order does not
# know (a journal from a newer slice.ps1) resolves to "nothing done", which
# redoes work rather than skipping it.
$script:ClosingPhaseOrder = @("verified", "branch-committed", "actions-committed", "archived", "refilled", "merged")

function Get-ClosingJournalPath {
    param([string]$Root)
    $commonDir = (git -C $Root rev-parse --git-common-dir).Trim()
    if (-not [System.IO.Path]::IsPathRooted($commonDir)) { $commonDir = Join-Path $Root $commonDir }
    return Join-Path $commonDir "meadow-slice-closeout.json"
}

function Get-ClosingJournal {
    # Returns $null unless a journal exists AND names this exact branch --
    # a journal from a different, already-finished slice must never be read
    # as this one's progress.
    param([string]$Root, [string]$Branch)
    $path = Get-ClosingJournalPath -Root $Root
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try {
        $journal = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
    }
    catch {
        return $null
    }
    if ($journal.branch -ne $Branch) { return $null }
    return $journal
}

function Write-ClosingJournal {
    param([string]$Root, [string]$Id, [string]$Branch, [string]$Lane, [string]$Phase)
    $path = Get-ClosingJournalPath -Root $Root
    ([ordered]@{ id = $Id; branch = $Branch; lane = $Lane; phase = $Phase } | ConvertTo-Json -Compress) |
        Set-Content -LiteralPath $path -NoNewline
}

function Remove-ClosingJournal {
    param([string]$Root)
    Remove-Item -LiteralPath (Get-ClosingJournalPath -Root $Root) -Force -ErrorAction SilentlyContinue
}

function Test-ClosingPhaseDone {
    # True once $Journal already recorded $Phase or a later one, so
    # Invoke-SliceFinish can skip straight past it on resume instead of
    # redoing a durable step (or re-running verify.ps1) a second time.
    param([object]$Journal, [string]$Phase)
    if (-not $Journal) { return $false }
    $doneIndex = $script:ClosingPhaseOrder.IndexOf([string]$Journal.phase)
    $phaseIndex = $script:ClosingPhaseOrder.IndexOf($Phase)
    if ($doneIndex -lt 0 -or $phaseIndex -lt 0) { return $false }
    return $doneIndex -ge $phaseIndex
}

function Get-PendingDeletionsPath {
    param([string]$Root)
    $commonDir = (git -C $Root rev-parse --git-common-dir).Trim()
    if (-not [System.IO.Path]::IsPathRooted($commonDir)) { $commonDir = Join-Path $Root $commonDir }
    return Join-Path $commonDir "meadow-slice-pending-deletions"
}

function Add-PendingWorktreeDeletion {
    param([string]$Root, [string]$WorktreeRelative)
    $queuePath = Get-PendingDeletionsPath -Root $Root
    $existing = if (Test-Path -LiteralPath $queuePath) { @(Get-Content -LiteralPath $queuePath) } else { @() }
    if ($WorktreeRelative -notin $existing) {
        Add-Content -LiteralPath $queuePath -Value $WorktreeRelative
    }
}

function Get-PendingWorktreeDeletions {
    param([string]$Root)
    $queuePath = Get-PendingDeletionsPath -Root $Root
    if (-not (Test-Path -LiteralPath $queuePath)) { return @() }
    return @(Get-Content -LiteralPath $queuePath | Where-Object { $_ -and $_.Trim() })
}

function Remove-PendingWorktreeDirectories {
    param([string]$Root)
    $queuePath = Get-PendingDeletionsPath -Root $Root
    if (-not (Test-Path -LiteralPath $queuePath)) { return }
    $paths = Get-PendingWorktreeDeletions -Root $Root
    $remaining = @()
    foreach ($relative in $paths) {
        $fullPath = Join-Path $Root $relative
        if (Test-Path -LiteralPath $fullPath) {
            try { Remove-Item -LiteralPath $fullPath -Recurse -Force -ErrorAction Stop } catch {}
        }
        if (Test-Path -LiteralPath $fullPath) { $remaining += $relative }
    }
    if ($remaining.Count -gt 0) {
        Set-Content -LiteralPath $queuePath -Value $remaining
    }
    else {
        Remove-Item -LiteralPath $queuePath -Force -ErrorAction SilentlyContinue
    }
}

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

# --- queue parsing ---

function Get-NextUpItems {
    param([string]$Root)

    $text = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $Root "NEXTSTEPS.md")
    return Get-NextUpItemsFromText -Text $text
}

function Get-NextUpItemsFromText {
    # Split out so closeout can read the queue as committed on master --
    # separately from the branch's own worktree copy, which a slice now edits
    # in place as part of the same transaction (see Invoke-SliceFinish's
    # "archived"/"refilled" phases).
    param([string]$Text)

    $text = $Text
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

    # Each lane has its own "### <Lane> lane" subsection. Split on those
    # first and drop each part's preamble (the text before its "1."), so the
    # next lane's heading never runs on into the last item's Next after line.
    $chunks = @()
    foreach ($part in [regex]::Split($section, '(?m)^(?=### )')) {
        $chunks += @([regex]::Split($part, '(?m)^\d+\.\s+') | Select-Object -Skip 1)
    }

    $items = @()
    $itemNumber = 0
    foreach ($chunk in $chunks) {
        $itemNumber++
        $trimmed = $chunk.Trim()
        # Id used to require a single bare token ([\w.-]+), which silently
        # dropped any item whose id is a multi-word phrase (e.g. "Hive comb
        # Slice 5") from every list this function produces -- including the
        # one Assert-CrossLaneOwnership and -Lane selection use to find a
        # lane's leading item, so the wrong item could be treated as leading
        # without any error surfacing.
        $headMatch = [regex]::Match(
            $trimmed,
            '^\*\*\[(?<lane>\w+)\]\s+(?<id>.+?)\s+--\s+(?<title>.*?)\*\*',
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
            # Queue entries quote the heading; the quotes are not part of it,
            # and left in they doubled up in the printed read command.
            $heading = $planSplit.Groups[2].Value.Trim().Trim('"')
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

function Get-LifecycleProducts {
    # These files describe integration state, not either feature branch.  A
    # slice may cause them to change, but only the lifecycle writes them after
    # merge, so they must not turn two otherwise independent branches into a
    # false ownership collision.
    return @("plans/workstreams.md", "checks/ready.md")
}

function Assert-CrossLaneOwnership {
    param([string]$Root, [object]$Candidate)

    # Candidate is always its own lane's leading item (Get-SlicePreflight
    # takes -First 1), and check_docs.py only requires the two lanes'
    # *leading* items to be file-disjoint -- a later, not-yet-claimable item
    # in the other lane sharing a file is not a real collision, since it
    # can't be started until the item ahead of it ships.  Checking every
    # other-lane item here would block a claim the documented rule allows.
    $lifecycle = @(Get-LifecycleProducts)
    $candidateFiles = @($Candidate.Files | Where-Object { $_ -notin $lifecycle })
    $otherLead = Get-NextUpItems -Root $Root |
        Where-Object { $_.Lane -ne $Candidate.Lane } |
        Sort-Object ItemNumber |
        Select-Object -First 1
    if ($otherLead) {
        $otherFiles = @($otherLead.Files | Where-Object { $_ -notin $lifecycle })
        $shared = @($candidateFiles | Where-Object { $_ -in $otherFiles } | Select-Object -Unique)
        if ($shared) {
            throw "$($Candidate.Id) and [$($otherLead.Lane)] $($otherLead.Id) both own $($shared -join ', ') -- reorder the queue before claiming either slice"
        }
    }
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
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $target
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

# --- briefing ---

function Get-SliceReadCommand {
    # The one bounded read a session needs before writing code: the slice's
    # own plan section, printed by tools/heading.py and stopping at the next
    # heading. Emitting the exact command is what replaced telling each agent
    # to "read only the Plan: file and heading" in prose -- CHATGPT.md named
    # neither the reader nor its arguments, and a sampled 24 Codex tasks used
    # it zero times while reading the whole 25 KB queue instead.
    param([object]$Candidate)
    if (-not $Candidate.Plan -or -not $Candidate.Heading) { return "" }
    return "python tools/heading.py $($Candidate.Plan) `"$($Candidate.Heading)`""
}

function Get-SliceLevel {
    # The minimum reasoning level the owning plan states for this slice: a
    # "Level: <x>" line inside its section, else its row in an "Open slices
    # at a glance" table. "unstated" when neither exists.
    param([string]$Root, [object]$Candidate)
    if (-not $Candidate.Plan) { return "unstated" }
    $planPath = Join-Path $Root $Candidate.Plan
    if (-not (Test-Path -LiteralPath $planPath -PathType Leaf)) { return "unstated" }
    $text = Get-Content -Raw -Encoding UTF8 -LiteralPath $planPath
    if ($Candidate.Heading) {
        $start = [regex]::Match($text, '(?im)^(?<hashes>#{1,6})\s+.*' + [regex]::Escape($Candidate.Heading) + '.*$')
        if ($start.Success) {
            $depth = $start.Groups['hashes'].Value.Length
            $rest = $text.Substring($start.Index + $start.Length)
            $end = [regex]::Match($rest, "(?m)^#{1,$depth}\s")
            $section = if ($end.Success) { $rest.Substring(0, $end.Index) } else { $rest }
            $levelMatch = [regex]::Match($section, '(?i)Level:(?:\*\*)?\s*(low|medium|high)\b')
            if ($levelMatch.Success) { return $levelMatch.Groups[1].Value.ToLower() }
        }
    }
    $row = [regex]::Match($text, '(?im)^\|\s*' + [regex]::Escape($Candidate.Id) + '\s*\|.*\|\s*(low|medium|high)\s*\|\s*$')
    if ($row.Success) { return $row.Groups[1].Value.ToLower() }
    return "unstated"
}

function Get-SliceAdvice {
    # Which model and which connectors a slice needs, derived from facts the
    # queue and plan already hold so every briefing and report agrees.
    # Model follows CLAUDE.md rule 4: the routine model for bounded work, the
    # strongest only where the plan says the reasoning is hard. Connectors:
    # git, headless runs and file edits need no MCP connector, and every
    # enabled connector's tool listing is re-sent on every request, so the
    # default is all off; the Godot connector is worth its cost only when a
    # slice edits scenes or on-screen UI, where a live boot shows the result.
    param([string]$Root, [object]$Candidate, [string]$Lane)
    $level = Get-SliceLevel -Root $Root -Candidate $Candidate
    if ($Lane -eq "Codex") {
        $model = if ($level -eq "unstated") { "Codex default model; the plan states no level -- use medium reasoning" } else { "Codex default model at $level reasoning" }
    }
    else {
        $model = switch ($level) {
            "high"   { "claude-opus-5" }
            "medium" { "claude-sonnet-5" }
            "low"    { "claude-sonnet-5 at low effort" }
            default  { "claude-sonnet-5; the plan states no level -- say so in the report" }
        }
    }
    $uiFile = @($Candidate.Files | Where-Object { $_ -match '\.(tscn|tres)$' -or $_ -match '^scripts/(hud|ui_[a-z_]+|[a-z_]+_panel|debug_panel|main)\.gd$' })
    $connectorsOn = if ($uiFile.Count -gt 0) { @("godot") } else { @() }
    return [ordered]@{
        level          = $level
        model          = $model
        connectors_on  = @($connectorsOn)
        connectors_off = "every other MCP connector (Notion, computer-use, GitKraken, Claude Docs, scheduled tasks, MCP registry, music, design data)"
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
    Assert-CrossLaneOwnership -Root $root -Candidate $candidate
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

# --- environment ---

function Get-ConfiguredGodotPath {
    param([string]$Root)

    if ($env:GODOT_PATH) {
        return $env:GODOT_PATH
    }

    $command = Get-Command "godot", "godot4" -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($command) {
        return $command.Source
    }

    $configPath = Join-Path $Root ".codex\config.toml"
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        $config = Get-Content -Raw -LiteralPath $configPath
        $match = [regex]::Match($config, '(?m)^\s*GODOT_PATH\s*=\s*[''"](?<path>[^''"]+)[''"]\s*$')
        if ($match.Success) {
            return $match.Groups["path"].Value
        }
    }

    return $null
}

function Get-GodotCapability {
    param([string]$Root)

    $mcpConfigPath = Join-Path $Root ".mcp.json"
    if (Test-Path -LiteralPath $mcpConfigPath -PathType Leaf) {
        try {
            $mcpConfig = Get-Content -Raw -LiteralPath $mcpConfigPath | ConvertFrom-Json
        }
        catch {
            return [PSCustomObject]@{
                state  = "mcp_unavailable"
                reason = "$mcpConfigPath could not be parsed: $($_.Exception.Message)"
            }
        }
        $mcpCommand = $mcpConfig.mcpServers.godot.command
        if ($mcpCommand -and -not (Get-Command $mcpCommand -CommandType Application -ErrorAction SilentlyContinue)) {
            return [PSCustomObject]@{
                state  = "mcp_unavailable"
                reason = "configured MCP command '$mcpCommand' in $mcpConfigPath cannot be resolved on PATH"
            }
        }
    }

    $godotPath = Get-ConfiguredGodotPath -Root $Root
    if (-not $godotPath) {
        return [PSCustomObject]@{
            state  = "editor_unavailable"
            reason = "no executable was found on PATH, in GODOT_PATH, or in .codex/config.toml"
        }
    }
    if (-not (Test-Path -LiteralPath $godotPath -PathType Leaf)) {
        return [PSCustomObject]@{
            state  = "editor_unavailable"
            reason = "configured executable does not exist: $godotPath"
        }
    }

    # Checked before the boot probe below: a fresh worktree with no .godot
    # cache fails the same probe with a non-zero exit and would otherwise be
    # misreported as environment_crash -- the false alarm this state exists
    # to name on sight.
    if (-not (Test-Path -LiteralPath (Join-Path $Root ".godot") -PathType Container)) {
        return [PSCustomObject]@{
            state  = "import_cache_missing"
            reason = "no .godot directory in $Root; verify.ps1 and run_scenario.py seed it from the primary checkout (tools/godot_cache.py), or run python tools/godot_cache.py there"
        }
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $godotPath
    $psi.Arguments = "--headless --disable-crash-handler --quit-after 1"
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    try {
        $process = [System.Diagnostics.Process]::Start($psi)
    }
    catch {
        return [PSCustomObject]@{
            state  = "environment_crash"
            reason = "$godotPath failed to launch: $($_.Exception.Message)"
        }
    }

    # Stdin is closed rather than inherited so a build that misparses these
    # arguments as an interactive prompt hits EOF instead of hanging.
    $process.StandardInput.Close()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $bootProbeTimeoutMs = 20000
    $exited = $process.WaitForExit($bootProbeTimeoutMs)
    if (-not $exited) {
        try { $process.Kill() } catch {}
        return [PSCustomObject]@{
            state  = "environment_crash"
            reason = "$godotPath --headless --quit-after 1 did not exit within $($bootProbeTimeoutMs / 1000) seconds"
        }
    }
    if ($process.ExitCode -ne 0) {
        $detail = @($stderrTask.Result, $stdoutTask.Result) |
            ForEach-Object { ($_ -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 1) } |
            Where-Object { $_ } |
            Select-Object -First 1
        if (-not $detail) { $detail = "no output" }
        return [PSCustomObject]@{
            state  = "environment_crash"
            reason = "$godotPath --headless --quit-after 1 exited with code $($process.ExitCode): $detail"
        }
    }

    return [PSCustomObject]@{
        state  = "ready"
        reason = "$godotPath booted headlessly and exited cleanly"
    }
}

function Get-GlobalExcludesDiagnostic {
    # A read-only probe, reported rather than enforced. Codex rollouts have
    # logged a permissions warning naming the user-level Git excludes file;
    # from an ordinary Windows session the same file reads fine, so the
    # warning is about the path being outside the sandbox's readable scope,
    # not about its ACL. Either way the answer is the same: say which path
    # Git resolved, whether this process can read it, and what to type.
    # Never touch a file outside the repository to "fix" it.
    $configured = (git config --get core.excludesFile 2>$null)
    if ($LASTEXITCODE -ne 0) { $configured = "" }
    $configured = "$configured".Trim()
    $source = "core.excludesFile"
    $path = $configured
    if (-not $path) {
        $source = "Git default"
        $base = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $env:USERPROFILE ".config" }
        $path = Join-Path (Join-Path $base "git") "ignore"
    }
    # Test-Path belongs inside the try: in Codex's sandbox it throws
    # UnauthorizedAccessException for this very file rather than answering,
    # and outside the try that took doctor -- and the five lifecycle tests
    # that run it -- down with it, so every Codex closeout failed its primary
    # verify (FB-3, 25-27 Sep 2026). A probe that reports must never throw.
    try {
        if (-not (Test-Path -LiteralPath $path)) {
            return "absent ($source): $path -- nothing to read; no action needed unless you want a personal ignore file there"
        }
        [void][System.IO.File]::ReadAllBytes($path)
        return "readable ($source): $path"
    }
    catch {
        return ("unreadable ($source): $path -- $($_.Exception.Message). " +
            "Fix it from an ordinary Windows shell with: " +
            "icacls `"$path`" /grant `"$env:USERNAME`":R    " +
            "or point Git at a path inside your profile with: " +
            "git config --global core.excludesFile `"$(Join-Path $env:USERPROFILE '.gitignore_global')`"")
    }
}

function Get-DoctorEnvironmentFailures {
    param(
        [string]$Root,
        [string]$RequestedPythonPath
    )

    $failures = @()

    # A native command's stderr becomes a terminating error under "Stop" (see
    # verify.ps1's Invoke-PythonStage), which would otherwise abort this
    # function on the first failing git call and lose every failure gathered
    # before it. This assignment is local to the function scope.
    $ErrorActionPreference = "Continue"

    $verifyScript = Join-Path $Root "tools\verify.ps1"
    $runtimeArgs = @{ ResolvePythonOnly = $true }
    if ($RequestedPythonPath) {
        $runtimeArgs["PythonPath"] = $RequestedPythonPath
    }
    try {
        $runtimeOutput = @(& $verifyScript @runtimeArgs 2>&1 | ForEach-Object { $_.ToString() })
        $runtimeExit = $LASTEXITCODE
    }
    catch {
        $runtimeOutput = @($_.Exception.Message)
        $runtimeExit = 1
    }
    if ($runtimeExit -ne 0) {
        $detail = ($runtimeOutput | Where-Object { $_ } | Select-Object -Last 1)
        $failures += "Python: $detail"
    }

    $godotPath = Get-ConfiguredGodotPath -Root $Root
    if (-not $godotPath) {
        $failures += "Godot: no executable was found on PATH, in GODOT_PATH, or in .codex/config.toml"
    }
    elseif (-not (Test-Path -LiteralPath $godotPath -PathType Leaf)) {
        $failures += "Godot: configured executable does not exist: $godotPath"
    }

    $userName = (& git -C $Root config --get user.name 2>$null | Select-Object -First 1)
    $userEmail = (& git -C $Root config --get user.email 2>$null | Select-Object -First 1)
    $identityParts = @()
    if ([string]::IsNullOrWhiteSpace($userName)) { $identityParts += "user.name" }
    if ([string]::IsNullOrWhiteSpace($userEmail)) { $identityParts += "user.email" }
    if ($identityParts) {
        $failures += "Git identity: missing $($identityParts -join ' and ')"
    }

    # This probe ignores untracked files, so a user-level excludes file cannot
    # affect its answer. Override it with an empty value to avoid making doctor depend on
    # read access to an otherwise unrelated home-directory file.
    $ownershipOutput = @(& git -c core.excludesFile= -C $Root status --porcelain --untracked-files=no 2>&1 |
        ForEach-Object { $_.ToString() })
    $ownershipExit = $LASTEXITCODE
    if ($ownershipExit -ne 0) {
        $detail = ($ownershipOutput | Where-Object { $_ } | Select-Object -Last 1)
        $failures += "Repository ownership: Git cannot read the worktree: $detail"
    }

    $remoteUrl = (& git -C $Root remote get-url --push origin 2>$null | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
        $failures += "Remote reachability: push remote 'origin' is not configured"
    }
    else {
        $remoteOutput = @(& git -c http.sslBackend=openssl -C $Root ls-remote --exit-code origin HEAD 2>&1 |
            ForEach-Object { $_.ToString() })
        $remoteExit = $LASTEXITCODE
        if ($remoteExit -ne 0) {
            $detail = ($remoteOutput | Where-Object { $_ } | Select-Object -Last 1)
            $failures += "Remote reachability: cannot reach origin ($remoteUrl): $detail"
        }
    }

    $commonDirOutput = @(& git -C $Root rev-parse --git-common-dir 2>&1 |
        ForEach-Object { $_.ToString() })
    $commonDirExit = $LASTEXITCODE
    if ($commonDirExit -ne 0 -or -not $commonDirOutput) {
        $detail = ($commonDirOutput | Where-Object { $_ } | Select-Object -Last 1)
        $failures += "Git metadata write: cannot locate the common Git directory: $detail"
    }
    else {
        # update-ref exercises Git's real lock-and-rename path rather than a
        # plain file write. The temporary ref is always removed, so doctor
        # proves shared-metadata access without leaving repository state.
        $probeRef = "refs/codex-doctor/$([guid]::NewGuid().ToString('N'))"
        $probeCreated = $false
        try {
            $probeOutput = @(& git -C $Root update-ref $probeRef HEAD 2>&1 |
                ForEach-Object { $_.ToString() })
            $probeExit = $LASTEXITCODE
            if ($probeExit -ne 0) {
                $detail = ($probeOutput | Where-Object { $_ } | Select-Object -Last 1)
                $failures += "Git metadata write: cannot create disposable ref ${probeRef}: $detail"
            }
            else {
                $probeCreated = $true
            }
        }
        finally {
            if ($probeCreated) {
                $deleteOutput = @(& git -C $Root update-ref -d $probeRef 2>&1 |
                    ForEach-Object { $_.ToString() })
                $deleteExit = $LASTEXITCODE
                if ($deleteExit -ne 0) {
                    $detail = ($deleteOutput | Where-Object { $_ } | Select-Object -Last 1)
                    $failures += "Git metadata write: cannot remove disposable ref ${probeRef}: $detail"
                }
            }
        }
    }

    return $failures
}

# --- commands ---

function Invoke-SliceDoctor {
    param(
        [string]$Lane,
        [string]$PythonPath
    )

    $root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    Remove-PendingWorktreeDirectories -Root $root
    $failures = @(Get-DoctorEnvironmentFailures -Root $root -RequestedPythonPath $PythonPath)
    # WD-2: one env_capability event per doctor, so "how often does the
    # environment rather than the code block a session?" has an answer.
    # `detail` is the category before the first colon, never the message.
    $godotCapability = Get-GodotCapability -Root $root
    Write-Diagnostic -Root $root -Kind "env_capability" -Fields @{
        lane     = $Lane
        godot    = $godotCapability
        failures = $failures.Count
        ok       = ($failures.Count -eq 0)
        detail   = if ($failures.Count -gt 0) { ($failures[0] -split ':')[0] } else { "" }
    }

    try {
        $preflight = Get-SlicePreflight -Lane $Lane
    }
    catch {
        $failures += "Slice preflight: $($_.Exception.Message)"
    }

    if ($failures) {
        [Console]::Error.WriteLine("slice doctor found $($failures.Count) problem(s):")
        foreach ($failure in $failures) {
            [Console]::Error.WriteLine("- $failure")
        }
        exit 1
    }

    [ordered]@{
        status       = "ready"
        id           = $preflight.Id
        lane         = $Lane
        plan         = $preflight.Candidate.Plan
        heading      = $preflight.Candidate.Heading
        read         = Get-SliceReadCommand -Candidate $preflight.Candidate
        files        = $preflight.Candidate.Files
        check        = $preflight.Candidate.Check
        proof        = $preflight.Candidate.Proof
        next_after   = $preflight.Candidate.NextAfter
        advice       = Get-SliceAdvice -Root $root -Candidate $preflight.Candidate -Lane $Lane
        branch       = $preflight.Branch
        worktree     = $preflight.WorktreeRelative
        git_excludes = Get-GlobalExcludesDiagnostic
        godot_capability = $godotCapability
        pending_deletions = Get-PendingWorktreeDeletions -Root $root
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
    [System.IO.File]::AppendAllText($ledgerPath, $row + "`r`n")

    Push-Location $root
    try {
        git add "plans/workstreams.md"
        if ($LASTEXITCODE -ne 0) { throw "git add failed" }
        $commitMessage = "Register the $id worktree in the ledger`n`n$(Get-LaneTrailer -Lane $Lane)"
        git commit -m $commitMessage | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git commit failed" }

        git worktree add $worktreeRelative -b $branch | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git worktree add failed" }

        # The new worktree has no .godot import cache yet. Its first boot
        # through verify.ps1 or run_scenario.py seeds one from this primary
        # checkout (tools/godot_cache.py), the one place that copies it.

        Invoke-InjectedLifecycleFailure -Phase "started"
    }
    finally {
        Pop-Location
    }

    $result = [ordered]@{
        id         = $id
        plan       = $candidate.Plan
        heading    = $candidate.Heading
        read       = Get-SliceReadCommand -Candidate $candidate
        files      = $candidate.Files
        check      = $candidate.Check
        proof      = $candidate.Proof
        next_after = $candidate.NextAfter
        advice     = Get-SliceAdvice -Root $root -Candidate $candidate -Lane $Lane
        branch     = $branch
        worktree   = $worktreeRelative
    }
    # The session id is the level-drift join key.  A claim creates its branch
    # after the session began, so joining the hook's pre-existing branch to
    # this new one can never work.  Claude Code exports CLAUDE_CODE_SESSION_ID
    # to the lifecycle command, and it equals the session_id the SessionStart
    # hook records; omit it when a non-Claude caller does not provide one so
    # the append-only diagnostic schema stays backward compatible.  (Until 25
    # Sep 2026 this read CLAUDE_SESSION_ID, which is never set, so no claim
    # before then carries a session.)
    Write-Diagnostic -Root $root -Kind "slice_claimed" -Fields @{
        id     = $id
        lane   = $Lane
        branch = $branch
        level  = $result.advice.level
        session = $env:CLAUDE_CODE_SESSION_ID
        ok     = $true
        ms     = [int]$script:SliceStopwatch.ElapsedMilliseconds
    }
    $result | ConvertTo-Json -Compress
}

function Get-SliceTarget {
    param([string]$Root, [string]$Lane)
    if (-not $Lane) { throw "resume and abort require -Lane Claude|Codex when run from the primary checkout" }
    $row = Get-LedgerLaneRows -Root $Root | Where-Object { $_.Lane -eq $Lane } | Select-Object -First 1
    if (-not $row) { throw "no open $Lane lifecycle was found" }
    $worktreeMatch = [regex]::Match($row.Worktree, '`(?<path>[^`]+)`')
    $worktreeRelative = if ($worktreeMatch.Success) { $worktreeMatch.Groups['path'].Value } else { $row.Worktree }
    $id = Split-Path -Leaf ($worktreeRelative -replace '/', '\\')
    [PSCustomObject]@{
        Id = $id; Lane = $Lane; Branch = "$($Lane.ToLower())/$id"
        WorktreeRelative = $worktreeRelative; WorktreePath = Join-Path $Root $worktreeRelative
    }
}

function Test-SliceBranchMerged {
    param([string]$Root, [string]$Branch)
    # A newly-created branch also starts as an ancestor of master, so ancestry
    # alone cannot prove a merge. While the branch still exists, its exact
    # head must be a parent of the named no-ff merge; once cleanup deleted the
    # branch, that merge message is the durable truth. This also prevents an
    # old completed fixture or reused id from being mistaken for the current
    # unmerged branch.
    $branchHead = @(git -C $Root rev-parse --verify --quiet "refs/heads/$Branch" 2>$null | Select-Object -First 1)
    $mergeParents = @(git -C $Root log master --merges --format=%P --fixed-strings --grep=$Branch 2>$null)
    if ($branchHead) {
        return @($mergeParents | Where-Object { ($_ -split '\s+') -contains $branchHead[0].Trim() }).Count -gt 0
    }
    return $mergeParents.Count -gt 0
}

function Remove-SliceLedgerRow {
    param([string]$Root, [object]$Target, [switch]$SkipPush)
    $ledgerPath = Join-Path $Root "plans\workstreams.md"
    $marker = '`' + $Target.WorktreeRelative + '`'
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $lines = @([System.IO.File]::ReadAllLines($ledgerPath, $utf8))
    $keep = @($lines | Where-Object { $_.IndexOf($marker, [System.StringComparison]::Ordinal) -lt 0 })
    if ($keep.Count -eq $lines.Count) { return $false }
    [System.IO.File]::WriteAllLines($ledgerPath, [string[]]$keep, $utf8)
    git -C $Root add "plans/workstreams.md"
    if ($LASTEXITCODE -ne 0) { throw "git add failed" }
    git -C $Root commit -m "Remove the $($Target.Id) worktree row from the ledger`n`n$(Get-LaneTrailer -Lane $Target.Lane)" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
    if (-not $SkipPush) {
        git -c http.sslBackend=openssl -C $Root push
        if ($LASTEXITCODE -ne 0) { throw "git push failed" }
    }
    return $true
}

# --- post-merge ---

function Invoke-SlicePostMergeCleanup {
    # Everything that happens once the branch is known to be merged: it is
    # the single tail both Invoke-SliceFinish (the common case) and
    # Invoke-SliceResume (recovering after an interrupted finish) call, so
    # there is exactly one place that regenerates the ready-check index,
    # removes the worktree/branch/ledger row, and pushes -- once, at the end,
    # with every commit the transaction made. Before this unification, finish
    # pushed after the ready-index commit *and* after the ledger commit,
    # while resume's own repair path skipped the ready-index step entirely.
    param([string]$Root, [object]$Target, [string]$PythonPath)

    $trailer = Get-LaneTrailer -Lane $Target.Lane

    # The ready-check page is a shared index, deliberately generated only
    # here, once the feature branch is known to be merged. This keeps
    # parallel branches from appending to the same Markdown file.
    $indexGenerator = Join-Path $Root "tools\check_docs.py"
    $verifyScript = Join-Path $Root "tools\verify.ps1"
    $python = if ($PythonPath) { $PythonPath } else { & $verifyScript -ResolvePythonOnly }
    if (-not $python -or -not (Test-Path -LiteralPath $python -PathType Leaf)) {
        throw "could not resolve Python for the ready-check index"
    }
    & $python $indexGenerator --write-ready-index
    if ($LASTEXITCODE -ne 0) { throw "could not regenerate checks/ready.md" }
    git -C $Root add -- checks/ready.md
    if ($LASTEXITCODE -ne 0) { throw "git add failed" }
    git -C $Root diff --cached --quiet -- checks/ready.md
    if ($LASTEXITCODE -ne 0) {
        git -C $Root commit -m "$($Target.Id) -- refresh ready-check index`n`n$trailer" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git commit failed while refreshing ready-check index" }
    }
    Invoke-InjectedLifecycleFailure -Phase "ready-index"

    if (Test-Path -LiteralPath $Target.WorktreePath) {
        # No stderr redirect here: PowerShell 5.1 wraps a redirected native
        # stderr line in a terminating ErrorRecord under $ErrorActionPreference
        # = "Stop", turning git's own "failed to delete" message (the normal
        # outcome of the case handled two lines down) into an uncaught
        # exception instead of the non-zero exit code this checks for.
        git -C $Root worktree remove --force $Target.WorktreeRelative
        if ($LASTEXITCODE -ne 0 -and (Test-Path -LiteralPath $Target.WorktreePath)) {
            # `git worktree remove` can deregister the worktree and still fail
            # to delete the directory (an external process briefly holding it
            # open -- OneDrive and the Search Indexer both do this on a
            # freshly emptied folder, same as a running Godot instance can).
            Remove-Item -LiteralPath $Target.WorktreePath -Recurse -Force -ErrorAction SilentlyContinue
        }
        git -C $Root worktree prune
    }
    if (Test-Path -LiteralPath $Target.WorktreePath) {
        # Prune git's own records regardless -- they are correct even when
        # the directory lags -- and queue the directory for a later slice
        # command to retry, rather than holding the lifecycle lock while we
        # wait.
        Add-PendingWorktreeDeletion -Root $Root -WorktreeRelative $Target.WorktreeRelative
        Write-Output "$($Target.Id) -- $($Target.WorktreeRelative) could not be deleted; queued in pending deletions for retry at the next slice command"
    }
    Invoke-InjectedLifecycleFailure -Phase "worktree-removed"

    git -C $Root show-ref --verify --quiet "refs/heads/$($Target.Branch)"
    if ($LASTEXITCODE -eq 0) {
        # The branch is already proven to be the second parent of its merge.
        # `-d` additionally insists its configured remote-tracking ref exists;
        # a normal slice never pushes its own branch, so that requirement turns
        # a completed local merge into a false cleanup failure.
        git -C $Root branch -D $Target.Branch
        if ($LASTEXITCODE -ne 0) { throw "git branch cleanup failed" }
    }
    Invoke-InjectedLifecycleFailure -Phase "branch-deleted"

    $removed = Remove-SliceLedgerRow -Root $Root -Target $Target -SkipPush
    if ($removed) { Invoke-InjectedLifecycleFailure -Phase "ledger-deleted" }

    # A closeout that archives a plan's last slice leaves the plan itself live
    # and marked complete, which check_docs' terminal-plan rule then fails on
    # every later branch (CB-2, T-3, V-4, ST-1). The plan can only move once
    # nothing in flight cites it -- the queue item went with the merge, the
    # ledger row just above -- so it moves here, on master, and travels in
    # the same push. A plan the tool keeps live is reported, not fatal: the
    # merge is already done, and check_docs still names what is left.
    $archiveTool = Join-Path $Root "tools\archive_slice.py"
    if (Test-Path -LiteralPath $archiveTool -PathType Leaf) {
        $run = Invoke-SlicePythonTool -Root $Root -PythonPath $PythonPath -Arguments @($archiveTool, "--complete-plans", "--root", $Root)
        $run.Output | ForEach-Object { Write-Output $_ }
        $touched = @($run.Output | Where-Object { $_ -like "touched: *" } | ForEach-Object { $_.Substring(9).Trim() })
        if ($touched) {
            $archived = @($run.Output | Where-Object { $_ -like "plan archived: *" } | ForEach-Object { ($_.Substring(15) -split " -> ")[0] })
            git -C $Root commit -m "$($Target.Id) -- archive the finished plan $($archived -join ', ')`n`n$trailer" -- @touched | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "git commit failed while archiving a finished plan" }
        }
        if ($run.Exit -ne 0) {
            Write-Output "$($Target.Id) -- a finished plan was kept live (reason above); check_docs will name it until it is moved to plans/archive/"
        }
    }

    # The one push for the whole transaction: every commit the merge, the
    # ready-index refresh and the ledger removal made travels together.
    if ((Invoke-GitQuiet -c http.sslBackend=openssl -C $Root push) -ne 0) { throw "git push failed" }
    Invoke-InjectedLifecycleFailure -Phase "pushed"

    if ((Invoke-GitQuiet -c http.sslBackend=openssl -C $Root ls-remote --exit-code --heads origin $Target.Branch) -eq 0) {
        if ((Invoke-GitQuiet -c http.sslBackend=openssl -C $Root push origin --delete $Target.Branch) -ne 0) { throw "git push origin --delete failed" }
    }
}

function Invoke-GitQuiet {
    # A native command's stderr becomes a terminating ErrorRecord in
    # PowerShell 5.1 whenever the *caller* redirects it -- `finish *> log.txt`,
    # or a wrapper piping through 2>&1 -- and `git push` writes its progress
    # to stderr on every success. Closeout then aborted after the merge, with
    # the branch already gone and the push not made (17 Sep 2026; the same
    # trap is why the worktree-remove call below carries its own note). Every
    # git call that talks to the remote goes through here, so the exit code
    # decides the outcome no matter how the session is invoking the script.
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & git @Arguments 2>&1 | ForEach-Object { Write-Host $_ }
    }
    finally {
        $ErrorActionPreference = $previous
    }
    return $LASTEXITCODE
}

function Test-OwnedPath {
    # A queue `Files:` entry or a changed file owns a path when they are the
    # same file, or when one is a folder (trailing slash) containing the other.
    param([string]$Owned, [string]$Wanted)
    $a = ($Owned -replace '\\', '/').Trim()
    $b = ($Wanted -replace '\\', '/').Trim()
    if ($a -eq $b) { return $true }
    if ($a.EndsWith("/") -and $b.StartsWith($a)) { return $true }
    if ($b.EndsWith("/") -and $a.StartsWith($b)) { return $true }
    return $false
}

function Invoke-SliceOwner {
    # Ad-hoc work (anything not claimed with `start`) runs this before editing.
    # On 20 Sep an ad-hoc session rebuilt verify.ps1's regeneration while the
    # queued V-1 slice was building the same thing; the branch was never merged.
    # A path is owned by any queue item that lists it, in either lane, and by
    # any unmerged local branch other than this one that already changes it.
    param([string[]]$Wanted)
    if (-not $Wanted) {
        Write-Error "owner needs at least one repository-relative path, e.g. tools/slice.ps1 owner tools/verify.ps1"
        exit 1
    }
    $root = Get-PrimaryRoot
    $here = (git rev-parse --abbrev-ref HEAD 2>$null)
    $owners = @()
    foreach ($item in Get-NextUpItems -Root $root) {
        $hits = @($Wanted | Where-Object { $w = $_; @($item.Files | Where-Object { Test-OwnedPath -Owned $_ -Wanted $w }).Count -gt 0 })
        if ($hits) {
            $owners += [PSCustomObject]@{ kind="queue"; id=$item.Id; lane=$item.Lane; title=$item.Title; paths=$hits }
        }
    }
    $branches = @(git -C $root branch --no-merged master --format="%(refname:short)" 2>$null | Where-Object { $_ -and $_ -ne $here })
    foreach ($branch in $branches) {
        $changed = @(git -C $root diff --name-only "master...$branch" 2>$null)
        $hits = @($Wanted | Where-Object { $w = $_; @($changed | Where-Object { Test-OwnedPath -Owned $_ -Wanted $w }).Count -gt 0 })
        if ($hits) {
            $last = (git -C $root log -1 --format="%cs %s" $branch 2>$null)
            $owners += [PSCustomObject]@{ kind="branch"; branch=$branch; last_commit=$last; paths=$hits }
        }
    }
    $status = if ($owners) { "owned" } else { "clear" }
    $next = if ($owners) { "stop: ask Dave whether to take the owning slice, wait for it, or finish/delete the branch -- do not build the same change twice" } else { "go ahead" }
    [PSCustomObject]@{ status=$status; owners=$owners; next=$next } | ConvertTo-Json -Depth 4 -Compress
    if ($owners) { exit 1 }
}

function Invoke-SliceStatus {
    param([string]$Lane)
    $root = Get-PrimaryRoot
    $rows = Get-LedgerLaneRows -Root $root
    $states = foreach ($row in $rows) {
        if ($Lane -and $row.Lane -ne $Lane) { continue }
        $worktreeMatch = [regex]::Match($row.Worktree, '`(?<path>[^`]+)`')
        $worktreeRelative = if ($worktreeMatch.Success) { $worktreeMatch.Groups['path'].Value } else { $row.Worktree }
        $id = Split-Path -Leaf ($worktreeRelative -replace '/', '\\')
        $branch = "$($row.Lane.ToLower())/$id"
        $worktreeExists = Test-Path -LiteralPath (Join-Path $root $worktreeRelative)
        git -C $root show-ref --verify --quiet "refs/heads/$branch"
        $branchExists = $LASTEXITCODE -eq 0
        $phase = if ($branchExists -and (Test-SliceBranchMerged -Root $root -Branch $branch)) { "merged; cleanup pending" } elseif ($worktreeExists) { "working" } elseif ($branchExists) { "worktree missing; resumable" } else { "ledger-only; repair required" }
        [PSCustomObject]@{ id=$id; lane=$row.Lane; branch=$branch; worktree=$worktreeRelative; state=$phase }
    }
    if (-not $states) { $states = @([PSCustomObject]@{ state="idle" }) }
    # `running` is the lifecycle command holding the lock now; `last_run` is
    # how the most recent one ended. Together they answer "did my finish
    # land?" for a caller whose shell returned before finish did.
    $running = Get-LifecycleHolder -LockPath (Get-LifecycleFilePath -Root $root -Name "meadow-slice-lifecycle.lock")
    $lastRun = $null
    $lastRunPath = Get-LifecycleFilePath -Root $root -Name "meadow-slice-last-run.json"
    if (Test-Path -LiteralPath $lastRunPath) {
        try { $lastRun = Get-Content -Raw -LiteralPath $lastRunPath | ConvertFrom-Json } catch { $lastRun = $null }
    }
    foreach ($state in $states) {
        $state | Add-Member -NotePropertyName running -NotePropertyValue $running
        $state | Add-Member -NotePropertyName last_run -NotePropertyValue $lastRun
    }
    $states | ConvertTo-Json -Compress -Depth 4
}

function Invoke-SliceResume {
    param([string]$Lane, [string]$PythonPath)
    $root = Get-PrimaryRoot
    $openRow = Get-LedgerLaneRows -Root $root | Where-Object { $_.Lane -eq $Lane } | Select-Object -First 1
    if (-not $openRow) {
        Write-Output "Slice resume: no open $Lane lifecycle remains; cleanup is already complete"
        return
    }
    $target = Get-SliceTarget -Root $root -Lane $Lane
    if (Test-SliceBranchMerged -Root $root -Branch $target.Branch) {
        Invoke-SlicePostMergeCleanup -Root $root -Target $target -PythonPath $PythonPath
        Remove-ClosingJournal -Root $root
        Write-Output "Slice resumed: $($target.Id) -- post-merge cleanup complete"
        return
    }
    if (-not (Test-Path -LiteralPath $target.WorktreePath)) { throw "$($target.Id) -- branch exists but its worktree is missing; abort is safe before merge" }
    Set-Location -LiteralPath $target.WorktreePath
    Invoke-SliceFinish -PythonPath $PythonPath
}

function Invoke-SliceAbort {
    param([string]$Lane)
    $root = Get-PrimaryRoot
    $target = Get-SliceTarget -Root $root -Lane $Lane
    if (Test-SliceBranchMerged -Root $root -Branch $target.Branch) { throw "$($target.Id) has already merged; use resume, not abort" }
    if (Test-Path -LiteralPath $target.WorktreePath) { git -C $root worktree remove --force $target.WorktreeRelative; git -C $root worktree prune }
    git -C $root show-ref --verify --quiet "refs/heads/$($target.Branch)"
    if ($LASTEXITCODE -eq 0) { git -C $root branch -D $target.Branch }
    [void](Remove-SliceLedgerRow -Root $root -Target $target)
    Write-Output "Slice aborted: $($target.Id)"
}

function Get-SuccessorId {
    # A `Next after:` value is prose ("L-6 -- two lanes closing out at once is
    # a test, not a hope."), not a queue item -- only its leading token is an
    # id. `none -- <plan> is complete` is the one value that names no
    # successor at all.
    param([string]$NextAfter)
    if (-not $NextAfter -or $NextAfter -match '^\s*none\b') { return $null }
    return ($NextAfter -split '--', 2)[0].Trim()
}

function Test-SuccessorDeferred {
    # A successor is not always admissible the moment its predecessor lands:
    # G3 followed G2 but waits on F2s, and the queue's own rule sends a
    # blocked item to "## Not in the queue, and why". Before 17 Sep 2026 the
    # refill gate knew only "in the lane", so closing such a slice meant
    # either queueing an unstartable item or lying in its `Next after:` line.
    # Only the bolded lead of each bullet counts, the same rule
    # check_docs.py's check_queue_section_agreement uses, so the prose naming
    # other ids as reasons stays allowed.
    param([string]$Text, [string]$Id)
    return ($null -ne (Get-SuccessorDeferralReason -Text $Text -Id $Id))
}

function Get-SuccessorDeferralReason {
    # The rest of $Id's bullet under "## Not in the queue, and why" -- the
    # part after its " -- ", which says what it waits for -- or $null when
    # $Id is not deferred there. The end-of-slice report quotes it, so a
    # deferred successor reads as deliberate rather than a failed refill.
    param([string]$Text, [string]$Id)
    if (-not $Id) { return $null }
    $section = [regex]::Match($Text, '(?ms)^## Not in the queue, and why\s*$(.*?)(?=^## |\Z)')
    if (-not $section.Success) { return $null }
    foreach ($bullet in [regex]::Matches($section.Groups[1].Value, '(?m)^-\s+\*\*(.+?)\*\*(.*?)\r?$')) {
        if ($bullet.Groups[1].Value -match "\b$([regex]::Escape($Id))\b") {
            $rest = $bullet.Groups[2].Value.Trim()
            $parts = $rest -split '\s--\s', 2
            if ($parts.Count -eq 2) { return $parts[1].Trim() }
            return $rest
        }
    }
    return $null
}

function Get-CopyPastePromptLine {
    # The exact block under "## Copy-paste prompts" for $Lane, so "Start it
    # with" in the end-of-slice report is a lookup instead of the generic
    # "tools/slice.ps1 start -Lane <lane with a free head>" a session then had
    # to translate into an actual prompt by hand.
    param([string]$Text, [string]$Lane)
    $pattern = "(?is)$([regex]::Escape($Lane)), implementing:\s*``````\s*\r?\n(.*?)``````"
    $match = [regex]::Match($Text, $pattern)
    if ($match.Success) { return $match.Groups[1].Value.Trim() }
    return $null
}

function Save-SliceBranchWork {
    # Stage and commit everything outstanding in the slice worktree; a clean
    # tree is left alone rather than given an empty commit.
    param([string]$Root, [string]$Message)
    git -C $Root add -A
    if ($LASTEXITCODE -ne 0) { throw "git add failed" }
    $staged = git -C $Root diff --cached --name-only
    if ($staged) {
        git -C $Root commit -m $Message | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
    }
}

function Invoke-SlicePythonTool {
    # Run one of the repository's Python tools and hand back its exit code
    # and every output line. Local "Continue": PowerShell 5.1 turns a
    # redirected native stderr line into a terminating ErrorRecord under
    # "Stop", which would replace the tool's own refusal with an exception.
    param([string]$Root, [string]$PythonPath, [string[]]$Arguments)
    $ErrorActionPreference = "Continue"
    $python = if ($PythonPath) { $PythonPath } else { & (Join-Path $Root "tools\verify.ps1") -ResolvePythonOnly | Select-Object -Last 1 }
    if (-not $python -or -not (Test-Path -LiteralPath $python -PathType Leaf)) {
        throw "could not resolve Python for $($Arguments[0]); pass -PythonPath"
    }
    $output = @(& $python @Arguments 2>&1 | ForEach-Object { $_.ToString() })
    return [pscustomobject]@{ Exit = $LASTEXITCODE; Output = $output }
}

function Get-SliceArchiveState {
    # What the "archived" gate reads, shared with the action that satisfies
    # it. State is "done" once the heading has left its plan and a
    # plans/archive/<id>_*.md record names that heading; "reused" when such
    # files exist but none names it (an id shipped before under another
    # heading); otherwise "missing" (no record) or "live" (heading still in
    # the plan).
    param([string]$Root, [object]$Item, [string]$Id)
    $archiveMatches = @(Get-ChildItem -Path (Join-Path $Root "plans\archive") -Filter "$Id`_*.md" -File -ErrorAction SilentlyContinue)
    $planPath = Join-Path $Root $Item.Plan
    $headingLive = $false
    if ($Item.Heading -and (Test-Path -LiteralPath $planPath -PathType Leaf)) {
        $planText = Get-Content -Raw -Encoding UTF8 -LiteralPath $planPath
        $headingRegex = [regex]::new('(?im)^#{1,6}\s+.*' + [regex]::Escape($Item.Heading))
        $headingLive = $headingRegex.IsMatch($planText)
    }
    # An id can be reused: plans/now/ui-w.md's UI-W-1..4 repeat four
    # ids that shipped from the ui-windows plan in September, so a
    # file named <id>_<date>.md is not on its own evidence that *this*
    # slice was archived -- an old namesake would satisfy the gate
    # while this slice's specification was simply deleted. Require a
    # record that names this slice's own heading. Deliberately not a
    # git range: `finish` is resumable after the merge, where every
    # such range is empty (17 Sep 2026 plan review).
    $namesThisSlice = -not $Item.Heading
    foreach ($candidate in $archiveMatches) {
        $candidateText = Get-Content -Raw -Encoding UTF8 -LiteralPath $candidate.FullName
        if ($candidateText.IndexOf($Item.Heading, [System.StringComparison]::Ordinal) -ge 0) { $namesThisSlice = $true; break }
    }
    $state = if ($archiveMatches -and -not $namesThisSlice -and -not $headingLive) { "reused" }
        elseif (-not $archiveMatches) { "missing" }
        elseif ($headingLive) { "live" }
        else { "done" }
    return [pscustomobject]@{ State = $state; HeadingLive = $headingLive; Count = $archiveMatches.Count }
}

function Invoke-SliceArchiveAndRefill {
    # L-13: do the archive move (tools/archive_slice.py, L-10) and the lane
    # deletion (tools/refill_lane.py, L-11) that the "archived" and
    # "refilled" gates would otherwise demand by hand, and commit each.
    # Each tool runs only when ground truth says its step is still owed, so
    # a branch that did either by hand -- or a resume after this already ran
    # -- passes straight through, and the gates stay as the proof that it
    # worked. Since L-12 (21 Sep 2026) the same refill call also tops the
    # lane back up from the queue blocks in the plans, so the five lines a
    # session used to rewrite out of plan prose are a copy. The archive runs
    # first on purpose: it takes the closing slice's section, and with it the
    # block, out of the plan before the top-up looks for candidates.
    param([string]$Root, [object]$Item, [string]$Id, [string]$Lane, [string]$Trailer, [string]$PythonPath)
    if (-not $Item) { return }

    $archiveTool = Join-Path $Root "tools\archive_slice.py"
    $archive = Get-SliceArchiveState -Root $Root -Item $Item -Id $Id
    if ($archive.HeadingLive -and (Test-Path -LiteralPath $archiveTool -PathType Leaf)) {
        # archive_slice.py refuses a dirty tree (so `git checkout` can undo
        # its move); anything a resume left uncommitted goes in first.
        Save-SliceBranchWork -Root $Root -Message "$Id -- finish outstanding work`n`n$Trailer"
        $run = Invoke-SlicePythonTool -Root $Root -PythonPath $PythonPath -Arguments @($archiveTool, $Id, "--root", $Root)
        $run.Output | ForEach-Object { Write-Output $_ }
        if ($run.Exit -ne 0) {
            Stop-Slice -Cause "$Id -- tools/archive_slice.py $Id refused (exit $($run.Exit)); its reason is printed above and nothing was moved" -Fix "fix what it names on this branch (or move the section under '$($Item.Heading)' into plans/archive/$Id`_$(Get-Date -Format yyyy-MM-dd).md by hand), commit, and retry"
        }
        Save-SliceBranchWork -Root $Root -Message "$Id -- archive its plan section`n`n$Trailer"
    }

    $refillTool = Join-Path $Root "tools\refill_lane.py"
    $stillQueued = Get-NextUpItems -Root $Root | Where-Object { $_.Id -eq $Id }
    if (Test-Path -LiteralPath $refillTool -PathType Leaf) {
        # One call: delete the closing item if it is still there, then fill the
        # lane back towards five from the backlog. --top-up runs even when the
        # deletion was done by hand, because a short lane is worth topping up
        # whoever emptied it.
        $refillArgs = @($refillTool)
        if ($stillQueued) { $refillArgs += @("--delete", $Id) }
        $refillArgs += @("--top-up", "--lane", $Lane, "--root", $Root)
        $run = Invoke-SlicePythonTool -Root $Root -PythonPath $PythonPath -Arguments $refillArgs
        $run.Output | ForEach-Object { Write-Output $_ }
        if ($run.Exit -ne 0) {
            Stop-Slice -Cause "$Id -- tools/refill_lane.py refused (exit $($run.Exit)); its reason is printed above and NEXTSTEPS.md is unchanged" -Fix "on this branch give its successor ($($Item.NextAfter)) a ``````queue block in its own plan section -- or, if that says the plan is complete, the next ready, file-disjoint slice from an owning plan -- then retry finish; it deletes $Id, tops the $Lane lane up and commits both. If the successor is not startable yet, put it under '## Not in the queue, and why' with what it waits for instead"
        }
        Save-SliceBranchWork -Root $Root -Message "$Id -- refill the $Lane lane`n`n$Trailer"
    }
}

# Releases the file locks a Godot run holds on the worktree about to be
# deleted. Only processes whose command line names that worktree are
# stopped: killing every Godot.exe on the machine ended other sessions'
# scenario runs mid-flight with exit code 4294967295 and no output, which
# looked exactly like a native crash (docs/known-pitfalls.md, 24 Sep 2026).
function Stop-WorktreeGodot {
    param([string]$Root)
    $needle = ([System.IO.Path]::GetFullPath($Root)).TrimEnd('\').Replace('\', '/').ToLowerInvariant()
    Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine.Replace('\', '/').ToLowerInvariant().Contains($needle) } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Invoke-SliceFinish {
    param([string]$PythonPath)

    $worktreeRoot = (Get-Location).Path
    $root = Get-PrimaryRoot

    Set-SliceStep "locating the slice worktree"
    if ((Resolve-Path -LiteralPath $worktreeRoot).Path -eq (Resolve-Path -LiteralPath $root).Path) {
        Stop-Slice -Cause "finish was run from the primary checkout" -Fix "cd into the slice's worktree (.worktrees/<id>) and run it there; if the branch is already merged, run tools/slice.ps1 resume -Lane <lane> from here instead"
    }

    $branch = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($LASTEXITCODE -ne 0) {
        Stop-Slice -Cause "not inside a git branch" -Fix "cd into the slice's worktree (.worktrees/<id>)"
    }
    $branchMatch = [regex]::Match($branch, '^(?<prefix>claude|codex)/(?<id>.+)$')
    if (-not $branchMatch.Success) {
        Stop-Slice -Cause "not on a slice branch (claude/<id> or codex/<id>): current branch is $branch" -Fix "finish closes only a branch made by tools/slice.ps1 start; merge any other branch by hand"
    }
    $id = $branchMatch.Groups["id"].Value
    $lane = if ($branchMatch.Groups["prefix"].Value -eq "claude") { "Claude" } else { "Codex" }
    $script:SliceContext.Id = $id
    $script:SliceContext.Lane = $lane
    $otherLane = if ($lane -eq "Claude") { "Codex" } else { "Claude" }
    $trailer = Get-LaneTrailer -Lane $lane
    $worktreeRelative = ".worktrees/$id"

    $journal = Get-ClosingJournal -Root $worktreeRoot -Branch $branch

    $verifyScript = Join-Path $worktreeRoot "tools\verify.ps1"
    Set-SliceStep "branch verification (tools/verify.ps1 -Scope branch)"
    if (-not (Test-ClosingPhaseDone -Journal $journal -Phase "verified")) {
        $verifyCmd = Get-Command $verifyScript
        # A hashtable splat, not an array: array splatting passes its elements as
        # positional arguments, so "-Quiet" bound to verify.ps1's $PythonPath and
        # every closeout died on "the supplied Python interpreter does not exist".
        $verifyArgs = @{}
        if ($verifyCmd.Parameters.ContainsKey("Quiet")) {
            $verifyArgs["Quiet"] = $true
        }
        if ($PythonPath -and $verifyCmd.Parameters.ContainsKey("PythonPath")) {
            $verifyArgs["PythonPath"] = $PythonPath
        }
        if ($verifyCmd.Parameters.ContainsKey("Scope")) {
            $verifyArgs["Scope"] = "branch"
        }
        $previousFinishVerify = $env:MEADOW_FINISH_VERIFY
        $env:MEADOW_FINISH_VERIFY = "1"
        try {
            $verifyOutput = & $verifyScript @verifyArgs 2>&1
            $verifyExit = $LASTEXITCODE
        }
        catch {
            $verifyOutput = $_ | Out-String
            $verifyExit = 1
        }
        finally {
            if ($null -eq $previousFinishVerify) {
                Remove-Item Env:MEADOW_FINISH_VERIFY -ErrorAction SilentlyContinue
            }
            else {
                $env:MEADOW_FINISH_VERIFY = $previousFinishVerify
            }
        }
        $verifyOutput | ForEach-Object { Write-Output $_ }
        if ($verifyExit -ne 0) {
            $verifyLog = Save-VerifyLog -Root $worktreeRoot -Output $verifyOutput
            Stop-Slice -Cause "$id -- tools/verify.ps1 (-Scope branch) failed; branch left untouched" -Fix "the failing check is printed above this block and saved to $verifyLog. Fix it on the branch, commit, and retry. If the only failure is the Godot compile check with 'Could not preload resource', the worktree's .godot import cache is stale and the automatic refresh could not fix it -- run python tools/godot_cache.py --force in the worktree; it is not a code fault"
        }
        Invoke-InjectedLifecycleFailure -Phase "verified"
        Write-ClosingJournal -Root $worktreeRoot -Id $id -Branch $branch -Lane $lane -Phase "verified"
    }
    else {
        Write-Output "$id -- tools/verify.ps1 (-Scope branch) already passed this closeout; skipping"
    }

    # The delivered item's own metadata (Title, Check, Plan, Heading, Next
    # after) must come from master's committed queue, not the worktree's --
    # the "refilled" phase below has the session edit that very file on the
    # branch, and by the time finish reaches it the branch's own copy may no
    # longer list this id at all.
    Set-SliceStep "hands-on check gate"
    $previousOutputEncoding = $OutputEncoding
    $previousConsoleOutputEncoding = [Console]::OutputEncoding
    try {
        $utf8 = [System.Text.UTF8Encoding]::new($false)
        $OutputEncoding = $utf8
        [Console]::OutputEncoding = $utf8
        $masterNextSteps = (git show "master:NEXTSTEPS.md" | Out-String)
    }
    finally {
        $OutputEncoding = $previousOutputEncoding
        [Console]::OutputEncoding = $previousConsoleOutputEncoding
    }
    if ($LASTEXITCODE -ne 0) { throw "could not read NEXTSTEPS.md from master" }
    $masterItems = Get-NextUpItemsFromText -Text $masterNextSteps
    $item = $masterItems | Where-Object { $_.Id -eq $id } | Select-Object -First 1
    $handsOnNote = "none needed"
    if ($item -and $item.Check -match '(?i)hands-on check') {
        $readyDirectory = Join-Path $worktreeRoot "checks\ready"
        $branchChecks = if (Test-Path -LiteralPath $readyDirectory) { Get-ChildItem -LiteralPath $readyDirectory -Filter "C-*.md" | ForEach-Object { $_.Name } } else { @() }
        $masterChecks = @(git -C $root ls-tree -r --name-only master -- checks/ready | ForEach-Object { Split-Path -Leaf $_ })
        $newEntries = @($branchChecks | Where-Object { $_ -notin $masterChecks })
        if (-not $newEntries) {
            Stop-Slice -Cause "$id -- Check: names a hands-on check but checks/ready/ gained no independently owned C-<id>.md record" -Fix "write checks/ready/C-<next free number>.md on this branch in the format plans/reference/closeout.md 'Filing a hands-on check' gives, commit, and retry"
        }
        $handsOnNote = "checks/ready/ gained $($newEntries -join ', ')"
    }
    elseif (-not $item) {
        Write-Output "$id -- no NEXTSTEPS.md entry found on master; skipping the hands-on-check gate"
    }

    Set-SliceStep "committing outstanding work on the branch"
    if (-not (Test-ClosingPhaseDone -Journal $journal -Phase "branch-committed")) {
        Save-SliceBranchWork -Root $worktreeRoot -Message "$id -- finish outstanding work`n`n$trailer"
        Invoke-InjectedLifecycleFailure -Phase "branch-committed"
        Write-ClosingJournal -Root $worktreeRoot -Id $id -Branch $branch -Lane $lane -Phase "branch-committed"
    }

    Set-SliceStep "archiving the plan section and deleting the item from the $lane lane"
    if (-not (Test-ClosingPhaseDone -Journal $journal -Phase "actions-committed")) {
        Invoke-SliceArchiveAndRefill -Root $worktreeRoot -Item $item -Id $id -Lane $lane -Trailer $trailer -PythonPath $PythonPath
        Invoke-InjectedLifecycleFailure -Phase "actions-committed"
        Write-ClosingJournal -Root $worktreeRoot -Id $id -Branch $branch -Lane $lane -Phase "actions-committed"
    }

    Set-SliceStep "archive gate (the slice's plan section must be in plans/archive/)"
    if (-not (Test-ClosingPhaseDone -Journal $journal -Phase "archived")) {
        if ($item) {
            $archive = Get-SliceArchiveState -Root $worktreeRoot -Item $item -Id $id
            if ($archive.State -eq "reused") {
                Stop-Slice -Cause "$id -- plans/archive/ has $($archive.Count) file(s) for this id, none naming '$($item.Heading)': the id is reused, so nothing there records this slice" -Fix "write this slice's own record to plans/archive/$id`_$(Get-Date -Format yyyy-MM-dd).md, including its heading text, commit it on this branch, and retry"
            }
            if ($archive.State -ne "done") {
                $archiveState = if ($archive.State -eq "missing") { "no plans/archive/$id`_*.md file exists" } else { "the heading '$($item.Heading)' is still in $($item.Plan)" }
                Stop-Slice -Cause "$id -- $archiveState" -Fix "on this branch run python tools/archive_slice.py $id (it moves the section under '$($item.Heading)' out of $($item.Plan) into plans/archive/$id`_$(Get-Date -Format yyyy-MM-dd).md and leaves a one-line pointer; it needs a clean tree, so commit first), commit, and retry"
            }
        }
        Invoke-InjectedLifecycleFailure -Phase "archived"
        Write-ClosingJournal -Root $worktreeRoot -Id $id -Branch $branch -Lane $lane -Phase "archived"
    }

    $successorId = if ($item) { Get-SuccessorId -NextAfter $item.NextAfter } else { $null }
    Set-SliceStep "refill gate (NEXTSTEPS.md's $lane lane)"
    if (-not (Test-ClosingPhaseDone -Journal $journal -Phase "refilled")) {
        if ($item) {
            $branchItems = Get-NextUpItems -Root $worktreeRoot
            if ($branchItems | Where-Object { $_.Id -eq $id }) {
                Stop-Slice -Cause "$id -- its own entry is still in NEXTSTEPS.md's ### $lane lane" -Fix "on this branch run python tools/refill_lane.py --delete $id (it removes the item from ### $lane lane and renumbers), add its successor ($($item.NextAfter)) with full Plan/Files/Check/Proof/Next after lines unless that says the plan is complete, run python tools/check_docs.py, commit, and retry"
            }
            if ($successorId -and -not ($branchItems | Where-Object { $_.Id -eq $successorId })) {
                $branchQueueText = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $worktreeRoot "NEXTSTEPS.md")
                if (-not (Test-SuccessorDeferred -Text $branchQueueText -Id $successorId)) {
                    Stop-Slice -Cause "$id -- Next after: names '$successorId', which is neither in the [$lane] lane nor under '## Not in the queue, and why'" -Fix "on this branch, either add '$successorId' to ### $lane lane with full Plan/Files/Check/Proof/Next after lines (its plan section is the source; python tools/heading.py <plan> '$successorId' prints it), or -- if it is not startable yet -- give it a one-line bullet under '## Not in the queue, and why' whose bolded lead is its id and whose line says what it waits for; then run python tools/check_docs.py, commit, and retry"
                }
            }
        }
        Invoke-InjectedLifecycleFailure -Phase "refilled"
        Write-ClosingJournal -Root $worktreeRoot -Id $id -Branch $branch -Lane $lane -Phase "refilled"
    }

    Stop-WorktreeGodot -Root $worktreeRoot

    # `finish` deletes the worktree it is run from, so it must not depend
    # on returning to it. Push-Location left that path on the location
    # stack and the matching Pop-Location threw once the directory was
    # gone -- and, sitting in a `finally`, replaced whatever real error was
    # propagating, so a failed ledger commit surfaced as a path error.
    Set-Location -LiteralPath $root
    Set-SliceStep "primary checkout checks"
    $primaryBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($primaryBranch -ne "master") {
        Stop-Slice -Cause "primary checkout is on '$primaryBranch', not master" -Fix "in the primary checkout run git switch master (commit or stash-by-WIP-commit anything there first), then retry"
    }

    # plans/workstreams.md and checks/ready.md are written by the lifecycle
    # itself (Get-LifecycleProducts), from the primary checkout, never from a
    # branch. An uncommitted edit already sitting there -- a stray hand edit,
    # or another lane's `start`/`finish` caught mid-write -- must not be
    # silently folded into this merge or silently discarded by it.
    $dirtyCoordination = @(git -C $root status --porcelain --untracked-files=no -- (Get-LifecycleProducts) |
        ForEach-Object { $_.ToString() })
    if ($dirtyCoordination) {
        $dirtyFiles = @($dirtyCoordination | ForEach-Object { $_.Substring(3).Trim() } | Select-Object -Unique)
        Stop-Slice -Cause "$id -- the primary checkout has uncommitted changes to $($dirtyFiles -join ', ')" -Fix "in the primary checkout, git diff those files: commit them if they are a deliberate edit, or git checkout -- them if they are a stray one, then retry"
    }

    Set-SliceStep "primary verification (tools/verify.ps1 -Scope primary)"
    $primaryVerifyScript = Join-Path $root "tools\verify.ps1"
    $primaryVerifyCmd = Get-Command $primaryVerifyScript
    $primaryVerifyArgs = @{}
    if ($primaryVerifyCmd.Parameters.ContainsKey("PythonPath") -and $PythonPath) {
        $primaryVerifyArgs["PythonPath"] = $PythonPath
    }
    if ($primaryVerifyCmd.Parameters.ContainsKey("Scope")) {
        $primaryVerifyArgs["Scope"] = "primary"
    }
    try {
        $primaryVerifyOutput = & $primaryVerifyScript @primaryVerifyArgs 2>&1
        $primaryVerifyExit = $LASTEXITCODE
    }
    catch {
        $primaryVerifyOutput = $_ | Out-String
        $primaryVerifyExit = 1
    }
    $primaryVerifyOutput | ForEach-Object { Write-Output $_ }
    if ($primaryVerifyExit -ne 0) {
        $verifyLog = Save-VerifyLog -Root $root -Output $primaryVerifyOutput
        Stop-Slice -Cause "$id -- tools/verify.ps1 (-Scope primary) failed; branch left untouched" -Fix "the failing check is printed above and saved to $verifyLog; it ran against the primary checkout, so a failure the branch did not show usually means master moved -- fix it on master or the branch, commit, and retry"
    }

    Set-SliceStep "merging into master"
    $title = if ($item) { $item.Title } else { $branch }
    $preMergeSha = (git -C $root rev-parse HEAD).Trim()
    if (-not (Test-SliceBranchMerged -Root $root -Branch $branch)) {
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
    }
    Invoke-InjectedLifecycleFailure -Phase "merged"
    Write-ClosingJournal -Root $root -Id $id -Branch $branch -Lane $lane -Phase "merged"

    $target = [PSCustomObject]@{
        Id = $id; Lane = $lane; Branch = $branch
        WorktreeRelative = $worktreeRelative; WorktreePath = (Join-Path $root $worktreeRelative)
    }
    Set-SliceStep "post-merge cleanup (ready-check index, worktree, branch, ledger row, push)"
    Invoke-SlicePostMergeCleanup -Root $root -Target $target -PythonPath $PythonPath
    Remove-ClosingJournal -Root $root
    Set-SliceStep "printing the report (the merge and cleanup are done)"

    # Both lookups below read master's NEXTSTEPS.md as the merge just left
    # it: the delivered item gone, its successor (if any) promoted. That is
    # what turns "Next slice" and "Other lane" into lookups instead of a
    # session having to open the file and work it out by hand.
    $mergedNextSteps = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "NEXTSTEPS.md")
    $mergedItems = Get-NextUpItemsFromText -Text $mergedNextSteps

    $laneLead = $mergedItems | Where-Object { $_.Lane -eq $lane } | Sort-Object ItemNumber | Select-Object -First 1

    $nextSliceLine = "see 'Next after:' on the item above, or the owning plan in plans/now/"
    if ($item -and -not $successorId) {
        $nextSliceLine = $item.NextAfter
    }
    elseif ($successorId) {
        $successorItem = $mergedItems | Where-Object { $_.Id -eq $successorId -and $_.Lane -eq $lane } | Select-Object -First 1
        $deferralReason = if ($successorItem) { $null } else { Get-SuccessorDeferralReason -Text $mergedNextSteps -Id $successorId }
        if ($successorItem) {
            $nextSliceLine = "$($successorItem.Id) -- $($successorItem.Title)"
        }
        elseif ($null -ne $deferralReason) {
            # The refill gate accepted a deferred successor (L-13 -> L-12 on
            # 19 Sep 2026), so the next slice is simply the lane's new lead.
            $deferralNote = "$successorId is deferred"
            if ($deferralReason) { $deferralNote += ": $deferralReason" }
            $nextSliceLine = if ($laneLead) { "$($laneLead.Id) -- $($laneLead.Title)  ($deferralNote)" } else { "none -- the $lane lane is empty ($deferralNote)" }
        }
        else {
            $nextSliceLine = "$successorId -- (not found in NEXTSTEPS.md; check the refill)"
        }
    }
    $queueLine = if ($laneLead) { "$lane lane now leads with $($laneLead.Id) -- $($laneLead.Title)" } else { "$lane lane is empty -- refill it from an owning plan" }
    $adviceLine = "none -- the $lane lane is empty"
    $connectorLine = "none needed"
    if ($laneLead) {
        $advice = Get-SliceAdvice -Root $root -Candidate $laneLead -Lane $lane
        $adviceLine = "$($advice.model) (plan level: $($advice.level))"
        $connectorLine = if ($advice.connectors_on.Count -gt 0) { "on: $($advice.connectors_on -join ', '); off: $($advice.connectors_off)" } else { "on: none; off: $($advice.connectors_off)" }
    }

    $otherLead = $mergedItems | Where-Object { $_.Lane -eq $otherLane } | Sort-Object ItemNumber | Select-Object -First 1
    $otherLaneLine = if ($otherLead) { "$($otherLead.Id) -- $($otherLead.Title), untouched by this merge" } else { "no [$otherLane] item in the queue -- check NEXTSTEPS.md" }

    $startLine = Get-CopyPastePromptLine -Text $mergedNextSteps -Lane $lane
    if (-not $startLine) { $startLine = "tools/slice.ps1 start -Lane $lane" }

    Write-Diagnostic -Root $root -Kind "slice_finished" -Fields @{
        id     = $id
        lane   = $lane
        branch = $branch
        ok     = $true
        ms     = [int]$script:SliceStopwatch.ElapsedMilliseconds
    }

    Write-Output ""
    Write-Output "Slice landed: $id -- $title"
    Write-Output "Branch:       $branch  |  verify.ps1: green"
    Write-Output "Merged:       yes, to master now"
    Write-Output "Hands-on:     $handsOnNote"
    Write-Output "Queue:        $queueLine"
    Write-Output "Next slice:   $nextSliceLine"
    Write-Output "Next model:   $adviceLine"
    Write-Output "Connectors:   active now: <the session fills this in from its own tool list>"
    Write-Output "Toggle:       $connectorLine"
    Write-Output "Other lane:   $otherLaneLine"
    Write-Output "Start it with: $startLine"
    Write-Output ""
    Write-Output "Diffstat:"
    git -C $root diff --stat $preMergeSha master | ForEach-Object { Write-Output $_ }
}

try {
switch ($Command) {
    "start"  { $root = Get-PrimaryRoot; Remove-PendingWorktreeDirectories -Root $root; Invoke-WithLifecycleLock -Root $root { Invoke-SliceStart -Lane $Lane } }
    "finish" { $root = Get-PrimaryRoot; Remove-PendingWorktreeDirectories -Root $root; Invoke-WithLifecycleLock -Root $root { Invoke-SliceFinish -PythonPath $PythonPath } }
    "doctor" { Invoke-SliceDoctor -Lane $Lane -PythonPath $PythonPath }
    "status" { Invoke-SliceStatus -Lane $Lane }
    "resume" { $root = Get-PrimaryRoot; Remove-PendingWorktreeDirectories -Root $root; Invoke-WithLifecycleLock -Root $root { Invoke-SliceResume -Lane $Lane -PythonPath $PythonPath } }
    "abort"  { $root = Get-PrimaryRoot; Invoke-WithLifecycleLock -Root $root { Invoke-SliceAbort -Lane $Lane } }
    "owner"  { Invoke-SliceOwner -Wanted $Path }
}
}
catch {
    Write-SliceFailure -Record $_
    exit 1
}
