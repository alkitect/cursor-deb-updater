#!/usr/bin/env bash
# Release gate for cursor-deb-updater (local + CI).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

FORBIDDEN_RE='Python/Linux|\.cursor/plans|topics/cursor|cursor-desktop-x11|cursor-managed|FRACTALNORTH'
hits="$(grep -rE "${FORBIDDEN_RE}" \
  --include='*.sh' --include='*.md' --include='*.example' --include='*.template' . \
  --exclude-dir=.git --exclude='ci-check.sh' 2>/dev/null || true)"
if [[ -n "${hits}" ]]; then
  echo "ci-check: forbidden refs found:" >&2
  echo "${hits}" >&2
  exit 1
fi

if grep -rE '/home/alex' --include='*.md' --include='*.template' . --exclude-dir=.git --exclude='ci-check.sh' >/dev/null 2>&1; then
  echo "ci-check: public tree must not contain host home paths" >&2
  exit 1
fi

REQUIRED_H2=(
  "## What this does"
  "## Who this is for"
  "## Quick start"
  "## Check it works"
  "## Uninstall"
  "## Limits & safety"
  "## License"
)
for h in "${REQUIRED_H2[@]}"; do
  grep -qFx "${h}" README.md || { echo "ci-check: README missing H2: ${h}" >&2; exit 1; }
done
grep -qE '\bSSOT\b' README.md && { echo "ci-check: README must not use SSOT" >&2; exit 1; }

[[ -f .github/FUNDING.yml ]] || { echo "ci-check: missing FUNDING.yml" >&2; exit 1; }
grep -qE '^[[:space:]]*ko_fi:[[:space:]]*alkitect[[:space:]]*$' .github/FUNDING.yml \
  || { echo "ci-check: FUNDING.yml must set ko_fi: alkitect" >&2; exit 1; }
grep -qF 'ko-fi.com/alkitect' README.md || { echo "ci-check: README missing Ko-fi link" >&2; exit 1; }
grep -qF 'ko-fi.com/img/githubbutton_sm.svg' README.md \
  || { echo "ci-check: README missing Ko-fi button" >&2; exit 1; }

grep -qF 'First public tag: v0.1.0' docs/PUBLISH.md \
  || { echo "ci-check: PUBLISH must record First public tag: v0.1.0" >&2; exit 1; }
if grep -qE '^## 0\.9\.0' CHANGELOG.md 2>/dev/null; then
  echo "ci-check: CHANGELOG ## 0.9.0 is not the default first tag" >&2
  exit 1
fi
for _vf in docs/PUBLISH.md README.md; do
  grep -qE 'v0\.9\.0' "${_vf}" && { echo "ci-check: ${_vf} mentions v0.9.0" >&2; exit 1; }
done

grep -q '^RELEASE_TRACK=' config/example.config \
  || { echo "ci-check: example.config missing RELEASE_TRACK" >&2; exit 1; }
grep -qE '^POST_INSTALL_CMD=' config/example.config \
  && { echo "ci-check: example.config must not ship POST_INSTALL_CMD" >&2; exit 1; }
grep -qE '^UI_MODE=' config/example.config \
  && { echo "ci-check: UI_MODE belongs in ui-mode file, not config" >&2; exit 1; }

if git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    && git describe --tags --abbrev=0 >/dev/null 2>&1; then
  _tag="$(git describe --tags --abbrev=0)"
  _tag="${_tag#v}"
  _first="$(awk '/^## [0-9]+\.[0-9]+\.[0-9]+/{ sub(/^## /,""); sub(/ .*/,""); print; exit }' CHANGELOG.md)"
  [[ -z "${_first}" || "${_first}" = "${_tag}" ]] \
    || { echo "ci-check: CHANGELOG ${_first} != tag ${_tag}" >&2; exit 1; }
fi

find scripts -type f \( -name '*.sh' -o -name 'cursor-deb-updater' -o -name 'cursor-deb-updater-ui' \) -print0 \
  | xargs -0 -r bash -n

tmp="$(mktemp -d)"
cleanup() { rm -rf "${tmp}"; }
trap cleanup EXIT

export HOME="${tmp}"
export XDG_CONFIG_HOME="${tmp}/.config"
export XDG_STATE_HOME="${tmp}/.local/state"
export XDG_DATA_HOME="${tmp}/.local/share"
export PATH="${tmp}/.local/bin:${PATH}"
mkdir -p "${tmp}/.local/bin" "${tmp}/.local/share/applications"

