# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

## 0.1.3 — 2026-10-02

- Fix: `UPDATE_CHANNEL=auto` compares aptrepo Candidate vs download API and installs from the newer source (apt on a version tie). Avoids staying on a stale aptrepo while the API already ships a newer `.deb`.
- Fix: parse `apt-cache policy` with POSIX `[[:space:]]` so mawk (Ubuntu default) returns Installed/Candidate.

## 0.1.2 — 2026-10-02

- Feat: prefer Anysphere aptrepo (`UPDATE_CHANNEL=auto|apt|api`) — `apt-cache policy` check, `apt-get install --only-upgrade cursor` install; download API kept as fallback.
- Feat: when relaunching, prefer an optional host Chromium-flag wrapper under `~/.local/bin` when present.
- Docs: README / IMPLEMENTATION / example.config for the apt-first channel.

## 0.1.1 — 2026-09-14

- Docs: portal README (explainer-first Quick start, dry-run/`pkill` callout, Issues help, Releases surface).
- Tip catch-up: launcher heal after update, CI tmp passwordless-sudo assert, hostname/username scrub, Ko-fi Support section.

## 0.1.0

- Initial public release: unofficial Cursor Linux `.deb` update glue
- Interactive sudo by default; optional passwordless sudo drop-in
- HTTPS download allowlist with post-redirect validation
- Packaging gate for official `cursor` deb package only
- Optional integrated `cursor.desktop` launcher with ui-mode SSOT
- CI smoke ladder with stub cursor and mock dpkg; `verify-cursor-deb-updater` exits 0 without host Cursor
