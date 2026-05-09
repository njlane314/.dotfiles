# Dotfiles

Stow-managed dotfiles. Each top-level directory is a package that maps into
`$HOME`.

```text
.
├── Makefile
├── README.md
├── install.sh
├── cpp/
│   ├── .clang-format
│   ├── .clang-tidy
│   └── .config/gdb/gdbinit
├── emacs/
│   └── .emacs.d/
│       ├── early-init.el
│       └── init.el
└── vim/
    ├── .vimrc
    └── .vim/
        └── after/ftplugin/
```

## Install

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
./install.sh cpp
./install.sh emacs
```

The installer uses GNU Stow, so install it first if needed:

```sh
# macOS
brew install stow

# Debian / Ubuntu
sudo apt install stow
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
