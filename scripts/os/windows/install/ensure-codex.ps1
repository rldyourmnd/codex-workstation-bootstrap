param(
  [string]$ExpectedVersion = ""
)

$ErrorActionPreference = "Stop"

Write-Host "[OS:windows][Codex] Starting install check"

function Get-CodexVersion {
  try {
    $raw = & codex --version 2>$null
    if (-not $raw) { return "" }
    $parts = $raw -split "\s+"
    if ($parts.Length -ge 2) { return $parts[1] }
    return ""
  } catch {
    return ""
  }
}

$current = Get-CodexVersion
if ($current) {
  Write-Host "[OS:windows][Codex] codex detected: $current"
} else {
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    throw "[OS:windows][Codex][ERROR] npm not found. Install Node.js first."
  }

  if ($ExpectedVersion -and $ExpectedVersion -ne "unknown") {
    Write-Host "[OS:windows][Codex] Installing @openai/codex@$ExpectedVersion"
    & npm i -g "@openai/codex@$ExpectedVersion"
  } else {
    Write-Host "[OS:windows][Codex] Installing @openai/codex latest"
    & npm i -g @openai/codex
  }

  $current = Get-CodexVersion
  if (-not $current) {
    throw "[OS:windows][Codex][ERROR] codex not found after install."
  }
  Write-Host "[OS:windows][Codex] codex installed: $current"
}

if ($ExpectedVersion -and $ExpectedVersion -ne "unknown" -and $current -ne $ExpectedVersion) {
  Write-Warning "[OS:windows][Codex] Expected $ExpectedVersion, got $current"
}
