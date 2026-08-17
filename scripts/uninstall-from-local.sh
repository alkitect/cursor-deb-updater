#!/usr/bin/env bash
# Remove cursor-deb-updater glue; keep the Cursor .deb app.
# Usage: uninstall-from-local.sh [--purge-config]
set -euo pipefail

BIN="${HOME}/.local/bin"
CFG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/cursor-deb-updater"
DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/cursor-deb-updater"
APPS="${XDG_DATA_HOME:-${HOME}/.local/share}/applications"
LOCAL_DESKTOP="${APPS}/cursor.desktop"
PURGE_CONFIG=0

for arg in "$@"; do
  case "${arg}" in
    --purge-config) PURGE_CONFIG=1 ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--purge-config]"
      echo "  Removes glue binaries and integrated desktop (if marker exists)."
      echo "  Keeps stub cursor on PATH if you installed one for testing."
      exit 0
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      exit 2
      ;;
  esac
done

if [[ -f "${CFG_DIR}/integrated-desktop" ]]; then
  rm -f "${LOCAL_DESKTOP}"
  rm -f "${CFG_DIR}/integrated-desktop"
  echo "Removed integrated ${LOCAL_DESKTOP}"
fi

rm -f "${BIN}/cursor-deb-updater"
rm -f "${BIN}/cursor-deb-updater-ui"
rm -f "${BIN}/verify-cursor-deb-updater"
rm -f "${BIN}/setup-passwordless-sudo.sh"
rm -rf "${DATA_DIR}"

if [[ -f /etc/sudoers.d/cursor-deb-updater ]] && [[ -f "${CFG_DIR}/passwordless-sudo-installed" ]]; then
  if [[ "$(id -u)" -eq 0 ]]; then
    rm -f /etc/sudoers.d/cursor-deb-updater
    echo "Removed /etc/sudoers.d/cursor-deb-updater"
  else
    echo "Run: sudo rm /etc/sudoers.d/cursor-deb-updater"
  fi
fi

if [[ "${PURGE_CONFIG}" -eq 1 ]]; then
  rm -rf "${CFG_DIR}"
  echo "Removed config under ${CFG_DIR}"
else
  echo "Config kept at ${CFG_DIR} (re-run with --purge-config to remove)."
fi

echo "Uninstalled cursor-deb-updater glue."