install -m0755 "${ROOT}/scripts/test/stub-cursor" "${tmp}/.local/bin/cursor"
install -m0755 "${ROOT}/scripts/test/mock-dpkg" "${tmp}/.local/bin/dpkg"
install -m0755 "${ROOT}/scripts/test/mock-dpkg" "${tmp}/.local/bin/dpkg-query"

export CURSOR_DEB_UPDATER_TEST_MODE=1
export CURSOR_DEB_UPDATER_TEST_PACKAGE=cursor
export CURSOR_DEB_UPDATER_STUB_VERSION=1.0.0
export CURSOR_DEB_UPDATER_TEST_LATEST=9.9.9
export CURSOR_DEB_UPDATER_TEST_DEB_URL=https://downloads.cursor.com/test/cursor_test_amd64.deb

"${ROOT}/scripts/install-to-local.sh"
test -x "${tmp}/.local/bin/cursor-deb-updater"
test -x "${tmp}/.local/bin/cursor-deb-updater-ui"
test -x "${tmp}/.local/bin/verify-cursor-deb-updater"
test ! -f /etc/sudoers.d/cursor-deb-updater
test ! -f "${tmp}/.local/share/applications/cursor.desktop"

"${tmp}/.local/bin/verify-cursor-deb-updater"

set +e
"${tmp}/.local/bin/cursor-deb-updater" --validate-url 'https://example.com/evil.deb'
rc_bad=$?
"${tmp}/.local/bin/cursor-deb-updater" --validate-url 'https://downloads.cursor.com/test/cursor.deb'
rc_ok=$?
set -e
[[ "${rc_bad}" -eq 2 ]] || { echo "ci-check: allowlist must reject example.com (got ${rc_bad})" >&2; exit 1; }
[[ "${rc_ok}" -eq 0 ]] || { echo "ci-check: allowlist must accept downloads.cursor.com (got ${rc_ok})" >&2; exit 1; }

export CURSOR_DEB_UPDATER_TEST_PACKAGE=not-cursor
set +e
"${tmp}/.local/bin/cursor-deb-updater" --packaging-gate
rc_pkg=$?
set -e
[[ "${rc_pkg}" -eq 2 ]] || { echo "ci-check: packaging negative expected exit 2, got ${rc_pkg}" >&2; exit 1; }
export CURSOR_DEB_UPDATER_TEST_PACKAGE=cursor

printf '[Desktop Entry]\nExec=/usr/bin/true\n' >"${tmp}/.local/share/applications/cursor.desktop"
set +e
"${ROOT}/scripts/install-to-local.sh" --integrate-launcher
rc_refuse=$?
set -e
[[ "${rc_refuse}" -eq 2 ]] || { echo "ci-check: integrate-launcher must refuse foreign desktop (got ${rc_refuse})" >&2; exit 1; }

rm -f "${tmp}/.local/share/applications/cursor.desktop"
"${ROOT}/scripts/install-to-local.sh" --integrate-launcher
test -f "${tmp}/.local/share/applications/cursor.desktop"
test -f "${tmp}/.config/cursor-deb-updater/integrated-desktop"
grep -q 'cursor-deb-updater' "${tmp}/.local/share/applications/cursor.desktop"
grep -q '/usr/share/cursor/cursor --new-window' "${tmp}/.local/share/applications/cursor.desktop"
! grep -q 'cursor-managed' "${tmp}/.local/share/applications/cursor.desktop"

grep -q 'desktop_main_exec_is_updater' "${ROOT}/scripts/cursor-deb-updater" \
  || { echo "ci-check: missing gio-recursion guard" >&2; exit 1; }

"${ROOT}/scripts/uninstall-from-local.sh"
test ! -x "${tmp}/.local/bin/cursor-deb-updater"
test -x "${tmp}/.local/bin/cursor"
test ! -f "${tmp}/.local/share/applications/cursor.desktop"

printf '[Desktop Entry]\nExec=/usr/bin/true\n' >"${tmp}/.local/share/applications/cursor.desktop"
"${ROOT}/scripts/install-to-local.sh"
"${ROOT}/scripts/uninstall-from-local.sh"
test -f "${tmp}/.local/share/applications/cursor.desktop"
test -x "${tmp}/.local/bin/cursor"

echo "ci-check: OK"
