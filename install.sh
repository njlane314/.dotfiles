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
  packages=(bash git vim cpp emacs tmux editorconfig)
else
  packages=("$@")
fi

has_package() {
  local package
  for package in "${packages[@]}"; do
    [[ "$package" == "$1" ]] && return 0
  done
  return 1
}

backup_conflict() {
  local rel="$1"
  local source="$repo_dir/$2"
  local target="$target_dir/$rel"
  local backup

  [[ -e "$target" || -L "$target" ]] || return 0
  [[ -L "$target" ]] && return 0

  if [[ -f "$target" && -f "$source" ]] && cmp -s "$target" "$source"; then
    rm "$target"
    return 0
  fi

  backup="$target.before-dotfiles-$(date +%Y%m%d%H%M%S)"
  mv "$target" "$backup"
  printf 'Backed up %s to %s\n' "$target" "$backup"
}

if has_package bash; then
  backup_conflict .bashrc bash/.bashrc
  backup_conflict .bash_profile bash/.bash_profile
fi

if has_package git; then
  backup_conflict .config/git/config git/.config/git/config
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
