# cursor-deb-updater

Unofficial helper to update the official Cursor Linux `.deb` and relaunch via your desktop session.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/alkitect/?hidefeed=true&widget=true&embed=true)

## What this does

Cursor ships a Linux `.deb`, but there is no separate CLI updater for it. This kit downloads the official package from Cursor’s API, installs it with `apt`/`dpkg`, and relaunches Cursor the way the app menu would — forwarding your Wayland/X11 session environment.

**Safe by default:** install does not enable passwordless sudo or replace your `cursor.desktop`. Run verify first; opt in to launcher integration or NOPASSWD only when you want them.

## Who this is for

- **In:** Ubuntu/Debian users who already installed Cursor from the official **`.deb`** (cursor.com/download) and want a terminal or app-grid update path that relaunches with session DPI
- **In:** GNOME on x64 (validated); arm64 is best-effort
- **Not for:** AppImage, snap, or Flatpak installs; RPM/Fedora; an official Anysphere product; generic multi-app deb updaters; linux-app-scale itself

**Prerequisite:** official Cursor **`.deb`** already installed on this machine.

## Quick start

```bash
git clone https://github.com/alkitect/cursor-deb-updater.git
cd cursor-deb-updater
./scripts/install-to-local.sh
./scripts/verify-cursor-deb-updater
cursor-deb-updater
```

**What you installed:** `cursor-deb-updater`, `cursor-deb-updater-ui`, and `verify-cursor-deb-updater` in `~/.local/bin`, plus config under `~/.config/cursor-deb-updater/`.

**Stay safe before enabling:** default install writes **no** sudoers file and **no** local `cursor.desktop`. Sudo may prompt when you run an update from a terminal.

**Needs:** Linux with `curl` or `wget`, `sudo`, and the official Cursor `.deb`. Run updates from a normal terminal (not from inside Cursor if you cannot afford closing all windows).

## Check it works

Glue is installed when `verify-cursor-deb-updater` exits 0. User success is running `cursor-deb-updater` from a terminal when an update exists (or “already on latest” when current).

```bash
verify-cursor-deb-updater
```

- If verify warns about packaging: install the official Cursor `.deb` first, or use `--strict` only when debugging.
- If update fails on sudo: run from a TTY terminal or see Configure for passwordless sudo.

Maintainers: `./scripts/ci-check.sh`.

## Uninstall

```bash
./scripts/uninstall-from-local.sh
# optional: --purge-config
```

Removes glue binaries and an integrated desktop this tool created. The Cursor application stays installed.

## Configure

Optional flags at install time:

```bash
./scripts/install-to-local.sh --enable-passwordless-sudo
./scripts/install-to-local.sh --integrate-launcher
./scripts/install-to-local.sh --integrate-launcher --force   # backup foreign cursor.desktop first
```

UI mode (terminal vs silent background updates):

```bash
cursor-deb-updater-ui terminal   # or silent / status
```

Config file `~/.config/cursor-deb-updater/config` supports `RELEASE_TRACK=latest` or `stable`. Preview an update without closing Cursor:

```bash
cursor-deb-updater --dry-run
```

## Limits & safety

This is **not affiliated with Anysphere or Cursor**. It does not relicense Cursor and does not vendor Cursor binaries.

- **Platform:** official `.deb` on Debian/Ubuntu; packaging gate refuses snap/AppImage/Flatpak wrappers
- **Kill-switch:** uninstall glue; optionally `sudo rm /etc/sudoers.d/cursor-deb-updater`
- **Defaults:** HTTPS allowlist on initial and post-redirect download URLs; interactive sudo when NOPASSWD is absent
- **Tradeoff:** updates run `pkill -x cursor` before install — closes every Cursor window; API/CDN shape may change
- This GitHub repo is the release source for tagged releases — see [CONTRIBUTING.md](CONTRIBUTING.md)

## License

MIT — see [LICENSE](LICENSE).

Optional tip jar: [ko-fi.com/alkitect](https://ko-fi.com/alkitect/?hidefeed=true&widget=true&embed=true)
