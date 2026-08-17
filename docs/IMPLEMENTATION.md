# Implementation notes

Unofficial glue around the official Cursor Linux `.deb`. Not affiliated with Anysphere.

## Phases

### Check (user)

1. **Packaging gate** — resolve the real Cursor binary (`/usr/share/cursor/cursor` or `dpkg -L cursor` desktop `Exec=`). `dpkg -S` must report package `cursor`. Exit 2 for non-deb installs.
2. Read installed version via `cursor --version`.
3. Fetch release JSON from Cursor API (`RELEASE_TRACK` from config: `latest` or `stable`; platform `linux-x64` or `linux-arm64`).
4. Validate resolved `.deb` URL against HTTPS allowlist (`www.cursor.com`, `cursor.com`, `api2.cursor.sh`, `downloads.cursor.com`).
5. If already latest: relaunch via session desktop and exit 0.
6. If update needed: invoke root install phase via sudo (interactive TTY prompt, or `sudo -n` when passwordless drop-in is configured).

### Install (root, `--install`)

Receives session env vars and optional pre-resolved deb URL (arg 11) to avoid root re-fetch.

1. Re-check versions; skip download if already matched.
2. Download `.deb`; re-validate **final** URL after redirects.
3. `pkill -x cursor`, wait, then `apt-get install` (TTY) or `dpkg -i` + `apt-get -f`.
4. Relaunch as desktop user: if local desktop `Exec=` is this updater, launch `/usr/share/cursor/cursor` directly (avoid `gio launch` recursion); else prefer `gio launch` / `gtk-launch` with forwarded session env.

Exit 2 = install succeeded but launch verification failed.

## Privilege model

- Default: interactive `sudo` for install phase when no NOPASSWD rule exists.
- `--enable-passwordless-sudo` writes `/etc/sudoers.d/cursor-deb-updater` granting **only** the absolute path to `cursor-deb-updater` plus `env_keep` for `CURSOR_UPDATE_VERBOSE`.
- Non-TTY without NOPASSWD: exit 1 with message to run from a terminal or enable passwordless sudo.

## Opt-in surfaces

| Flag | Effect |
|------|--------|
| `--integrate-launcher` | Generate `~/.local/share/applications/cursor.desktop` from template; marker `integrated-desktop` |
| `--integrate-launcher --force` | Backup foreign desktop to `.bak.<timestamp>` first |
| `--enable-passwordless-sudo` | Install sudoers drop-in via `setup-passwordless-sudo.sh` |
| `--dry-run` | Print/update path without pkill, download, dpkg, or relaunch |

`~/.config/cursor-deb-updater/ui-mode` is the only UI-mode SSOT (`cursor-deb-updater-ui` writes it).

## Deferred (not v0.1.0)

- `POST_INSTALL_CMD` hook — use manual host steps after update if you need extra launcher reconciliation.

## Test mode

`CURSOR_DEB_UPDATER_TEST_MODE=1` with stub `cursor` and mock `dpkg` on PATH powers `./scripts/ci-check.sh` without network or a real Cursor install.
