param(
  [string]$RepoOwner = "hurry060215-tech",
  [string]$RepoName = "MMV",
  [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

function Clear-ProxyEnvForGit {
  $proxyVars = @("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "GIT_HTTP_PROXY", "GIT_HTTPS_PROXY")
  foreach ($k in $proxyVars) {
    [System.Environment]::SetEnvironmentVariable($k, $null, "Process")
  }
}

function Invoke-GitStrict {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Args
  )
  & git @Args
  if ($LASTEXITCODE -ne 0) {
    throw "git $($Args -join ' ') failed with exit code $LASTEXITCODE."
  }
}

function Try-Git {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Args
  )
  & git @Args *> $null
  return $LASTEXITCODE
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tempRoot = Join-Path $env:TEMP "MMV_publish_$stamp"
$originUrl = "https://github.com/$RepoOwner/$RepoName.git"

Clear-ProxyEnvForGit

Write-Host "Cloning remote repo to temp path..."
$cloneOk = $false
$cloneCode = Try-Git -Args @("-c", "http.proxy=", "-c", "https.proxy=", "-c", "http.version=HTTP/1.1", "clone", $originUrl, $tempRoot)
if ($cloneCode -ne 0) {
  Write-Host "Default clone failed. Retrying with OpenSSL backend..."
  $cloneCode = Try-Git -Args @("-c", "http.proxy=", "-c", "https.proxy=", "-c", "http.version=HTTP/1.1", "-c", "http.sslbackend=openssl", "clone", $originUrl, $tempRoot)
}
if ($cloneCode -eq 0 -and (Test-Path (Join-Path $tempRoot ".git"))) {
  $cloneOk = $true
}
if (-not $cloneOk) {
  throw "git clone failed after retry."
}

Set-Location $tempRoot

# Ensure target branch exists locally.
$checkoutCode = Try-Git -Args @("checkout", $Branch)
if ($checkoutCode -ne 0) {
  # Try to align/reset local branch to remote branch first.
  $trackCode = Try-Git -Args @("checkout", "-B", $Branch, "origin/$Branch")
  if ($trackCode -ne 0) {
    Invoke-GitStrict -Args @("checkout", "-B", $Branch)
  }
}

Write-Host "Syncing local project files into temp clone..."
$copyResult = robocopy $projectRoot $tempRoot /E /XD .git .mmv_git mmv_gitdata outputs .abc /XF Rplots.pdf /NFL /NDL /NJH /NJS /NC /NS /NP
if ($LASTEXITCODE -ge 8) {
  throw "robocopy failed with exit code $LASTEXITCODE."
}

# Clean up git metadata fallback folders if copied/left.
if (Test-Path ".mmv_git") { Remove-Item -LiteralPath ".mmv_git" -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path "mmv_gitdata") { Remove-Item -LiteralPath "mmv_gitdata" -Recurse -Force -ErrorAction SilentlyContinue }

Invoke-GitStrict -Args @("add", ".")

$hasStaged = ((Try-Git -Args @("diff", "--cached", "--quiet")) -ne 0)
if (-not $hasStaged) {
  Write-Host "No changes to commit. Repository is already up to date."
  Write-Host "Temp repo: $tempRoot"
  exit 0
}

Invoke-GitStrict -Args @("commit", "-m", "chore: update MMV docs/examples and publish scripts")

Write-Host "Pushing to origin..."
$pushCode = Try-Git -Args @("-c", "http.proxy=", "-c", "https.proxy=", "-c", "http.version=HTTP/1.1", "push", "origin", $Branch)
if ($pushCode -ne 0) {
  Write-Host "Default push failed. Retrying with OpenSSL backend..."
  $pushCode = Try-Git -Args @("-c", "http.proxy=", "-c", "https.proxy=", "-c", "http.version=HTTP/1.1", "-c", "http.sslbackend=openssl", "push", "origin", $Branch)
}
if ($pushCode -ne 0) {
  throw "git push failed after retry."
}

Write-Host "Pushed successfully: $originUrl ($Branch)"
Write-Host "Temp repo kept at: $tempRoot"
