# Contributing

## README conventions

Public README required H2s (enforced by `./scripts/ci-check.sh`):

```text
## What this does
## Who this is for
## Quick start
## Check it works
## Uninstall
## Limits & safety
## License
```

Also enforced: `.github/FUNDING.yml` with `ko_fi: alkitect`, Ko-fi badge in README, no `SSOT` token, no monorepo paths in public docs.

Gate: `./scripts/ci-check.sh`.

## Versioning

First public tag is recorded in `docs/PUBLISH.md` (`First public tag:`). Default is **0.1.0**. Never copy another alkitect repo’s tag. After the first tag, bump from CHANGELOG Unreleased (`feat` → minor, `fix` → patch).

## Bug reports

Please include:

- Distro and desktop (expect Ubuntu GNOME)
- Output of `cursor --version` and `dpkg -S /usr/share/cursor/cursor` (or packaging gate message)
- Whether you use integrated launcher or terminal-only updates
- Relevant lines from `~/.config/cursor-deb-updater/updater.log`

## Behavior changes

Update [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md) when changing check/install phases, sudo policy, allowlist, or launch behavior.

Run before PR:

```bash
find scripts -type f \( -name '*.sh' -o -name 'cursor-deb-updater' -o -name 'cursor-deb-updater-ui' \) -print0 | xargs -0 -r bash -n
./scripts/ci-check.sh
```

## Maintenance

After the first public tag, edit **this** repository only.

## Safety defaults

Default `install-to-local.sh` must not write sudoers or replace `cursor.desktop`. Opt-in flags stay explicit.
