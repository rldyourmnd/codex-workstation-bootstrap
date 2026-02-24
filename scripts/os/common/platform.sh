#!/usr/bin/env bash

platform_id() {
  case "$(uname -s)" in
    Darwin) printf 'macos\n' ;;
    Linux) printf 'linux\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

is_macos() {
  [[ "$(platform_id)" == "macos" ]]
}

sed_inplace() {
  local target="$1"
  shift

  if is_macos; then
    sed -i '' "$@" "$target"
  else
    sed -i "$@" "$target"
  fi
}

mktemp_with_suffix() {
  local suffix="$1"
  local tmp

  tmp="$(mktemp)"
  mv "$tmp" "${tmp}${suffix}"
  printf '%s\n' "${tmp}${suffix}"
}

base64_decode_file() {
  local src="$1"
  local dst="$2"

  if is_macos; then
    base64 -D -i "$src" > "$dst"
  else
    base64 -d "$src" > "$dst"
  fi
}

base64_encode_nolinewrap() {
  local src="$1"
  if is_macos; then
    base64 -i "$src" | tr -d '\n'
  elif base64 --help 2>/dev/null | grep -q -- '-w'; then
    base64 -w 0 "$src"
  else
    base64 "$src" | tr -d '\n'
  fi
}

sha256_file() {
  local src="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$src" | awk '{print $1}'
    return 0
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$src" | awk '{print $1}'
    return 0
  fi

  echo "[ERROR] No sha256 tool available (sha256sum or shasum)." >&2
  return 1
}

list_top_level_dirs() {
  local dir="$1"
  find "$dir" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sort
}

read_nonempty_lines() {
  local file="$1"
  grep -Ev '^\s*#|^\s*$' "$file" || true
}

utc_now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}
