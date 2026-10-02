# Implementation notes

Unofficial glue around the official Cursor Linux `.deb`. Not affiliated with Anysphere.

## Phases

### Check (user)

1. **Packaging gate** — resolve the real Cursor binary (`/usr/share/cursor/cursor` or `dpkg -L cursor` desktop `Exec=`). `dpkg -S` must report package `cursor`. Exit 2 for non-deb installs.
2. **Resolve channel** — `UPDATE_CHANNEL` from config (`auto` | `apt` | `api`).
   - `apt` / `api`: force that source.
   - `auto` (default): probe aptrepo Candidate (when configured) and download API; pick the source with the newer normalized semver. Prefer apt when versions tie or only apt is known.
3. **Installed version** — prefer apt `Installed` when available, else `cursor --version`.
4. **Chosen source** — if Candidate/API version is not newer than installed (`cdu_semver_gt`), relaunch and exit 0.
5. If update needed: invoke root install phase via sudo (interactive TTY prompt, or `sudo -n` when passwordless drop-in is configured). Pass resolved channel as install arg 12.

### Install (root, `--install`)

Receives session env vars, optional pre-resolved deb URL (arg 11), and channel (arg 12: `apt` or `api`).

**Apt channel**

1. `apt-get update`, re-read policy, skip upgrade when Candidate is not newer.
2. `pkill -x cursor`, wait, then `apt-get install --only-upgrade -y cursor`.
3. Heal integrated desktop and relaunch (same as API path).

**API channel**

1. Re-check versions; skip download if already matched.
2. Download `.deb`; re-validate **final** URL after redirects.
3. `pkill -x cursor`, wait, then `apt-get install` (TTY) or `dpkg -i` + `apt-get -f`.
4. Relaunch as desktop user: if local desktop `Exec=` is this updater, launch `/usr/share/cursor/cursor` directly (avoid `gio launch` recursion), preferring an optional Chromium-flag wrapper in the desktop user's `~/.local/bin` when present; else prefer `gio launch` / `gtk-launch` with forwarded session env.

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
| `--dry-run` | Print/update path without pkill, download, dpkg/apt upgrade, or relaunch |

`~/.config/cursor-deb-updater/ui-mode` is the only UI-mode file (`cursor-deb-updater-ui` writes it).

Config (`~/.config/cursor-deb-updater/config`):

| Key | Values | Notes |
|-----|--------|--------|
| `UPDATE_CHANNEL` | `auto` (default), `apt`, `api` | `auto` picks newer of aptrepo vs download API (apt on tie) |
| `RELEASE_TRACK` | `latest`, `stable` | Download API only |

## Deferred (not v0.1.x)

- `POST_INSTALL_CMD` hook — use manual host steps after update if you need extra launcher reconciliation.
- Scoped `apt-get update` to aptrepo only (today refreshes all sources; PackageKit lock still applies).

## Test mode

`CURSOR_DEB_UPDATER_TEST_MODE=1` with stub `cursor` and mock `dpkg` on PATH powers `./scripts/ci-check.sh` without network or a real Cursor install.

Apt path fixtures: `CURSOR_DEB_UPDATER_TEST_APT_REPO=1`, `CURSOR_DEB_UPDATER_TEST_APT_INSTALLED`, `CURSOR_DEB_UPDATER_TEST_APT_CANDIDATE`.
