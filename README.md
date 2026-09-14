# cursor-deb-updater

Download the official Cursor Linux `.deb`, install it with apt/dpkg, and relaunch with your Wayland or X11 session environment.

[Quick start](#quick-start) · [Releases](https://github.com/alkitect/cursor-deb-updater/releases) · [License](#license)

Latest release notes: [CHANGELOG.md](CHANGELOG.md) and [GitHub Releases](https://github.com/alkitect/cursor-deb-updater/releases). A plain `git clone` follows the default branch tip unless you check out a tag; prefer a tagged release for day-to-day use.

## What this does

Cursor ships a Linux `.deb`, but there is no separate CLI updater for it. You either wait on the in-app prompt or dig through the download page again.

This kit downloads the official package from Cursor's API, installs it with `apt`/`dpkg`, and relaunches Cursor the way the app menu would, forwarding your Wayland/X11 session environment.

Safe by default: install does not enable passwordless sudo or replace your `cursor.desktop`. Run verify first; opt in to launcher integration or NOPASSWD only when you want them.

## Who this is for

This is for Ubuntu/Debian users who already installed Cursor from the official `.deb` (cursor.com/download) and want a terminal or app-grid update path that relaunches with session DPI. GNOME on x64 is validated; arm64 is best-effort.

It is not for AppImage, snap, or Flatpak installs; RPM/Fedora; an official Anysphere product; generic multi-app deb updaters; or linux-app-scale itself. You need the official Cursor `.deb` already on this machine.

## Quick start

Install puts `cursor-deb-updater`, `cursor-deb-updater-ui`, and `verify-cursor-deb-updater` in `~/.local/bin`, plus config under `~/.config/cursor-deb-updater/`. Default install writes no sudoers file and no local `cursor.desktop`. Sudo may prompt when you run an update from a terminal.

Then: [Install](#install) → [Verify layout](#verify-layout) → [Dry-run / first update](#dry-run--first-update) → [Run updater](#run-updater).

### Install

Needs: Linux with `curl` or `wget`, `sudo`, and the official Cursor `.deb`. Prefer a normal terminal (not from inside Cursor if you cannot afford closing all windows).

Stable path: clone or download a release tag from [Releases](https://github.com/alkitect/cursor-deb-updater/releases), then run the install script. Tip of the default branch is fine for contributors.

```bash
git clone https://github.com/alkitect/cursor-deb-updater.git
cd cursor-deb-updater
# optional: git checkout vX.Y.Z   # pin to a release tag
./scripts/install-to-local.sh
```

### Verify layout

```bash
verify-cursor-deb-updater
```

Glue is installed when that exits 0. If it warns about packaging, install the official Cursor `.deb` first, or use `--strict` only when debugging.

### Dry-run / first update

A real update runs `pkill -x cursor` before install, which closes every Cursor window. Preview first:

```bash
cursor-deb-updater --dry-run
```

### Run updater

```bash
cursor-deb-updater
```

You should see a download/install path when an update exists, or "already on latest" when current. If update fails on sudo, run from a TTY terminal or see Configure for passwordless sudo.

## Check it works

User success is running `cursor-deb-updater` from a terminal when an update exists (or "already on latest" when current), after verify exits 0.

<details>
<summary>Optional confirmation</summary>

```bash
verify-cursor-deb-updater
./scripts/ci-check.sh
```

</details>

Questions or a stuck install: open a GitHub [Issue](https://github.com/alkitect/cursor-deb-updater/issues) or see [CONTRIBUTING.md](CONTRIBUTING.md).

## Support my work

Tip jar for the next desktop fix. Or a coffee so the next script stays boring on purpose.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/alkitect/?hidefeed=true&widget=true&embed=true)

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

Config file `~/.config/cursor-deb-updater/config` supports `RELEASE_TRACK=latest` or `stable`.

## Limits & safety

This is not affiliated with Anysphere or Cursor. It does not relicense Cursor and does not vendor Cursor binaries.

- Platform: official `.deb` on Debian/Ubuntu; packaging gate refuses snap/AppImage/Flatpak wrappers.
- Kill-switch: uninstall glue; optionally `sudo rm /etc/sudoers.d/cursor-deb-updater`.
- Defaults: HTTPS allowlist on initial and post-redirect download URLs; interactive sudo when NOPASSWD is absent.
- Tradeoff: updates run `pkill -x cursor` before install (closes every Cursor window); API/CDN shape may change.
- This GitHub repo is the release source for tagged releases. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).

Optional tip jar: [ko-fi.com/alkitect](https://ko-fi.com/alkitect/?hidefeed=true&widget=true&embed=true)
