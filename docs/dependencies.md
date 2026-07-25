# Dependencies

## Policy

This repository records configuration, not machine package state. Dependencies
follow current upstream releases: there are no platform package manifests,
version locks, or vendored toolchains here. Fixed version numbers below are
minimum compatibility requirements, not pins.

Machine provisioning belongs in the separate repository at
`~/programs/workstation`. Add or change operating-system package recipes there
rather than duplicating them in this repository.

## Baseline

| Tool | Requirement | Used for |
| --- | --- | --- |
| Bash | A Bash-compatible environment | `install.sh`, checks, and shell configuration |
| GNU Stow | Current release | Linking every package listed in `packages/stow` |
| Vim | 9.1 or later | Bundled EditorConfig support and the Vim configuration |
| Emacs | 30.1 or later | Bundled EditorConfig support and the Emacs configuration |
| tmux | Current release | tmux configuration and shell-history integration checks |
| LLVM | Current release | `clangd`, `clang-format`, and `clang-tidy` integration |

The GitHub Actions check runs on `macos-latest` and installs the unversioned
Homebrew formulas for Stow, Vim, Emacs, tmux, and LLVM. This keeps CI on the
same rolling policy instead of creating a second pinned dependency set.

Git is needed to clone and work on the repository, and Make provides the
convenience targets. A C and C++ compiler is needed for the editor build
mappings and their checks.

## Optional integrations

The core configurations still load when these tools are absent. Their related
features activate when the executable or package is available.

| Configuration | Optional dependency | Effect |
| --- | --- | --- |
| Bash | `direnv` | Loads the directory-specific environment hook |
| Bash | `zoxide` | Loads smarter directory navigation |
| Git | Delta | Uses the configured colour-aware pager instead of the standard fallback |
| Vim and Emacs | `clangd` | Enables C/C++ language-server features |
| Vim and Emacs | `clang-format` | Formats C/C++ buffers with the shared style |
| Emacs | Ripgrep | Enables `consult-ripgrep` search |
| C/C++ | GDB | Uses the managed GDB defaults and history location |

For best language-server results, each C/C++ project should provide its own
`compile_commands.json` or `compile_flags.txt`. These dotfiles deliberately do
not inject project paths or a platform SDK.

## Editor packages

Vim starts without downloading anything. Plugin support is optional and uses
vim-plug under the XDG data directory. The configured plugins are
`vim-sensible`, `vim-surround`, `vim-commentary`, `vim-gitgutter`, CtrlP, and
ALE. Provision them explicitly from the workstation repository:

```sh
make -C ~/programs/workstation vim-plugins
```

This command also requires `curl`. Vim's C/C++ language-server, formatting,
and related mappings require ALE.

Emacs startup likewise stays offline and skips unavailable optional packages.
Its explicit package set includes Vertico, Marginalia, Orderless, Consult,
Corfu, Magit, `exec-path-from-shell`, and Markdown, YAML, and JSON modes.
Provision that set explicitly when network access is intended:

```sh
make -C ~/programs/workstation emacs-packages
```

EditorConfig itself is built into the supported Vim and Emacs versions; it
does not need an external plugin.
