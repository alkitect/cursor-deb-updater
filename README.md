# cursor-deb-updater

Download the official Cursor Linux `.deb`, install it with apt/dpkg, and relaunch with your Wayland or X11 session environment.

[Quick start](#quick-start) · [Releases](https://github.com/alkitect/cursor-deb-updater/releases) · [License](#license)

Latest release notes: [CHANGELOG.md](CHANGELOG.md) and [GitHub Releases](https://github.com/alkitect/cursor-deb-updater/releases). A plain `git clone` follows the default branch tip unless you check out a tag; prefer a tagged release for day-to-day use.

## What this does

Cursor ships a Linux `.deb`. On recent builds the package postinst also configures Anysphere's APT repository (`downloads.cursor.com/aptrepo`), and the app tells you when a newer package is available via apt.

This kit checks for updates on launch (or from a terminal), installs them, and relaunches Cursor the way the app menu would, forwarding your Wayland/X11 session environment.

By default it compares the Cursor aptrepo Candidate with the download API and installs from whichever reports the newer version (apt on a tie). If aptrepo is missing, it uses the download API only.

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

You should see an apt or download/install path when an update exists, or "already on latest" when current. If update fails on sudo, run from a TTY terminal or see Configure for passwordless sudo.

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

UI mode (silent desktop install vs terminal for sudo prompts):

```bash
cursor-deb-updater-ui silent     # default: app-grid installs then relaunches
cursor-deb-updater-ui terminal   # open a terminal when sudo needs a password
cursor-deb-updater-ui status
```

Desktop launches install the newer apt/API build before Cursor starts when passwordless sudo is configured (`--enable-passwordless-sudo` or `setup-passwordless-sudo.sh`). Without it, silent mode errors; terminal mode opens a window so sudo can prompt.

Config file `~/.config/cursor-deb-updater/config`:

```bash
UPDATE_CHANNEL=auto    # auto | apt | api  (auto picks newer of aptrepo vs API)
RELEASE_TRACK=latest     # download API only: latest | stable
```

Re-running `install-to-local.sh` appends `UPDATE_CHANNEL=auto` if your older config lacks it.

## Limits & safety

This is not affiliated with Anysphere or Cursor. It does not relicense Cursor and does not vendor Cursor binaries.

- Platform: official `.deb` on Debian/Ubuntu; packaging gate refuses snap/AppImage/Flatpak wrappers.
- Kill-switch: uninstall glue; optionally `sudo rm /etc/sudoers.d/cursor-deb-updater`.
- Defaults: compare aptrepo vs download API and install from the newer source; HTTPS allowlist on API download URLs; interactive sudo when NOPASSWD is absent.
- Tradeoff: updates run `pkill -x cursor` before install (closes every Cursor window); apt metadata refresh can fail under PackageKit locks; API/CDN shape may change.
- Optional: if a Chromium-flag launch wrapper exists next to the updater under `~/.local/bin`, relaunch uses it so host ozone flags still apply.
- This GitHub repo is the release source for tagged releases. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).

Optional tip jar: [ko-fi.com/alkitect](https://ko-fi.com/alkitect/?hidefeed=true&widget=true&embed=true)
