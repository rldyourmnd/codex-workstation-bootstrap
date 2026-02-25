#!/usr/bin/env bash

is_supported_profile_os() {
  case "$1" in
    macos|linux|windows) return 0 ;;
    *) return 1 ;;
  esac
}

detect_profile_os() {
  if [[ -n "${BETTER_CODEX_PROFILE_OS:-}" ]]; then
    printf '%s\n' "$BETTER_CODEX_PROFILE_OS"
    return
  fi
  platform_id
}

profile_runtime_root() {
  local profile="$1"
  printf '%s\n' "$ROOT_DIR/codex/os/$profile/runtime"
}

macos_runtime_root() {
  profile_runtime_root "macos"
}

common_agent_skills_root() {
  printf '%s\n' "$ROOT_DIR/codex/os/common/agents/codex-agents"
}

profile_has_payload() {
  local profile="$1"
  local root
  root="$(profile_runtime_root "$profile")"
  [[ -f "$root/config/config.template.toml" ]]
}

resolve_profile_os() {
  local requested="${1:-$(detect_profile_os)}"
  if is_supported_profile_os "$requested" && profile_has_payload "$requested"; then
    printf '%s\n' "$requested"
    return
  fi
  printf 'macos\n'
}

resolve_runtime_root() {
  local requested="${1:-$(detect_profile_os)}"
  local resolved
  resolved="$(resolve_profile_os "$requested")"
  profile_runtime_root "$resolved"
}
