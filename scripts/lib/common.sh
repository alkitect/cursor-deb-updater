#!/usr/bin/env bash
# Shared helpers for cursor-deb-updater (sourced, not executed).
set -euo pipefail

CDU_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/cursor-deb-updater"
CDU_LOG="${CDU_CONFIG_DIR}/updater.log"
CDU_UI_MODE_FILE="${CDU_CONFIG_DIR}/ui-mode"
CDU_UI_MODE_DEFAULT="silent"
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

cdu_config_value() {
  local key="$1" cfg="${CDU_CONFIG_DIR}/config" line=""
  [ -f "$cfg" ] || return 0
  line="$(grep -E "^${key}=" "$cfg" | head -1 | cut -d= -f2- || true)"
  printf '%s' "$(printf '%s' "$line" | tr -d '[:space:]"'"'" )"
}

cdu_read_release_track() {
  local track
  track="$(cdu_config_value RELEASE_TRACK)"
  case "$track" in
    latest|stable) printf '%s' "$track" ;;
    *) printf '%s' 'latest' ;;
  esac
}

# auto = compare aptrepo Candidate vs download API and pick the newer source.
cdu_read_update_channel() {
  local ch
  ch="$(cdu_config_value UPDATE_CHANNEL)"
  case "$ch" in
    auto|apt|api) printf '%s' "$ch" ;;
    *) printf '%s' 'auto' ;;
  esac
}

# True when normalized semver $1 is greater than $2.
cdu_semver_gt() {
  local a b
  a="$(cdu_normalize_semver "$1")"
  b="$(cdu_normalize_semver "$2")"
  [ -n "$a" ] && [ -n "$b" ] || return 1
  [ "$a" = "$b" ] && return 1
  if [ "${CURSOR_DEB_UPDATER_TEST_MODE:-0}" = 1 ]; then
    [ "$(printf '%s\n%s\n' "$a" "$b" | sort -V | tail -n1)" = "$a" ]
    return $?
  fi
  dpkg --compare-versions "$a" gt "$b"
}

# Pick install channel from probed versions. Prints apt|api.
# Prefer apt when versions tie or only apt is known; api when only api is known.
cdu_pick_channel_by_version() {
  local apt_ver="${1:-}" api_ver="${2:-}"
  local apt_n api_n
  apt_n="$(cdu_normalize_semver "$apt_ver")"
  api_n="$(cdu_normalize_semver "$api_ver")"
  if [ -z "$apt_n" ] && [ -z "$api_n" ]; then
    return 1
  fi
  if [ -z "$apt_n" ]; then
    printf '%s' api
    return 0
  fi
  if [ -z "$api_n" ]; then
    printf '%s' apt
    return 0
  fi
  if cdu_semver_gt "$api_n" "$apt_n"; then
    printf '%s' api
  else
    # apt newer, or equal → prefer apt install path
    printf '%s' apt
  fi
  return 0
}

cdu_apt_repo_configured() {
  local f
  if [ "${CURSOR_DEB_UPDATER_TEST_MODE:-0}" = 1 ]; then
    [ "${CURSOR_DEB_UPDATER_TEST_APT_REPO:-0}" = 1 ]
    return $?
  fi
  for f in /etc/apt/sources.list.d/cursor.sources /etc/apt/sources.list.d/cursor.list \
    /etc/apt/sources.list.d/cursor-apparmor.sources; do
    if [ -f "$f" ] && grep -qE 'downloads\.cursor\.com/aptrepo' "$f" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

# Prints "installed<TAB>candidate" or empty on failure. Versions may include Debian revision.
cdu_apt_policy_versions() {
  local policy inst cand
  if [ "${CURSOR_DEB_UPDATER_TEST_MODE:-0}" = 1 ]; then
    inst="${CURSOR_DEB_UPDATER_TEST_APT_INSTALLED:-}"
    cand="${CURSOR_DEB_UPDATER_TEST_APT_CANDIDATE:-}"
    [ -n "$inst" ] && [ -n "$cand" ] || return 1
    printf '%s\t%s' "$inst" "$cand"
    return 0
  fi
  policy="$(apt-cache policy cursor 2>/dev/null || true)"
  [ -n "$policy" ] || return 1
  inst="$(printf '%s\n' "$policy" | awk '/^[[:space:]]*Installed:/{print $2; exit}')"
  cand="$(printf '%s\n' "$policy" | awk '/^[[:space:]]*Candidate:/{print $2; exit}')"
  case "$inst" in ''|'(none)') return 1 ;; esac
  case "$cand" in ''|'(none)') return 1 ;; esac
  printf '%s\t%s' "$inst" "$cand"
  return 0
}

cdu_apt_candidate_newer() {
  local inst="$1" cand="$2"
  [ -n "$inst" ] && [ -n "$cand" ] || return 1
  if [ "${CURSOR_DEB_UPDATER_TEST_MODE:-0}" = 1 ]; then
    [ "$cand" != "$inst" ] && return 0
    return 1
  fi
  dpkg --compare-versions "$cand" gt "$inst"
}

# Resolve forced channel preference only (apt|api). For auto, callers probe both
# versions and use cdu_pick_channel_by_version.
cdu_resolve_update_channel() {
  local pref
  pref="$(cdu_read_update_channel)"
  case "$pref" in
    apt)
      if cdu_apt_repo_configured; then
        printf '%s' apt
        return 0
      fi
      cdu_err "UPDATE_CHANNEL=apt but Cursor aptrepo is not configured under /etc/apt/sources.list.d/"
      cdu_err "Install/repair the official .deb (postinst adds the repo) or set UPDATE_CHANNEL=api|auto."
      return 1
      ;;
    api)
      printf '%s' api
      return 0
      ;;
    *)
      # auto: deferred — caller compares apt vs API versions
      printf '%s' auto
      return 0
      ;;
  esac
}

# Fix integrated launcher desktop entry after root-phase install (644, user-owned, cursor-deb-updater Exec).
cdu_ensure_integrated_desktop() {
  local target_user="${1:-}"
  local target_home desktop apps bin updater template tmp marker
  if [ -z "$target_user" ]; then
    return 0
  fi
  target_home="$(getent passwd "$target_user" | cut -d: -f6)"
  [ -n "$target_home" ] || return 0
  desktop="${target_home}/.local/share/applications/cursor.desktop"
  apps="${target_home}/.local/share/applications"
  bin="${target_home}/.local/bin"
  updater="${bin}/cursor-deb-updater"
  template="${target_home}/.local/share/cursor-deb-updater/cursor.desktop.template"
  marker="${target_home}/.config/cursor-deb-updater/integrated-desktop"

  mkdir -p "$apps"
  if [ -f "$marker" ] || [ -f "$desktop" ]; then
    if [ -f "$template" ] && [ -x "$updater" ]; then
      tmp="$(mktemp)"
      sed -e "s|@HOME@|${target_home}|g" -e "s|@BIN@|${bin}|g" "$template" >"$tmp"
      install -m0644 "$tmp" "$desktop"
      rm -f "$tmp"
      touch "$marker"
    elif [ -f "$desktop" ]; then
      if grep -q 'cursor-updater\.sh' "$desktop" 2>/dev/null && [ -x "$updater" ]; then
        sed -i "s|cursor-updater\.sh|cursor-deb-updater|g" "$desktop"
      fi
    fi
  fi
  if [ -f "$desktop" ]; then
    chown "${target_user}:${target_user}" "$desktop"
    chmod 0644 "$desktop"
    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "$apps" 2>/dev/null || true
    fi
  fi
}
