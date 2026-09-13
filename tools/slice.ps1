[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("start", "finish", "doctor", "status", "resume", "abort")]
    [string]$Command,

    [ValidateSet("Claude", "Codex")]
    [string]$Lane,

    [string]$PythonPath
)

$ErrorActionPreference = "Stop"

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

function Invoke-WithLifecycleLock {
    param([string]$Root, [scriptblock]$Action)

    $commonDir = (git -C $Root rev-parse --git-common-dir).Trim()
    if (-not [System.IO.Path]::IsPathRooted($commonDir)) { $commonDir = Join-Path $Root $commonDir }
    $lockPath = Join-Path $commonDir "meadow-slice-lifecycle.lock"
    $stream = $null
    try {
        try {
            # OpenOrCreate makes a lock left behind by a killed PowerShell
            # process recoverable: the OS releases its exclusive handle, so a
            # later lifecycle command can take that same file. CreateNew
            # instead made the stale name itself a permanent manual-repair
            # problem.
            $stream = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        }
        catch [System.IO.IOException] {
            throw "slice lifecycle is busy; retry this command after the other lifecycle command completes"
        }
        & $Action
    }
    finally {
        if ($stream) { $stream.Dispose(); Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue }
    }
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
    if (-not (Test-Path -LiteralPath $path)) {
        return "absent ($source): $path -- nothing to read; no action needed unless you want a personal ignore file there"
    }
    try {
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

function Invoke-SliceDoctor {
    param(
        [string]$Lane,
        [string]$PythonPath
    )

    $root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    Remove-PendingWorktreeDirectories -Root $root
    $failures = @(Get-DoctorEnvironmentFailures -Root $root -RequestedPythonPath $PythonPath)

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
        branch       = $preflight.Branch
        worktree     = $preflight.WorktreeRelative
        git_excludes = Get-GlobalExcludesDiagnostic
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
        branch     = $branch
        worktree   = $worktreeRelative
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
    param([string]$Root, [object]$Target)
    $ledgerPath = Join-Path $Root "plans\workstreams.md"
    $marker = '`' + $Target.WorktreeRelative + '`'
    $lines = @(Get-Content -LiteralPath $ledgerPath)
    $keep = @($lines | Where-Object { $_.IndexOf($marker, [System.StringComparison]::Ordinal) -lt 0 })
    if ($keep.Count -eq $lines.Count) { return $false }
    Set-Content -LiteralPath $ledgerPath -Value $keep
    git -C $Root add "plans/workstreams.md"
    if ($LASTEXITCODE -ne 0) { throw "git add failed" }
    git -C $Root commit -m "Remove the $($Target.Id) worktree row from the ledger`n`n$(Get-LaneTrailer -Lane $Target.Lane)" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
    git -c http.sslBackend=openssl -C $Root push
    if ($LASTEXITCODE -ne 0) { throw "git push failed" }
    return $true
}

function Invoke-SlicePostMergeCleanup {
    param([string]$Root, [object]$Target)
    if (Test-Path -LiteralPath $Target.WorktreePath) {
        git -C $Root worktree remove --force $Target.WorktreeRelative 2>$null
        if ($LASTEXITCODE -ne 0 -and (Test-Path -LiteralPath $Target.WorktreePath)) {
            Remove-Item -LiteralPath $Target.WorktreePath -Recurse -Force
        }
        git -C $Root worktree prune
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
    git -c http.sslBackend=openssl -C $Root ls-remote --exit-code --heads origin $Target.Branch | Out-Null
    if ($LASTEXITCODE -eq 0) {
        git -c http.sslBackend=openssl -C $Root push origin --delete $Target.Branch
        if ($LASTEXITCODE -ne 0) { throw "git push origin --delete failed" }
    }
    $removed = Remove-SliceLedgerRow -Root $Root -Target $Target
    if ($removed) { Invoke-InjectedLifecycleFailure -Phase "ledger-deleted" }
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
    $states | ConvertTo-Json -Compress
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
        Invoke-SlicePostMergeCleanup -Root $root -Target $target
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

function Invoke-SliceFinish {
    param([string]$PythonPath)

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
    if ($PythonPath -and $verifyCmd.Parameters.ContainsKey("PythonPath")) {
        $verifyArgs["PythonPath"] = $PythonPath
    }
    if ($verifyCmd.Parameters.ContainsKey("Scope")) {
        $verifyArgs["Scope"] = "branch"
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
        Write-Error "$id -- tools/verify.ps1 (-Scope branch) failed; branch left untouched"
        exit 1
    }
    Invoke-InjectedLifecycleFailure -Phase "verified"

    $items = Get-NextUpItems -Root $worktreeRoot
    $item = $items | Where-Object { $_.Id -eq $id } | Select-Object -First 1
    $handsOnNote = "none needed"
    if ($item -and $item.Check -match '(?i)hands-on check') {
        $readyDirectory = Join-Path $worktreeRoot "checks\ready"
        $branchChecks = if (Test-Path -LiteralPath $readyDirectory) { Get-ChildItem -LiteralPath $readyDirectory -Filter "C-*.md" | ForEach-Object { $_.Name } } else { @() }
        $masterChecks = @(git -C $root ls-tree -r --name-only master -- checks/ready | ForEach-Object { Split-Path -Leaf $_ })
        $newEntries = @($branchChecks | Where-Object { $_ -notin $masterChecks })
        if (-not $newEntries) {
            Write-Error "$id -- Check: names a hands-on check but checks/ready/ gained no independently owned C-<id>.md record -- file it before finishing"
            exit 1
        }
        $handsOnNote = "checks/ready/ gained $($newEntries -join ', ')"
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
    Invoke-InjectedLifecycleFailure -Phase "branch-committed"

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
        Write-Error "$id -- tools/verify.ps1 (-Scope primary) failed; branch left untouched"
        exit 1
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
    Invoke-InjectedLifecycleFailure -Phase "merged"

    # The ready-check page is a shared index, deliberately generated only in
    # the primary checkout once the feature branch has landed. This keeps
    # parallel branches from appending to the same Markdown file.
    $indexGenerator = Join-Path $root "tools\check_docs.py"
    $python = if ($PythonPath) { $PythonPath } else { & $verifyScript -ResolvePythonOnly }
    if (-not $python -or -not (Test-Path -LiteralPath $python -PathType Leaf)) {
        throw "could not resolve Python for the ready-check index"
    }
    & $python $indexGenerator --write-ready-index
    if ($LASTEXITCODE -ne 0) { throw "could not regenerate checks/ready.md" }
    git add -- checks/ready.md
    $indexStaged = git diff --cached --name-only
    if ($indexStaged) {
        $indexMessage = "$id -- refresh ready-check index`n`n$trailer"
        git commit -m $indexMessage | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "git commit failed while refreshing ready-check index" }
    }

    git -c http.sslBackend=openssl push
    if ($LASTEXITCODE -ne 0) { throw "git push failed" }
    Invoke-InjectedLifecycleFailure -Phase "pushed"

    $worktreePath = Join-Path $root $worktreeRelative
    git worktree remove $worktreeRelative
    if ($LASTEXITCODE -ne 0) {
        # `git worktree remove` can deregister the worktree and still fail to
        # delete the directory (an external process briefly holding it open --
        # OneDrive and the Search Indexer both do this on a freshly emptied
        # folder, same as a running Godot instance can). Prune git's own
        # records regardless -- they are correct even when the directory
        # lags -- and queue the directory for a later slice command to
        # retry, rather than holding the lifecycle lock while we wait.
        git worktree prune
        if (Test-Path -LiteralPath $worktreePath) {
            Add-PendingWorktreeDeletion -Root $root -WorktreeRelative $worktreeRelative
            Write-Output "$id -- $worktreeRelative could not be deleted; queued in pending deletions for retry at the next slice command"
        }
    }
    Invoke-InjectedLifecycleFailure -Phase "worktree-removed"

    # This branch was just merged with --no-ff above. Use the same local
    # merge-based cleanup as resume, without requiring a remote branch that a
    # slice intentionally never pushed.
    git branch -D $branch
    if ($LASTEXITCODE -ne 0) { throw "git branch cleanup failed" }
    Invoke-InjectedLifecycleFailure -Phase "branch-deleted"

    git -c http.sslBackend=openssl ls-remote --exit-code --heads origin $branch | Out-Null
    if ($LASTEXITCODE -eq 0) {
        git -c http.sslBackend=openssl push origin --delete $branch
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

        git -c http.sslBackend=openssl push
        if ($LASTEXITCODE -ne 0) { throw "git push failed" }
        Invoke-InjectedLifecycleFailure -Phase "ledger-deleted"
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
    "start"  { $root = Get-PrimaryRoot; Remove-PendingWorktreeDirectories -Root $root; Invoke-WithLifecycleLock -Root $root { Invoke-SliceStart -Lane $Lane } }
    "finish" { $root = Get-PrimaryRoot; Remove-PendingWorktreeDirectories -Root $root; Invoke-WithLifecycleLock -Root $root { Invoke-SliceFinish -PythonPath $PythonPath } }
    "doctor" { Invoke-SliceDoctor -Lane $Lane -PythonPath $PythonPath }
    "status" { Invoke-SliceStatus -Lane $Lane }
    "resume" { $root = Get-PrimaryRoot; Remove-PendingWorktreeDirectories -Root $root; Invoke-WithLifecycleLock -Root $root { Invoke-SliceResume -Lane $Lane -PythonPath $PythonPath } }
    "abort"  { $root = Get-PrimaryRoot; Invoke-WithLifecycleLock -Root $root { Invoke-SliceAbort -Lane $Lane } }
}
