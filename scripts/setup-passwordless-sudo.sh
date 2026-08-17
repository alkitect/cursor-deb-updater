#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UPDATER=""
for candidate in "${HOME}/.local/bin/cursor-deb-updater" "${SCRIPT_DIR}/cursor-deb-updater"; do
  if [ -x "$candidate" ]; then
    UPDATER="$(readlink -f "$candidate")"
    break
  fi
done
SUDOERS_FILE="/etc/sudoers.d/cursor-deb-updater"
MARKER="${XDG_CONFIG_HOME:-$HOME/.config}/cursor-deb-updater/passwordless-sudo-installed"

if [ ! -x "$UPDATER" ]; then
  echo "ERROR: cursor-deb-updater not found or not executable." >&2
  echo "Run install-to-local.sh first, then re-run this helper." >&2
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

TARGET_USER="${SUDO_USER:-${1:-}}"
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
  TARGET_USER="$(logname 2>/dev/null || true)"
fi
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
  echo "ERROR: could not determine desktop username (run via: sudo ./setup-passwordless-sudo.sh)" >&2
  exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
LINE="${TARGET_USER} ALL=(ALL) NOPASSWD: ${UPDATER}"
DEFAULTS_LINE="Defaults!${UPDATER} env_keep += \"CURSOR_UPDATE_VERBOSE\""
{
  printf '%s\n' "$DEFAULTS_LINE"
  printf '%s\n' "$LINE"
} >"$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"
visudo -cf "$SUDOERS_FILE"
mkdir -p "${TARGET_HOME}/.config/cursor-deb-updater"
touch "${TARGET_HOME}/.config/cursor-deb-updater/passwordless-sudo-installed"

echo "OK: passwordless sudo configured for ${TARGET_USER}"
echo "     ${SUDOERS_FILE}"
echo "     ${DEFAULTS_LINE}"
echo "     ${LINE}"
