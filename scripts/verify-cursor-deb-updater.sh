#!/usr/bin/env bash
# Verify installed cursor-deb-updater glue (no network; no real Cursor required).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${HOME}/.local/bin"
CFG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/cursor-deb-updater"
DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/cursor-deb-updater"
ROOT=""
STRICT=0
INSTALLED=0

for arg in "$@"; do
  case "${arg}" in
    --strict) STRICT=1 ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--strict]"
      exit 0
      ;;
    *)
      echo "Unknown option: ${arg}" >&2
      exit 2
      ;;
  esac
done

resolve_root() {
  if [[ -f "${SCRIPT_DIR}/../config/example.config" && -f "${SCRIPT_DIR}/cursor-deb-updater" ]]; then
    ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
    return 0
  fi
  if [[ -f "${DATA_DIR}/cursor.desktop.template" && -f "${DATA_DIR}/packaging-gate.sh" ]]; then
    INSTALLED=1
    return 0
  fi
  return 1
}

fail() {
  echo "verify-cursor-deb-updater: $*" >&2
  exit 1
}

warn() {
  echo "verify-cursor-deb-updater: WARN: $*" >&2
}

if ! resolve_root; then
  fail "install root unresolved (run install-to-local.sh from the checkout)"
fi

if [[ "${INSTALLED}" -eq 0 ]]; then
  bash -n "${ROOT}/scripts/cursor-deb-updater"
  bash -n "${ROOT}/scripts/cursor-deb-updater-ui"
  bash -n "${ROOT}/scripts/install-to-local.sh"
  bash -n "${ROOT}/scripts/uninstall-from-local.sh"
  bash -n "${ROOT}/scripts/verify-cursor-deb-updater.sh"
  bash -n "${ROOT}/scripts/setup-passwordless-sudo.sh"
  bash -n "${ROOT}/scripts/lib/common.sh"
  bash -n "${ROOT}/scripts/lib/allowlist.sh"
  bash -n "${ROOT}/scripts/lib/packaging-gate.sh"
else
  bash -n "${BIN}/cursor-deb-updater"
  bash -n "${BIN}/cursor-deb-updater-ui"
fi

[[ -x "${BIN}/cursor-deb-updater" ]] || fail "missing ${BIN}/cursor-deb-updater (run install-to-local.sh)"
[[ -x "${BIN}/cursor-deb-updater-ui" ]] || fail "missing ${BIN}/cursor-deb-updater-ui"
[[ -x "${BIN}/verify-cursor-deb-updater" ]] || fail "missing verify wrapper on PATH"
[[ -d "${CFG_DIR}" ]] || fail "missing config dir ${CFG_DIR}"
[[ -f "${CFG_DIR}/config" ]] || fail "missing ${CFG_DIR}/config"
grep -q '^RELEASE_TRACK=' "${CFG_DIR}/config" || fail "config missing RELEASE_TRACK"
if grep -qE '^POST_INSTALL_CMD=' "${CFG_DIR}/config" 2>/dev/null; then
  fail "config must not contain POST_INSTALL_CMD in v0.1.0"
fi
if grep -qE '^UI_MODE=' "${CFG_DIR}/config" 2>/dev/null; then
  fail "ui-mode must live in ${CFG_DIR}/ui-mode, not config"
fi
[[ -f "${DATA_DIR}/cursor.desktop.template" ]] || fail "missing desktop template under ${DATA_DIR}"

if [[ -f /etc/sudoers.d/cursor-deb-updater ]]; then
  warn "passwordless sudo drop-in present (expected only after --enable-passwordless-sudo)"
  [[ "${STRICT}" -eq 1 ]] && fail "unexpected sudoers without --strict waiver"
fi

set +e
"${BIN}/cursor-deb-updater" --packaging-gate 2>/dev/null
cdu_gate_rc=$?
set -e
if [[ "${cdu_gate_rc}" -eq 0 ]]; then
  :
else
  if [[ "${cdu_gate_rc}" -eq 2 ]]; then
    warn "packaging gate: official Cursor .deb not detected on this machine"
    [[ "${STRICT}" -eq 1 ]] && fail "packaging gate failed (--strict)"
  else
    fail "packaging gate check failed unexpectedly (exit ${cdu_gate_rc})"
  fi
fi

echo "verify-cursor-deb-updater: OK"
