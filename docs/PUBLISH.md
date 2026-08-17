# Publish notes

Before tag: README must pass `./scripts/ci-check.sh`. See [CONTRIBUTING.md](../CONTRIBUTING.md).

First public tag: v0.1.0

**v0.1.0 scope:** glue + CI green + verify exits 0 in stub environment. **Not** a production soak for “DPI matches app menu after real update” — target that for **v1.0.0** on a machine with the official `.deb`.

Never copy another alkitect repo’s tag. Do not use `RC-BEFORE-1.0` unless intentionally shipping a 0.9.x RC.

```bash
./scripts/ci-check.sh
git tag -a v0.1.0 -m "v0.1.0"
git push origin main
git push origin v0.1.0
gh release create v0.1.0 --verify-tag
```

Repo URL: `https://github.com/alkitect/cursor-deb-updater`

## GitHub About

| Field | Value |
|-------|--------|
| Description | Unofficial helper — update the official Cursor Linux .deb and relaunch via the desktop session (not affiliated with Anysphere) |
| Website | _(empty — tip via README Ko-fi badge)_ |
| Topics | `cursor`, `linux`, `debian`, `ubuntu`, `deb`, `gnome`, `electron`, `updater` |

```bash
gh repo create cursor-deb-updater --public --source=. --remote=origin
gh repo edit alkitect/cursor-deb-updater \
  --description "Unofficial helper — update the official Cursor Linux .deb and relaunch via the desktop session (not affiliated with Anysphere)" \
  --homepage "" \
  --add-topic cursor --add-topic linux --add-topic debian --add-topic ubuntu \
  --add-topic deb --add-topic gnome --add-topic electron --add-topic updater
```

Sidebar (manual if shown): Releases ✓ · Packages ✗ · Deployments ✗

## Linux monorepo submodule (human gate)

After GitHub is live:

```bash
cd /path/to/Linux
git submodule add -b v0.1.0 https://github.com/alkitect/cursor-deb-updater.git public/cursor-deb-updater
```

Pin submodule gitlink to tag `v0.1.0`, not `main`.
