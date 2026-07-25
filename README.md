# Dotfiles

Stow-managed dotfiles. Most top-level directories are Stow packages that map
into `$HOME`; `bootstrap/`, `packages/`, and `templates/` define machine and
project setup.

```text
.
├── Makefile
├── README.md
├── bootstrap/
│   ├── bootstrap.sh
│   └── install.sh
├── packages/
│   ├── common.cli
│   ├── work.cli
│   ├── personal.cli
│   ├── stow
│   ├── macos.brewfile
│   ├── linux.apt
│   └── linux.pacman
├── tests/
│   └── check.sh
├── templates/
│   ├── python/
│   ├── node/
│   ├── rust/
│   ├── go/
│   └── shell/
├── repos/
│   ├── README.md
│   ├── stdmk/
│   └── mkskel/
├── install.sh
├── bash/
│   ├── .bash_profile
│   ├── .bashrc
│   └── .config/bash/
│       ├── aliases.bash
│       ├── functions.bash
│       ├── local.bash.example
│       └── prompt.bash
├── git/
│   └── .config/git/
│       ├── config
│       └── pager
├── cpp/
│   ├── .clang-format
│   ├── .clang-tidy
│   └── .config/gdb/gdbinit
├── editorconfig/
│   └── .editorconfig
├── emacs/
│   └── .emacs.d/
│       ├── early-init.el
│       ├── init.el
│       └── lisp/dotfiles-format.el
├── terminal/
│   └── .config/terminal/
│       ├── apply
│       └── style
├── wallpaper/
│   └── .config/wallpaper/
│       ├── apply
│       └── desktop.webp
├── tmux/
│   └── .tmux.conf
└── vim/
    ├── .vimrc
    └── .vim/
        └── after/ftplugin/
```

## Install

Install OS packages:

```sh
./bootstrap/bootstrap.sh
```

The desired CLI state is explicit in `packages/`:

```text
packages/common.cli      baseline tools
packages/work.cli        development tools
packages/personal.cli    interactive personal tools
packages/stow            dotfile packages accepted by install.sh
packages/macos.brewfile  Homebrew / Linuxbrew package manifest
packages/linux.apt       Debian / Ubuntu package manifest
packages/linux.pacman    Arch Linux package manifest
```

The bootstrap script uses the matching package-manager manifest for the current
machine. Linux package managers install the packages available from their
repositories and report names they cannot resolve.

The same bootstrap is available through Make:

```sh
make packages
```

Project templates are plain directories:

```sh
cp -R templates/python ~/programs/new-python-project
```

Available templates:

```text
templates/python
templates/node
templates/rust
templates/go
templates/shell
```

Related project skeleton repos live under `repos/` as independent nested Git
repositories:

- `repos/stdmk`: standard Unix-shaped repository surface: `./configure`,
  `make`, `make check`, `make install`, `make clean`, and `make distclean`.
- `repos/mkskel`: language-extensible coding workstation with short make
  commands, source/test separation, cached builds, and bundle/run helpers.

Install all packages:

```sh
./install.sh
```

Or:

```sh
make install
```

`packages/stow` is the single allowlist used by both commands. The installer
rejects unknown names and option-like arguments before touching the target. Set
`DOTFILES_TARGET` to install into another home-shaped directory; the directory
is created when needed:

```sh
DOTFILES_TARGET=/tmp/dotfiles-home ./install.sh
```

Before Stow changes anything, the installer runs a dry preflight. Existing
`.bashrc`, `.bash_profile`, and `.config/git/config` files are backed up on a
successful install; if a later conflict prevents installation, those moves are
rolled back. Other conflicts are left untouched and reported by Stow.

Machine-local Bash settings and mutable Vim plugin, undo, backup, and swap data
are excluded from Stow packages, so installing into another target does not copy
private runtime state from this checkout. If an older install folded the Bash
config or one of those Vim directories into the checkout, the next corresponding
install preserves those contents while unfolding the legacy link into
target-local paths.

Install selected packages:

```sh
./install.sh vim
./install.sh bash
./install.sh git
./install.sh cpp
./install.sh emacs
./install.sh tmux
./install.sh editorconfig
./install.sh terminal
./install.sh wallpaper
```

The bootstrap install wrapper is equivalent:

```sh
./bootstrap/install.sh vim cpp emacs
```

The installer uses GNU Stow, so install it first if needed:

```sh
# macOS
brew install stow

# Debian / Ubuntu
sudo apt install stow
```

When the `terminal` or `wallpaper` package is installed directly into the real
home directory on macOS, its `apply` helper also runs. Alternate
`DOTFILES_TARGET` installs never change desktop settings.

## Check

Run the hermetic configuration and template checks with:

```sh
make check
```

This is also the default `make` target. It installs twice into a temporary home,
checks Stow isolation and conflict rollback, loads the Bash, Vim, and tmux
configuration, parses the Git, Emacs, and Clang configuration, exercises the
Git pager and Emacs formatter, and runs each available project-template test
suite. Test targets and language build caches stay under a temporary directory;
the check does not change live dotfiles or apply macOS desktop settings.

## Keys

Notation: `C-x` means Control-x, `M-x` means Meta-x, and Vim's `<leader>` is
the space key.

