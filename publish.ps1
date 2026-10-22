<#
    publish.ps1 - commit and push the productivity diary.

    Uses the full path to git because git is NOT on PATH on this machine.
    Authentication is handled by the existing Git Credential Manager - no token
    is stored in or printed by this script.
#>

# --- Configuration -----------------------------------------------------------
$GitExe  = 'C:\Users\juwen_lie\AppData\Local\Programs\Git\cmd\git.exe'
$RepoUrl = 'https://github.com/juwpegatron/productivity-diary.git'
$Branch  = 'main'
# -----------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $GitExe)) {
    Write-Error "git.exe not found at '$GitExe'. Update `$GitExe in publish.ps1."
    exit 1
}

# Always work from the script's own directory.
Set-Location -LiteralPath $PSScriptRoot

# 1. Initialise the repo if it does not exist yet.
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot '.git'))) {
    Write-Host 'No .git found - initialising repository...'
    & $GitExe init -b $Branch
}

# 2. Ensure the 'origin' remote points at the diary repo.
$remotes = @(& $GitExe remote)
if ($remotes -notcontains 'origin') {
    Write-Host "Adding remote 'origin' -> $RepoUrl"
    & $GitExe remote add origin $RepoUrl
    Write-Host 'If the GitHub repository does not exist yet, run create_repo.ps1 first.'
}
else {
    $current = (& $GitExe remote get-url origin).Trim()
    if ($current -ne $RepoUrl) {
        Write-Host "Updating remote 'origin': $current -> $RepoUrl"
        & $GitExe remote set-url origin $RepoUrl
    }
}

# 3. Stage everything.
& $GitExe add -A

# 4. Commit only if there is something to commit.
& $GitExe diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host 'Nothing to commit - working tree clean.'
}
else {
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
    & $GitExe commit -m "diary: update $stamp"
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'Commit failed.'
        exit 1
    }
}

# 5. Push.
& $GitExe push -u origin $Branch
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'Push failed. If the GitHub repository does not exist yet,'
    Write-Host 'run create_repo.ps1 (or create an empty repo on github.com),'
    Write-Host 'then run publish.ps1 again.'
    exit 1
}

Write-Host 'Published successfully.'
