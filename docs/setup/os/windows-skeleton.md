# Windows Skeleton

This repository includes Windows installer skeletons but treats macOS and Ubuntu/Linux as the primary production path.

## PowerShell installers

- `scripts/os/windows/install/ensure-codex.ps1`
- `scripts/os/windows/install/ensure-claude-code.ps1`

## Run manually in PowerShell

```powershell
./scripts/os/windows/install/ensure-codex.ps1
./scripts/os/windows/install/ensure-claude-code.ps1
```

## Notes

- Keep `codex/os/windows/snapshots/full-home/` for future full-home Windows snapshot support.
- Validate parity on Windows before promoting from skeleton to production.
