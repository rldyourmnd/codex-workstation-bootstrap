## Summary

Describe what changed and why.

## Scope

- [ ] macOS runtime payload
- [ ] shared agent profiles
- [ ] scripts
- [ ] docs
- [ ] CI / GitHub config

## Validation

- [ ] `scripts/check-toolchain.sh --strict-codex-only`
- [ ] `scripts/audit-codex-agents.sh`
- [ ] `scripts/self-test.sh`

## Risk and rollback

List potential risk and how to rollback safely.

## Checklist

- [ ] No real secrets committed
- [ ] No shared/custom skill overlap introduced
- [ ] Structure remains under `codex/os/*`
