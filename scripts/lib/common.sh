#!/usr/bin/env bash
# Shared helpers for cursor-deb-updater (sourced, not executed).
set -euo pipefail

CDU_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/cursor-deb-updater"
CDU_LOG="${CDU_CONFIG_DIR}/updater.log"
CDU_UI_MODE_FILE="${CDU_CONFIG_DIR}/ui-mode"
CDU_UI_MODE_DEFAULT="terminal"
CDU_INTEGRATED_MARKER="${CDU_CONFIG_DIR}/integrated-desktop"
CDU_SUDOERS_FILE="/etc/sudoers.d/cursor-deb-updater"

cdu_msg() {
  printf '[cursor-deb-updater] %s\n' "$*"
}

cdu_verbose() {
  if [ "${CURSOR_UPDATE_VERBOSE:-0}" = 1 ]; then
    cdu_msg "$@"
  fi
  return 0
}

cdu_err() {
  printf '[cursor-deb-updater] ERROR: %s\n' "$*" >&2
}

cdu_notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send -i co.anysphere.cursor "Cursor Deb Updater" "$1" 2>/dev/null || true
}

cdu_interactive_tty() { [ -t 1 ] && [ "${CURSOR_UPDATE_VERBOSE:-0}" != 1 ]; }

cdu_tty_endline() { cdu_interactive_tty && printf '\n' || true; }

cdu_phase() {
  local n="$1" total="$2"
  shift 2
  cdu_msg "[$n/$total] $*"
}

cdu_countdown_line() {
  local sec="$1" prefix="$2" s
  cdu_interactive_tty || return 0
  for ((s = sec; s >= 1; s--)); do
    printf '\r[cursor-deb-updater] %s %s…' "$prefix" "$s"
    sleep 1
  done
  printf '\n'
}

cdu_log_event() {
  local phase="$1" status="$2"
  shift 2
  mkdir -p "$CDU_CONFIG_DIR"
  printf '%s %s %s %s\n' "$(date -Is)" "$phase" "$status" "$*" >>"$CDU_LOG"
}

cdu_platform_slug() {
  case "$(uname -m)" in
    x86_64) printf '%s' 'linux-x64' ;;
    aarch64) printf '%s' 'linux-arm64' ;;
    *)
      cdu_err "Unsupported architecture: $(uname -m)"
      return 1
      ;;
  esac
}

cdu_deb_arch() {
  case "$(uname -m)" in
    x86_64) printf '%s' 'amd64' ;;
    aarch64) printf '%s' 'arm64' ;;
    *) return 1 ;;
  esac
}

cdu_release_api_urls() {
  local platform track
  platform="$(cdu_platform_slug)" || return 1
  for track in latest stable; do
    printf '%s\n' "https://www.cursor.com/api/download?platform=${platform}&releaseTrack=${track}"
    printf '%s\n' "https://api2.cursor.sh/updates/api/download/${track}/${platform}/cursor"
  done
}

cdu_json_field() {
  local json="$1" field="$2"
  printf '%s' "$json" | grep -o "\"${field}\":\"[^\"]*\"" | head -1 | cut -d'"' -f4 || true
}

cdu_normalize_semver() {
  echo "$1" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true
}

cdu_ui_mode() {
  local mode="${CURSOR_UPDATE_UI:-}"
  if [ -z "$mode" ] && [ -f "$CDU_UI_MODE_FILE" ]; then
    mode="$(tr -d '[:space:]' <"$CDU_UI_MODE_FILE" | tr '[:upper:]' '[:lower:]')"
  fi
  case "$mode" in
    silent|terminal) printf '%s' "$mode" ;;
    *) printf '%s' "$CDU_UI_MODE_DEFAULT" ;;
  esac
}

cdu_silent_enabled() {
  [ "$(cdu_ui_mode)" = silent ]
}

cdu_read_release_track() {
  local cfg="${CDU_CONFIG_DIR}/config"
  local track="latest"
  if [ -f "$cfg" ]; then
    track="$(grep -E '^RELEASE_TRACK=' "$cfg" | head -1 | cut -d= -f2- | tr -d '[:space:]"'"'" || true)"
  fi
  case "$track" in
    latest|stable) printf '%s' "$track" ;;
    *) printf '%s' 'latest' ;;
  esac
}
