# Dotfiles

Stow-managed dotfiles. Each top-level directory is a package that maps into
`$HOME`.

```text
.
├── Makefile
├── README.md
├── Brewfile
├── bootstrap/
│   ├── bootstrap.sh
│   └── install.sh
├── install.sh
├── bash/
│   ├── .bash_profile
│   ├── .bashrc
│   └── .config/bash/
├── git/
│   └── .config/git/config
├── cpp/
│   ├── .clang-format
│   ├── .clang-tidy
│   └── .config/gdb/gdbinit
├── editorconfig/
│   └── .editorconfig
├── emacs/
│   └── .emacs.d/
│       ├── early-init.el
│       └── init.el
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

This uses the repo `Brewfile` with Homebrew on macOS or Linuxbrew on Linux. On
Linux systems without Linuxbrew, it falls back to apt and installs the packages
available from the distro repositories, using Linux package names such as
`fd-find` and `bat`.

Install all packages:

```sh
./install.sh
```

Or:

```sh
make install
```

Install selected packages:

```sh
./install.sh vim
./install.sh bash
./install.sh git
./install.sh cpp
./install.sh emacs
./install.sh tmux
./install.sh editorconfig
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
# Debian / Ubuntu
sudo apt install clang clangd clang-format clang-tidy cppcheck make

# macOS with Homebrew
brew install llvm cppcheck
```

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
~/.config/bash/init.bash
~/.config/bash/tools.bash
```

The shell setup distinguishes macOS and Linux when initializing Homebrew paths
and when commands use different distro names, such as `batcat` and `fdfind` on
some Linux systems.

## Git

The `git` package provides:

```text
~/.config/git/config
```

Git identity can stay in `~/.gitconfig`; the managed config adds pager, delta,
diff, merge, and short aliases.

## Emacs

The `emacs` package provides:

```text
~/.emacs.d/early-init.el
~/.emacs.d/init.el
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
and binds `C-c C-f` to format the current buffer with `clang-format`.

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
