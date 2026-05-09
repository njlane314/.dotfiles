#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${DOTFILES_TARGET:-$HOME}"

if ! command -v stow >/dev/null 2>&1; then
  cat >&2 <<'EOF'
GNU Stow is required to install these dotfiles.

Install it with one of:
  brew install stow
  sudo apt install stow
EOF
  exit 1
fi

if (($# == 0)); then
  packages=(vim cpp emacs tmux editorconfig aerospace)
else
  packages=("$@")
fi

cd "$repo_dir"
stow --target="$target_dir" --restow --no-folding "${packages[@]}"

if [[ " ${packages[*]} " == *" vim "* ]]; then
  mkdir -p "$target_dir/.vim"/{autoload,plugged,undo,backup,swap,after/ftplugin}
fi

if [[ " ${packages[*]} " == *" cpp "* ]]; then
  mkdir -p "$target_dir/.cache/gdb"
fi

if [[ " ${packages[*]} " == *" emacs "* ]]; then
  mkdir -p "$target_dir/.emacs.d"/{elpa,var/auto-save,var/backup,var/lock}
fi

printf 'Installed packages: %s\n' "${packages[*]}"
