<#
    create_repo.ps1 - one-time helper to create the private GitHub repo
                      juwpegatron/diary.

    Flow:
      1. git credential fill (non-interactive) -> read stored GitHub token.
      2. POST https://api.github.com/user/repos with the token.
      3. On success (201) or "already exists" (422), set the 'origin' remote.

    The token is NEVER printed, logged, or written to disk. It is used only in
    the Authorization header of the API request.
#>

# --- Configuration -----------------------------------------------------------
$GitExe  = 'C:\Users\juwen_lie\AppData\Local\Programs\Git\cmd\git.exe'
$RepoUrl = 'https://github.com/juwpegatron/diary.git'
$RepoName = 'diary'
$BodyJson = '{"name":"diary","private":true,"description":"Auto-generated productivity diary","has_issues":false}'
# -----------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $GitExe)) {
    Write-Error "git.exe not found at '$GitExe'. Update `$GitExe in create_repo.ps1."
    exit 1
}

# Always work from the script's own directory so the remote is set here.
Set-Location -LiteralPath $PSScriptRoot

# 1. Try to read the stored credential non-interactively.
$env:GIT_TERMINAL_PROMPT = '0'
$credInput = "protocol=https`nhost=github.com`n`n"
$credRaw = $credInput | & $GitExe credential fill 2>$null

$token = $null
foreach ($line in @($credRaw)) {
    if ($line -match '^password=(.+)$') {
        $token = $Matches[1]
    }
}

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host ''
    Write-Host 'Could not obtain a stored GitHub token via "git credential fill".'
    Write-Host ''
    Write-Host 'Fallback: create the empty repository once on github.com, then publish:'
    Write-Host '  1. Go to https://github.com/new'
    Write-Host "  2. Name it '$RepoName', set it to Private, and DO NOT add a README."
    Write-Host '  3. Run publish.ps1 - it will push the diary to the new empty repo.'
    exit 1
}

# 2. Create the repo via the GitHub API (token used ONLY in the header).
$respRaw = & curl.exe -s -w "`nHTTPSTATUS:%{http_code}" `
    -X POST 'https://api.github.com/user/repos' `
    -H "Authorization: Bearer $token" `
    -H 'Accept: application/vnd.github+json' `
    -H 'User-Agent: productivity-diary' `
    -d $BodyJson

$respText = (@($respRaw) -join "`n")
$status = $null
if ($respText -match 'HTTPSTATUS:(\d+)') {
    $status = [int]$Matches[1]
}

if ($status -eq 201) {
    Write-Host "Created GitHub repository '$RepoName'."
}
elseif ($status -eq 422) {
    Write-Host "Repository '$RepoName' already exists - treating as success."
}
else {
    Write-Error "Failed to create repository (HTTP status: $status). See the message above."
    exit 1
}

# 3. Ensure the local repo exists and point 'origin' at the new remote.
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot '.git'))) {
    & $GitExe init -b main
}

$remotes = @(& $GitExe remote)
if ($remotes -contains 'origin') {
    & $GitExe remote set-url origin $RepoUrl
}
else {
    & $GitExe remote add origin $RepoUrl
}

Write-Host ''
Write-Host "Remote 'origin' set to $RepoUrl"
Write-Host 'Run publish.ps1 to push the first commit.'
