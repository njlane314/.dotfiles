# Dotfiles

Personal configuration files linked into a home directory with GNU Stow.
This repository deliberately has a narrow contract: it owns the configuration
below and installs links to it. It does not provision a workstation, maintain
project templates, manage nested repositories, or apply graphical settings.

## Managed packages

[`packages/stow`](packages/stow) is the single allowlist accepted by
`install.sh`. Each name identifies a top-level Stow package.

| Package | Main paths |
| --- | --- |
| `bash` | `~/.bash_profile`, `~/.bashrc`, `~/.config/bash/` |
| `git` | `~/.config/git/` |
| `vim` | `~/.vimrc`, `~/.vim/after/ftplugin/` |
| `cpp` | `~/.clang-format`, `~/.clang-tidy`, `~/.config/gdb/gdbinit` |
| `emacs` | `~/.emacs.d/` |
| `tmux` | `~/.tmux.conf` |
| `editorconfig` | `~/.editorconfig` |

Machine-local settings, editor plugins, caches, history, undo data, backups,
and other mutable state are not Stow-managed configuration.

## Install

Install GNU Stow first, then run from this checkout:

```sh
./install.sh --dry-run
./install.sh
```

The first command previews the Stow operation without creating a missing
target or moving an existing file. With no package arguments, the installer
uses the complete `packages/stow` allowlist. Pass names to install only a
subset:

```sh
./install.sh vim cpp editorconfig
```

Unknown packages and unrecognised options fail before Stow changes the target.
Use `DOTFILES_TARGET` for an alternate home-shaped directory:

```sh
DOTFILES_TARGET=/tmp/dotfiles-home ./install.sh --dry-run
```

Existing configurations and installations from earlier revisions need a
little more context; see [migration and recovery](docs/migration.md).

## Dependencies

Dependencies roll with their upstream package sources rather than being pinned
in this repository. Vim 9.1 or later and Emacs 30.1 or later are the supported
editor baselines; both include the EditorConfig integration used here.

The complete tool and optional editor-package policy is in
[dependencies](docs/dependencies.md). Machine provisioning belongs in the
separate repository at `~/programs/workstation`.

## Check

Run the configuration checks with:

```sh
make check
```

The suite installs into temporary home directories, checks Stow isolation and
conflict handling, and loads the managed shell, editor, Git, tmux, and C/C++
configuration without changing the live home directory.

## Reference

- [Dependencies](docs/dependencies.md)
- [Keybindings](docs/keybindings.md)
- [Migration and recovery](docs/migration.md)

Project templates now live in the separate repository at `~/src/mkskel`.

## Licence

No licence has been selected. The licensing question remains explicitly
unresolved, so this repository intentionally contains no licence file.
