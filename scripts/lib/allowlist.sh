#!/usr/bin/env bash
# HTTPS download host allowlist (sourced).
set -euo pipefail

CDU_ALLOWED_HOSTS=(
  www.cursor.com
  cursor.com
  api2.cursor.sh
  downloads.cursor.com
)

cdu_host_allowlisted() {
  local host="$1" allowed
  host="${host,,}"
  host="${host#www.}"
  for allowed in "${CDU_ALLOWED_HOSTS[@]}"; do
    allowed="${allowed#www.}"
    if [ "$host" = "$allowed" ]; then
      return 0
    fi
  done
  return 1
}

cdu_url_allowlisted() {
  local url="$1" host

  if [ "${CURSOR_DEB_UPDATER_TEST_MODE:-0}" = 1 ] && [ -n "${CURSOR_DEB_UPDATER_TEST_REJECT_URL:-}" ]; then
    if [ "$url" = "${CURSOR_DEB_UPDATER_TEST_REJECT_URL}" ]; then
      cdu_err "URL rejected by test fixture: $url"
      return 2
    fi
  fi

  case "$url" in
    https://*) ;;
    *)
      cdu_err "Download URL must use HTTPS: $url"
      return 2
      ;;
  esac

  host="$(printf '%s' "$url" | sed -E 's#^https://([^/:]+).*#\1#')"
  if ! cdu_host_allowlisted "$host"; then
    cdu_err "Download host not allowlisted: $host"
    return 2
  fi
  return 0
}

cdu_validate_url_cmd() {
  local url="$1"
  cdu_url_allowlisted "$url"
}