```text
tmux prefix: C-b

C-b d     detach from tmux
C-b c     new window
C-b n     next window
C-b p     previous window
C-b 1     go to window 1
C-b ,     rename window
C-b &     kill window

C-b -     split pane vertically
C-b |     split pane horizontally
C-b h     move left
C-b j     move down
C-b k     move up
C-b l     move right
C-b x     kill current pane
C-b z     zoom/unzoom pane

C-b [     scroll/copy mode
q         leave scroll/copy mode
C-b ?     show all keybindings
C-b :     tmux command prompt
C-b r     reload ~/.tmux.conf
```

```text
emacs prefixes: C-x, C-c, M-x

C-x C-f   open file
C-x C-s   save file
C-x C-c   quit Emacs
C-g       cancel current prompt
M-x       run command by name

C-c s     save buffer
C-c k     kill current buffer
C-c e     open init.el
C-s       search current buffer
C-x b     switch buffer
C-c f     find file
C-c r     ripgrep search
C-c g     Git status
C-c p     project commands
C-c m     compile
C-c M     recompile
C-c !     show diagnostics
M-n       next diagnostic
M-p       previous diagnostic
C-c C-f   format C/C++ buffer
```

```text
vim prefix: <leader> is Space

<leader>w       write file
<leader>q       quit
<leader>e       file explorer
<leader>p       file picker
<leader><space> clear search highlight
jk              leave insert mode

<C-h>           move to left split
<C-j>           move to lower split
<C-k>           move to upper split
<C-l>           move to right split

<leader>m       run make
<leader>b       build current C/C++ file
<leader>x       run current C/C++ output
<leader>f       format/fix with ALE
<leader>d       show diagnostic detail
<leader>a       code action
<leader>gd      go to definition
<leader>gr      find references
<leader>gh      hover detail
[d              previous diagnostic
]d              next diagnostic
```

## Vim

The `vim` package provides:

```text
~/.vimrc
~/.vim/after/ftplugin/c.vim
~/.vim/after/ftplugin/cpp.vim
```

After installing the package, install Vim plugins:

```sh
make vim-plug
make vim-plugins
```

Install the external tools Vim calls:

```sh
./bootstrap/bootstrap.sh
```

Those tools are listed in `packages/work.cli` and resolved through the
package-manager manifests.

For best C/C++ results, generate `compile_commands.json` in each project. With CMake:

```sh
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

## Shell

The `bash` package provides:

```text
~/.bash_profile
~/.bashrc
~/.config/bash/aliases.bash
~/.config/bash/functions.bash
~/.config/bash/local.bash.example
~/.config/bash/prompt.bash
```

Put machine-specific shell setup in `~/.config/bash/local.bash`. That file is
ignored by Git and excluded from Stow, so it remains local to one target.

## Terminal

The `terminal` package provides:

```text
~/.config/terminal/style
~/.config/terminal/apply
```

On macOS, `style` contains the Apple Terminal profile name to use. The default
is `Basic`, the standard white Terminal style. Apply it with:

```sh
~/.config/terminal/apply
```

## Wallpaper

The `wallpaper` package provides:

```text
~/.config/wallpaper/desktop.webp
~/.config/wallpaper/apply
```

On macOS, `apply` sets `desktop.webp` as the picture for every Desktop. The
bootstrap script also applies it during first laptop setup.

## Git

The `git` package provides:

```text
~/.config/git/config
~/.config/git/pager
```

Git identity can stay in `~/.gitconfig`; the managed config adds diff, merge,
and short aliases. Its pager uses Delta when available and falls back to
standard tools when Delta has not been installed yet.

## Emacs

The `emacs` package provides:

```text
~/.emacs.d/early-init.el
~/.emacs.d/init.el
~/.emacs.d/lisp/dotfiles-format.el
```

The configuration bootstraps `package.el` with GNU ELPA, NonGNU ELPA, and MELPA,
then installs its declared packages on first launch. To install packages from the
command line after stowing the package:

```sh
make emacs-packages
```

Install the external tools Emacs calls:

```sh
# Debian / Ubuntu
sudo apt install emacs clangd clang-format ripgrep

# macOS with Homebrew
brew install emacs llvm ripgrep
```

The C/C++ configuration uses `clangd` through Eglot when `clangd` is available
and binds `C-c C-f` to format the current buffer with `clang-format`. Formatting
is applied only after the formatter exits successfully, so a tool failure
cannot erase the original buffer.

## Tmux

The `tmux` package provides:

```text
~/.tmux.conf
```

Reload the config inside a running tmux server:

```sh
make tmux-reload
```

Install tmux first if needed:

```sh
# Debian / Ubuntu
sudo apt install tmux

# macOS with Homebrew
brew install tmux
```

## C/C++ Tooling

The `cpp` package provides:

```text
~/.clang-format
~/.clang-tidy
~/.config/clangd/config.yaml
~/.config/gdb/gdbinit
~/Library/Preferences/clangd/config.yaml
```

`~/.clang-format` defines the formatting style used by `clang-format` and Vim's
`<leader>f` mapping.

`~/.clang-tidy` enables Clang-Tidy checks for common bug, performance,
modernization, readability, and C++ Core Guidelines diagnostics.

`~/.config/gdb/gdbinit` sets practical GDB defaults and stores command history
at `~/.cache/gdb/history`.

## EditorConfig

The `editorconfig` package provides:

```text
~/.editorconfig
```

It sets UTF-8, LF line endings, final newlines, trailing-whitespace trimming,
two-space defaults, and four-space overrides for C, C++, Python, Rust, and
related source files.
