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
│       └── lisp/
│           ├── dotfiles-format.el
│           └── dotfiles-packages.el
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

The bundled EditorConfig integration targets Vim 9.1 or newer and Emacs 30.1
or newer. Older releases can still load the core settings, but do not provide
that integration without an external plugin.

Preview the selected package-manager action without changing the machine:

```sh
./bootstrap/bootstrap.sh --dry-run
# or: make packages-dry-run
```

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

Use `./install.sh --help` for the full command surface. A Stow-only preview does
not create a missing target or move existing files:

```sh
./install.sh --dry-run
# or: make install-dry-run
```

`packages/stow` is the single allowlist used by both commands. The installer
rejects unknown package names and unrecognized options before touching the
target. Set `DOTFILES_TARGET` to install into another home-shaped directory; the
directory is created when needed:

```sh
DOTFILES_TARGET=/tmp/dotfiles-home ./install.sh
```

Before Stow changes anything, the installer runs a dry preflight. Existing
`.bashrc`, `.bash_profile`, and `.config/git/config` files are backed up on a
successful install; if a later conflict prevents installation, those moves are
rolled back. Other conflicts are left untouched and reported by Stow.

Machine-local Bash settings and mutable Vim data are excluded from Stow packages,
so installing into another target does not copy private runtime state from this
checkout. By default, Vim plugins live under `~/.local/share/vim`, persistent
undo under `~/.local/state/vim`, and backup and swap data under
`~/.cache/vim`. For real-home installs, absolute `XDG_*_HOME` values override
those roots; alternate targets remain self-contained.
If an older install folded the Bash config or a Vim runtime directory into the
checkout, the next corresponding install moves those contents to the target's
local or XDG path while unfolding the legacy link. State left in real
`~/.vim/{autoload,plugged,undo,backup,swap}` directories by an earlier installer
is migrated too. If both a checkout directory and its real `~/.vim` counterpart
contain data, installation stops before changing either copy so they can be
reconciled explicitly.

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

Installing links never changes graphical settings. Apply the installed Terminal
profile selection and wallpaper explicitly on macOS with:

```sh
make apply-visuals
```

This is equivalent to `./install.sh --apply-visuals terminal wallpaper`.
Alternate `DOTFILES_TARGET` installs never change desktop settings.

## Check

Run the hermetic configuration and template checks with:

```sh
make check
```

This is also the default `make` target. It installs twice into a temporary home,
checks Stow isolation, dry runs, and conflict rollback, loads the Bash, Vim, and
tmux configuration, starts Emacs with package networking disabled, exercises
EditorConfig, Git, formatting, and Clang-Tidy, and runs each available
project-template test suite. Test targets and language build caches stay under
a temporary directory; the check does not change live dotfiles or apply macOS
desktop settings.

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
C-c R     rename with Eglot
C-c a     show Eglot code actions
```

```text
vim prefix: <leader> is Space

<leader>w       write file
<leader>q       quit
<leader>e       file explorer
<leader>p       file picker
<leader><space> clear search highlight

<C-h>           move to left split
<C-j>           move to lower split
<C-k>           move to upper split
<C-l>           move to right split

<leader>m       run make
<leader>b       build current C/C++ file
<leader>x       run current C/C++ output
<leader>f       format/fix with ALE
<leader>d       show diagnostic detail
<leader>rn      rename symbol with ALE
<leader>a       code action
<leader>gd      go to definition
<leader>gr      find references
<leader>gh      hover detail
[d              previous diagnostic
]d              next diagnostic
```

ALE marks diagnostics in the gutter and under the relevant token, then echoes
the current-line message. Inline diagnostic text and automatic hover are
disabled; use `<leader>d` and `<leader>gh` when you want the full details.

## Vim

The `vim` package provides:

```text
~/.vimrc
~/.vim/after/ftplugin/c.vim
```

The shared C/C++ ftplugin uses Vim's GCC compiler parser, keeps comments from
wrapping automatically, and provides the same build keys in every repository.
Vim's bundled EditorConfig support applies project and global indentation rules.

After installing the package, install Vim plugins:

```sh
make vim-plug
make vim-plugins
```

`make vim-plug` installs the manager under an absolute `XDG_DATA_HOME`, or
`~/.local/share` when it is unset or relative. Plugins are stored beside it in
the Vim data directory.

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
~/.config/bash/local.bash.example
~/.config/bash/prompt.bash
```

Put machine-specific shell setup in `~/.config/bash/local.bash`. That file is
ignored by Git and excluded from Stow, so it remains local to one target.
Interactive shells append and reload history at each prompt, so commands remain
visible across tmux panes. The lightweight zoxide and direnv hooks activate when
their executables are installed; the prompt itself remains plain Bash.

## Terminal

The `terminal` package provides:

```text
~/.config/terminal/style
~/.config/terminal/apply
```

On macOS, `style` contains the Apple Terminal profile name to select. The default
is the built-in `Basic` profile. Apply it with:

```sh
~/.config/terminal/apply
```

Applying the profile opens Terminal.app if it is not already running. The file
selects a profile; it does not replace or import Terminal's profile database.

## Wallpaper

The `wallpaper` package provides:

```text
~/.config/wallpaper/desktop.webp
~/.config/wallpaper/apply
```

On macOS, `apply` sets `desktop.webp` as the picture for every connected
display's Desktop. Package bootstrap and link installation leave it unchanged
until this helper or `make apply-visuals` is run explicitly.

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
~/.emacs.d/lisp/dotfiles-packages.el
```

Normal startup activates installed packages but never refreshes archives or
installs anything, so it remains usable offline and degrades cleanly when an
optional package is missing. Provision the external packages explicitly after
stowing the package:

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
~/.config/gdb/gdbinit
```

`~/.clang-format` defines the formatting style used by `clang-format` and Vim's
`<leader>f` mapping.

`~/.clang-tidy` enables analyzer, bug-finding, and performance checks. Broad
style-only modernization, readability, and C++ Core Guidelines families remain
disabled.

Project compilation flags belong in each repository's `compile_flags.txt` or
`compile_commands.json`; the portable dotfiles do not inject project paths or a
macOS SDK into clangd.

`~/.config/gdb/gdbinit` sets practical GDB defaults and stores command history
at `~/.cache/gdb/history`.

## EditorConfig

The `editorconfig` package provides:

```text
~/.editorconfig
```

It sets UTF-8, LF line endings, final newlines, trailing-whitespace trimming,
two-space defaults, and four-space overrides for C, C++, Python, Rust, and
related source files. Makefiles and `*.mk` files preserve tab recipes. Vim 9.1+
and Emacs 30.1+ both enable their bundled EditorConfig support; no extra editor
plugin is needed.
