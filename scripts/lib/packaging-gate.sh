#!/usr/bin/env bash
# Packaging gate: official Cursor .deb only (sourced).
set -euo pipefail

cdu_resolve_real_cursor_binary() {
  local bin f exec_line

  bin="/usr/share/cursor/cursor"
  if [ -x "$bin" ]; then
    printf '%s' "$bin"
    return 0
  fi

  f="$(dpkg -L cursor 2>/dev/null | grep -E '/applications/.*\.desktop$' | head -n1 || true)"
  if [ -n "$f" ] && [ -f "$f" ]; then
    exec_line="$(grep -E '^Exec=' "$f" | head -1 | cut -d= -f2- || true)"
    exec_line="${exec_line%% *}"
    if [ -n "$exec_line" ] && [ -x "$exec_line" ]; then
      printf '%s' "$exec_line"
      return 0
    fi
  fi

  for bin in /usr/bin/cursor /usr/share/cursor/cursor; do
    if [ -x "$bin" ]; then
      printf '%s' "$bin"
      return 0
    fi
  done
  return 1
}

cdu_packaging_gate() {
  local real_bin owner pkg

  if [ "${CURSOR_DEB_UPDATER_TEST_MODE:-0}" = 1 ] && [ -n "${CURSOR_DEB_UPDATER_TEST_PACKAGE:-}" ]; then
    pkg="${CURSOR_DEB_UPDATER_TEST_PACKAGE}"
    if [ "$pkg" != "cursor" ]; then
      cdu_err "Packaging gate: expected deb package 'cursor', got '${pkg}' (test mode)."
      return 2
    fi
    return 0
  fi

  if ! real_bin="$(cdu_resolve_real_cursor_binary)"; then
    cdu_err "Packaging gate: Cursor .deb binary not found (install official .deb first)."
    return 2
  fi

  owner="$(dpkg -S "$real_bin" 2>/dev/null | head -1 || true)"
  pkg="${owner%%:*}"
  if [ "$pkg" != "cursor" ]; then
    cdu_err "Packaging gate: ${real_bin} is not owned by deb package 'cursor' (got: ${pkg:-unknown})."
    cdu_err "This tool supports the official Cursor Linux .deb only (not AppImage/snap/Flatpak wrappers)."
    return 2
  fi
  return 0
}
