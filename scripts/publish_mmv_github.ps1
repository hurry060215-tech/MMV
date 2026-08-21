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
$script:SavedProxyEnv = @{}

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

function Clear-ProxyEnvForGit {
  $proxyVars = @("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "GIT_HTTP_PROXY", "GIT_HTTPS_PROXY")
  foreach ($k in $proxyVars) {
    $val = [System.Environment]::GetEnvironmentVariable($k, "Process")
    if ($null -ne $val -and $val -ne "") {
      $script:SavedProxyEnv[$k] = $val
      [System.Environment]::SetEnvironmentVariable($k, $null, "Process")
    }
  }
}

function Restore-ProxyEnv {
  foreach ($k in $script:SavedProxyEnv.Keys) {
    [System.Environment]::SetEnvironmentVariable($k, $script:SavedProxyEnv[$k], "Process")
  }
}

function Invoke-GitOutput {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Args
  )

  $oldEap = $ErrorActionPreference
  try {
    $ErrorActionPreference = "Continue"
    $allArgs = @()
    if ($script:GitPrefix.Count -gt 0) {
      $allArgs += $script:GitPrefix
    }
    $allArgs += $Args
    $out = & git @allArgs 2>$null
    return ,$out
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
  throw (
    "The current .git metadata is invalid. MMV will not delete or recreate " +
    "repository metadata. Run scripts/publish_mmv_from_temp.ps1 instead."
  )
}

Clear-ProxyEnvForGit
try {
  if (-not (Test-IsValidGitRepo)) {
    Reset-BrokenGitRepo
  }

  if (-not (Test-IsValidGitRepo)) {
    throw "Repository is still invalid after reinitialization."
  }

  $currentBranch = (Invoke-GitOutput -Args @("branch", "--show-current")) -join ""
  if (-not $currentBranch -or $currentBranch -ne $Branch) {
    throw "Current branch is '$currentBranch'; expected '$Branch'. Switch branches explicitly before publishing."
  }

  Invoke-Git -Args @(
    "add", "--", ".github", ".gitignore", "DESCRIPTION", "LICENSE",
    "LICENSE.md", "NEWS.md", "NAMESPACE", "R", "README.md", "_pkgdown.yml",
    "inst", "man", "scripts", "tests"
  ) | Out-Null

  $diffCode = Invoke-Git -Args @("diff", "--cached", "--quiet") -Quiet -AllowFailure
  if ($diffCode -eq 0) {
    Write-Host "No changes to commit. Repository is already up to date."
    return
  }

  $hasCommit = $false
  $headCode = Invoke-Git -Args @("rev-parse", "--verify", "HEAD") -Quiet -AllowFailure
  if ($headCode -eq 0) {
    $hasCommit = $true
  }

  if (-not $hasCommit) {
    Invoke-Git -Args @("commit", "-m", "feat: initial MMV release (R-first watermaze/minefield visualization)") | Out-Null
  } else {
    Invoke-Git -Args @("commit", "-m", "chore: update MMV package") | Out-Null
  }

  $originUrl = "https://github.com/$RepoOwner/$RepoName.git"
  $hasOrigin = $false
  try {
    $code = Invoke-Git -Args @("remote", "get-url", "origin") -Quiet -AllowFailure
    $existingOrigin = $null
    if ($code -eq 0) {
      $existingOrigin = (Invoke-GitOutput -Args @("remote", "get-url", "origin")) -join ""
    }
    if ($existingOrigin) { $hasOrigin = $true }
  } catch {
    $hasOrigin = $false
  }

  if (-not $hasOrigin) {
    Invoke-Git -Args @("remote", "add", "origin", $originUrl) | Out-Null
  } else {
    $allowedOrigins = @($originUrl, "git@github.com:$RepoOwner/$RepoName.git")
    if ($existingOrigin -notin $allowedOrigins) {
      throw "Existing origin '$existingOrigin' does not match $RepoOwner/$RepoName. Refusing to rewrite it."
    }
  }

  # Force no proxy and HTTP/1.1 for flaky networks.
  $pushCode = Invoke-Git -Args @("-c", "http.proxy=", "-c", "https.proxy=", "-c", "http.version=HTTP/1.1", "push", "-u", "origin", $Branch) -AllowFailure
  if ($pushCode -ne 0) {
    Start-Sleep -Seconds 2
    $pushCode = Invoke-Git -Args @("-c", "http.proxy=", "-c", "https.proxy=", "-c", "http.version=HTTP/1.1", "push", "-u", "origin", $Branch) -AllowFailure
    if ($pushCode -ne 0) {
      Write-Host "Default push failed twice. Retrying with OpenSSL backend..."
      $pushCode = Invoke-Git -Args @("-c", "http.proxy=", "-c", "https.proxy=", "-c", "http.version=HTTP/1.1", "-c", "http.sslbackend=openssl", "push", "-u", "origin", $Branch) -AllowFailure
      if ($pushCode -ne 0) {
        throw "git push failed after retry. Check network access/credentials for github.com."
      }
    }
  }

  Write-Host "Pushed to $originUrl (branch: $Branch)"
} finally {
  Restore-ProxyEnv
}
