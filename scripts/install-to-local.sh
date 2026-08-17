#!/usr/bin/env bash
# Install cursor-deb-updater glue to ~/.local/bin.
# Usage: install-to-local.sh [--enable-passwordless-sudo] [--integrate-launcher] [--force]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${HOME}/.local/bin"
CFG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/cursor-deb-updater"
DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/cursor-deb-updater"
APPS="${XDG_DATA_HOME:-${HOME}/.local/share}/applications"
LOCAL_DESKTOP="${APPS}/cursor.desktop"
ENABLE_SUDO=0
INTEGRATE=0
FORCE=0

for arg in "$@"; do
  case "${arg}" in
    --enable-passwordless-sudo) ENABLE_SUDO=1 ;;
    --integrate-launcher) INTEGRATE=1 ;;
    --force) FORCE=1 ;;
    -h|--help)
      cat <<EOF
Usage: $(basename "$0") [--enable-passwordless-sudo] [--integrate-launcher] [--force]

  Installs cursor-deb-updater, cursor-deb-updater-ui, verify-cursor-deb-updater.
  Seeds ~/.config/cursor-deb-updater/config and ui-mode if missing.
  Default: no sudoers drop-in, no cursor.desktop changes.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      exit 2
      ;;
  esac
done

mkdir -p "${BIN}" "${CFG_DIR}" "${DATA_DIR}"
install -m0755 "${ROOT}/scripts/cursor-deb-updater" "${BIN}/cursor-deb-updater"
install -m0755 "${ROOT}/scripts/cursor-deb-updater-ui" "${BIN}/cursor-deb-updater-ui"
install -m0755 "${ROOT}/scripts/verify-cursor-deb-updater.sh" "${BIN}/verify-cursor-deb-updater"
install -m0755 "${ROOT}/scripts/setup-passwordless-sudo.sh" "${BIN}/setup-passwordless-sudo.sh"
install -m0644 "${ROOT}/scripts/lib/common.sh" "${DATA_DIR}/common.sh"
install -m0644 "${ROOT}/scripts/lib/allowlist.sh" "${DATA_DIR}/allowlist.sh"
install -m0644 "${ROOT}/scripts/lib/packaging-gate.sh" "${DATA_DIR}/packaging-gate.sh"
install -m0644 "${ROOT}/desktop/cursor.desktop.template" "${DATA_DIR}/cursor.desktop.template"

if [[ ! -f "${CFG_DIR}/config" ]]; then
  install -m0644 "${ROOT}/config/example.config" "${CFG_DIR}/config"
  echo "Seeded ${CFG_DIR}/config"
fi
if [[ ! -f "${CFG_DIR}/ui-mode" ]]; then
  printf 'terminal\n' >"${CFG_DIR}/ui-mode"
  echo "Seeded ${CFG_DIR}/ui-mode (terminal)"
fi

integrate_launcher() {
  local template tmp
  if [[ -f "${LOCAL_DESKTOP}" ]] && [[ ! -f "${CFG_DIR}/integrated-desktop" ]]; then
    if [[ "${FORCE}" -ne 1 ]]; then
      echo "Refusing to overwrite existing ${LOCAL_DESKTOP} without integrated marker." >&2
      echo "Re-run with --integrate-launcher --force to backup and replace." >&2
      exit 2
    fi
    cp -a "${LOCAL_DESKTOP}" "${LOCAL_DESKTOP}.bak.$(date +%Y%m%d%H%M%S)"
    echo "Backed up existing desktop to ${LOCAL_DESKTOP}.bak.*"
  fi
  mkdir -p "${APPS}"
  template="${DATA_DIR}/cursor.desktop.template"
  tmp="$(mktemp)"
  sed -e "s|@HOME@|${HOME}|g" -e "s|@BIN@|${BIN}|g" "${template}" >"${tmp}"
  install -m0644 "${tmp}" "${LOCAL_DESKTOP}"
  rm -f "${tmp}"
  touch "${CFG_DIR}/integrated-desktop"
  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${APPS}" 2>/dev/null || true
  fi
  echo "Integrated launcher: ${LOCAL_DESKTOP}"
}

if [[ "${INTEGRATE}" -eq 1 ]]; then
  integrate_launcher
fi

if [[ "${ENABLE_SUDO}" -eq 1 ]]; then
  "${ROOT}/scripts/setup-passwordless-sudo.sh"
fi

echo ""
echo "Installed:"
echo "  ${BIN}/cursor-deb-updater"
echo "  ${BIN}/cursor-deb-updater-ui"
echo "  ${BIN}/verify-cursor-deb-updater"
echo ""
echo "Next: cursor-deb-updater   # from a terminal (sudo may prompt)"
echo "Verify: verify-cursor-deb-updater"
