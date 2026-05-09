# ~/.bashrc

if [[ -r "$HOME/.config/bash/tools.bash" ]]; then
  . "$HOME/.config/bash/tools.bash"
fi

if ! declare -F _dotfiles_path_prepend >/dev/null; then
  _dotfiles_path_prepend() {
    [[ -n "${1:-}" && -d "$1" ]] || return 0
    case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac
  }
  _dotfiles_path_append() {
    [[ -n "${1:-}" && -d "$1" ]] || return 0
    case ":$PATH:" in *":$1:"*) ;; *) PATH="$PATH:$1" ;; esac
  }
fi

if declare -F _dotfiles_brew_init >/dev/null; then
  _dotfiles_brew_init
fi

export EDITOR="${EDITOR:-vim}"

export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT/bin" ]]; then
  _dotfiles_path_prepend "$PYENV_ROOT/bin"
fi
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

_dotfiles_path_append "$HOME/.local/bin"
_dotfiles_path_prepend "$HOME/.foundry/bin"

if [[ -r "$HOME/.cargo/env" ]]; then
  . "$HOME/.cargo/env"
fi

for file in \
  "$HOME/.config/bash/aliases.bash" \
  "$HOME/.config/bash/functions.bash" \
  "$HOME/.config/bash/init.bash"
do
  if [[ -r "$file" ]]; then
    . "$file"
  fi
done
