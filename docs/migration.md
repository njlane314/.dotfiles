# Migration and recovery

The current installer is intentionally small: it validates the package
allowlist, preflights GNU Stow, preserves conventional entry-file conflicts,
and creates empty editor state directories. Deployments made before July 2026
must use the one-time migration before installing the current layout.

## One-time July 2026 migration

Preview the migration first:

```sh
./migrations/2026-07-xdg-state.sh --dry-run
```

The script unfolds legacy Bash and Vim links, preserves machine-local
`local.bash`, and moves mutable Vim directories to their XDG data, state, and
cache locations. It refuses to merge when both a Vim source directory and its
destination are non-empty; reconcile those directories manually and preview
again.

When the preview is correct, run the migration and then the installer:

```sh
./migrations/2026-07-xdg-state.sh
./install.sh
```

Use the same `DOTFILES_TARGET` for every command when migrating an existing
alternate home-shaped target:

```sh
DOTFILES_TARGET=/path/to/existing-home ./migrations/2026-07-xdg-state.sh --dry-run
DOTFILES_TARGET=/path/to/existing-home ./migrations/2026-07-xdg-state.sh
DOTFILES_TARGET=/path/to/existing-home ./install.sh
```

This script is temporary compatibility code, not part of a fresh install. The
sunset target is **2027-01-31**, after every managed machine has completed and
verified the migration.

## Existing configuration files

For `~/.bashrc`, `~/.bash_profile`, and `~/.config/git/config`, the installer
turns an identical file into a link without keeping a duplicate. A different
file is retained beside the new link with a
`.before-dotfiles-YYYYMMDDHHMMSS` suffix. Other Stow conflicts are reported
without being moved.

If a later conflict causes installation to fail, automatic moves from that run
are rolled back. A backup from a successful install remains for manual review.

## Repository split

Machine bootstrap scripts and platform package manifests are maintained at
`~/programs/workstation`; project templates are maintained at `~/src/mkskel`.
Neither is installed or updated by this repository.

Terminal and wallpaper packages from the earlier broad repository are no
longer managed here. Updating the checkout does not remove links created by a
removed package. Inspect old `~/.config/terminal` and
`~/.config/wallpaper` links, removing only links that still point into the old
dotfiles package when that configuration is no longer wanted.
