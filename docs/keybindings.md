# Keybindings

`C-x` means Control-x, `M-x` means Meta-x, and Vim's `<leader>` is Space.

## tmux

The tmux prefix is `C-b`.

| Keys | Action |
| --- | --- |
| `C-b d` | Detach |
| `C-b c` | Create a window |
| `C-b n` / `C-b p` | Select the next or previous window |
| `C-b 1` ... `C-b 9` | Select a numbered window |
| `C-b ,` | Rename the current window |
| `C-b &` | Kill the current window |
| `C-b -` | Split vertically, creating a pane below |
| `C-b \|` | Split horizontally, creating a pane to the right |
| `C-b h/j/k/l` | Select the pane to the left/down/up/right |
| `C-b H/J/K/L` | Resize the pane left/down/up/right in five-cell steps |
| `C-b x` | Kill the current pane |
| `C-b z` | Toggle pane zoom |
| `C-b [` | Enter copy mode |
| `q` | Leave copy mode |
| `C-b r` | Reload `~/.tmux.conf` |
| `C-b ?` | Show all tmux keybindings |
| `C-b :` | Open the tmux command prompt |

## Vim

### General

| Keys | Action |
| --- | --- |
| `<leader>w` | Write the current file |
| `<leader>q` | Quit the current window |
| `<leader>e` | Open the built-in file explorer |
| `<leader>p` | Open CtrlP when the plugin is installed |
| `<leader><space>` | Clear search highlighting |
| `<leader>n` / `<leader>N` | Select the next or previous quickfix entry |
| `<leader>c` | Open the quickfix list |
| `C-h/j/k/l` | Move to the split on the left/down/up/right |

### C and C++

| Keys | Action |
| --- | --- |
| `<leader>m` | Run `make` and populate the quickfix list |
| `<leader>b` | Build the current C or C++ file |
| `<leader>x` | Run the current file's compiled output |
| `<leader>f` | Format or fix with ALE |
| `<leader>d` | Show diagnostic detail with ALE |
| `<leader>rn` | Rename a symbol with ALE |
| `<leader>a` | Show ALE code actions |
| `<leader>gd` | Go to a definition with ALE |
| `<leader>gr` | Find references with ALE |
| `<leader>gh` | Show hover detail with ALE |
| `[d` / `]d` | Select the previous or next ALE diagnostic |

ALE marks diagnostics without persistent inline text or automatic hover. Use
the explicit detail and hover mappings when the full message is useful. The
build mappings are buffer-local and quote filenames before invoking the shell.

## Emacs

### Core and configured bindings

| Keys | Action |
| --- | --- |
| `C-x C-f` | Open a file |
| `C-x C-s` | Save the current buffer |
| `C-x C-c` | Quit Emacs |
| `C-g` | Cancel the current command or prompt |
| `M-x` | Run a command by name |
| `C-c s` | Save the current buffer |
| `C-c k` | Kill the current buffer |
| `C-c e` | Open `init.el` |
| `C-c p` | Open the project command map |
| `C-c m` / `C-c M` | Compile or recompile |
| `C-c !` | Show Flymake diagnostics for the buffer |
| `M-n` / `M-p` | Select the next or previous Flymake diagnostic |
| `C-c C-f` | Format the current C/C++ buffer with `clang-format` |

### Optional-package bindings

| Keys | Package | Action |
| --- | --- | --- |
| `C-s` | Consult | Search the current buffer |
| `C-x b` | Consult | Switch buffers |
| `M-y` | Consult | Select from the kill ring |
| `C-c f` | Consult | Find a file |
| `C-c r` | Consult and Ripgrep | Search project text |
| `C-c g` | Magit | Open Git status |
| `C-c R` | Eglot | Rename a symbol |
| `C-c a` | Eglot | Show code actions |

When an optional package is not installed, its package-specific bindings are
not added; standard Emacs bindings remain available.
