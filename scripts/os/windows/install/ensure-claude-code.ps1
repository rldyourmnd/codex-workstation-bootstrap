$ErrorActionPreference = "Stop"

Write-Host "[OS:windows][Claude] Starting install check"

if (Get-Command claude -ErrorAction SilentlyContinue) {
  Write-Host "[OS:windows][Claude] claude already available"
  try { & claude --version } catch {}
  exit 0
}

if (Get-Command winget -ErrorAction SilentlyContinue) {
  Write-Host "[OS:windows][Claude] Installing via winget Anthropic.ClaudeCode"
  & winget install Anthropic.ClaudeCode
} else {
  Write-Host "[OS:windows][Claude] winget unavailable, trying official installer"
  & powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex"
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  throw "[OS:windows][Claude][ERROR] claude not found after install."
}

Write-Host "[OS:windows][Claude] Claude Code installed"
try { & claude --version } catch {}
