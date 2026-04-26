param(
  [string]$RepoOwner = "hurry060215-tech",
  [string]$RepoName = "MMV",
  [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

$script:GitPrefix = @()
$script:AltGitDir = "mmv_gitdata"

function Invoke-Git {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Args,
    [switch]$Quiet,
    [switch]$AllowFailure
  )

  $oldEap = $ErrorActionPreference
  try {
    $ErrorActionPreference = "Continue"
    $allArgs = @()
    if ($script:GitPrefix.Count -gt 0) {
      $allArgs += $script:GitPrefix
    }
    $allArgs += $Args

    if ($Quiet) {
      & git @allArgs *> $null
    } else {
      & git @allArgs
    }
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $oldEap
  }

  if (-not $AllowFailure -and $exitCode -ne 0) {
    throw "git $($Args -join ' ') failed with exit code $exitCode."
  }
  return $exitCode
}

function Invoke-CmdQuiet {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Command
  )

  $oldEap = $ErrorActionPreference
  try {
    $ErrorActionPreference = "SilentlyContinue"
    cmd /c $Command *> $null
    return $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $oldEap
  }
}

function Test-IsValidGitRepo {
  if ($script:GitPrefix.Count -gt 0) {
    $code = Invoke-Git -Args @("rev-parse", "--is-inside-work-tree") -Quiet -AllowFailure
    return ($code -eq 0)
  }
  if (-not (Test-Path ".git")) {
    return $false
  }
  $code = Invoke-Git -Args @("rev-parse", "--is-inside-work-tree") -Quiet -AllowFailure
  return ($code -eq 0)
}

function Init-AltGitRepo {
  $script:GitPrefix = @("--git-dir=$($script:AltGitDir)", "--work-tree=.")

  # Try normal init first.
  $initCode = Invoke-Git -Args @("init", "-b", $Branch) -Quiet -AllowFailure
  if ($initCode -eq 0) {
    return
  }

  # Manual bootstrap fallback for environments where git init cannot write config directly.
  New-Item -ItemType Directory -Force -Path "$($script:AltGitDir)\objects\info" | Out-Null
  New-Item -ItemType Directory -Force -Path "$($script:AltGitDir)\objects\pack" | Out-Null
  New-Item -ItemType Directory -Force -Path "$($script:AltGitDir)\refs\heads" | Out-Null
  New-Item -ItemType Directory -Force -Path "$($script:AltGitDir)\refs\tags" | Out-Null
  New-Item -ItemType Directory -Force -Path "$($script:AltGitDir)\hooks" | Out-Null
  New-Item -ItemType Directory -Force -Path "$($script:AltGitDir)\info" | Out-Null

  Set-Content -Path "$($script:AltGitDir)\config" -Value "[core]`n`trepositoryformatversion = 0`n`tfilemode = false`n`tbare = false`n`tlogallrefupdates = true`n" -NoNewline
  Set-Content -Path "$($script:AltGitDir)\HEAD" -Value "ref: refs/heads/$Branch`n" -NoNewline
}

function Ensure-GitIgnoreRule {
  param([string]$Rule)
  if (-not (Test-Path ".gitignore")) {
    Set-Content -Path ".gitignore" -Value "$Rule`n"
    return
  }
  $txt = Get-Content ".gitignore" -Raw
  $escapedRule = [regex]::Escape($Rule)
  if ($txt -notmatch "(?m)^$escapedRule$") {
    Add-Content ".gitignore" "`n$Rule"
  }
}

function Reset-BrokenGitRepo {
  if (Test-Path ".git") {
    Write-Host "Found broken .git metadata. Recreating repository..."
    Invoke-CmdQuiet -Command "attrib -h -s .git" | Out-Null
    Invoke-CmdQuiet -Command "attrib -h -s .git\* /s /d" | Out-Null
    Invoke-CmdQuiet -Command "del /f /q .git\config.lock" | Out-Null
    Remove-Item -LiteralPath ".git" -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path ".git") {
      Invoke-CmdQuiet -Command "rmdir /s /q .git" | Out-Null
    }
  }
  if (Test-Path ".git") {
    Write-Host "Unable to remove broken .git folder. Using alternate metadata directory $($script:AltGitDir)."
    Init-AltGitRepo
    Ensure-GitIgnoreRule -Rule "$($script:AltGitDir)/"
    return
  }
  $script:GitPrefix = @()
  $initCode = Invoke-Git -Args @("init", "-b", $Branch) -Quiet -AllowFailure
  if ($initCode -ne 0) {
    Write-Host "Default git init failed. Using alternate metadata directory $($script:AltGitDir)."
    Init-AltGitRepo
    Ensure-GitIgnoreRule -Rule "$($script:AltGitDir)/"
  }
}

if (-not (Test-IsValidGitRepo)) {
  Reset-BrokenGitRepo
}

if (-not (Test-IsValidGitRepo)) {
  throw "Repository is still invalid after reinitialization."
}

Invoke-Git -Args @("add", ".github", ".gitignore", "DESCRIPTION", "LICENSE", "NAMESPACE", "R", "README.md", "_pkgdown.yml", "inst", "scripts", "tests") | Out-Null

$hasCommit = $false
$headCode = Invoke-Git -Args @("rev-parse", "--verify", "HEAD") -Quiet -AllowFailure
if ($headCode -eq 0) {
  $hasCommit = $true
}

if (-not $hasCommit) {
  Invoke-Git -Args @("commit", "-m", "feat: initial MMV release (R-first watermaze/minefield visualization)") | Out-Null
} else {
  Invoke-Git -Args @("commit", "-m", "chore: update MMV package", "--allow-empty") | Out-Null
}

$originUrl = "https://github.com/$RepoOwner/$RepoName.git"
$hasOrigin = $false
try {
  $code = Invoke-Git -Args @("remote", "get-url", "origin") -Quiet -AllowFailure
  $existingOrigin = $null
  if ($code -eq 0) {
    $existingOrigin = (& git remote get-url origin 2>$null)
  }
  if ($existingOrigin) { $hasOrigin = $true }
} catch {
  $hasOrigin = $false
}

if (-not $hasOrigin) {
  Invoke-Git -Args @("remote", "add", "origin", $originUrl) | Out-Null
} else {
  Invoke-Git -Args @("remote", "set-url", "origin", $originUrl) | Out-Null
}

Invoke-Git -Args @("push", "-u", "origin", $Branch)

Write-Host "Pushed to $originUrl (branch: $Branch)"
