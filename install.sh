#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${DOTFILES_TARGET:-$HOME}"
package_file="$repo_dir/packages/stow"

if ! command -v stow >/dev/null 2>&1; then
  cat >&2 <<'EOF'
GNU Stow is required to install these dotfiles.

Install it with one of:
  brew install stow
  sudo apt install stow
EOF
  exit 1
fi

if [[ ! -f "$package_file" ]]; then
  printf 'Missing Stow package manifest: %s\n' "$package_file" >&2
  exit 1
fi

available_packages=()
while IFS= read -r package; do
  [[ -n "$package" ]] && available_packages+=("$package")
done <"$package_file"

if (($# == 0)); then
  packages=("${available_packages[@]}")
else
  packages=("$@")
fi

package_is_available() {
  local package
  for package in "${available_packages[@]}"; do
    [[ "$package" == "$1" ]] && return 0
  done
  return 1
}

for package in "${packages[@]}"; do
  if ! package_is_available "$package"; then
    printf 'Unknown dotfiles package: %s\n' "$package" >&2
    printf 'Available packages: %s\n' "${available_packages[*]}" >&2
    exit 2
  fi
done

mkdir -p -- "$target_dir"
target_dir="$(cd -- "$target_dir" && pwd -P)"
home_dir="$(cd -- "$HOME" && pwd -P)"

has_package() {
  local package
  for package in "${packages[@]}"; do
    [[ "$package" == "$1" ]] && return 0
  done
  return 1
}

rollback_sources=()
rollback_targets=()
temporary_backups=()
rollback_count=0
temporary_count=0
transaction_dir=
install_complete=0
bash_local_was_folded=0
legacy_vim_runtime_dirs=()
legacy_vim_runtime_count=0

finish_install() {
  local status=$?
  local index
  local source
  local target

  trap - EXIT

  if ((install_complete)); then
    for ((index = 0; index < temporary_count; index++)); do
      source="${temporary_backups[$index]}"
      [[ -e "$source" || -L "$source" ]] && unlink "$source"
    done
  else
    for ((index = rollback_count - 1; index >= 0; index--)); do
      source="${rollback_sources[$index]}"
      target="${rollback_targets[$index]}"

      [[ -L "$target" ]] && unlink "$target"
      if [[ -e "$target" ]]; then
        printf 'Could not restore %s; unexpected path remains in place\n' "$target" >&2
        status=1
        continue
      fi

      if [[ -e "$source" || -L "$source" ]]; then
        mkdir -p -- "$(dirname -- "$target")"
        mv -- "$source" "$target"
        printf 'Restored %s after failed install\n' "$target" >&2
      fi
    done
  fi

  if [[ -n "$transaction_dir" && -d "$transaction_dir" ]]; then
    rmdir "$transaction_dir" 2>/dev/null || true
  fi

  exit "$status"
}
trap finish_install EXIT

backup_conflict() {
  local rel="$1"
  local source="$repo_dir/$2"
  local target="$target_dir/$rel"
  local backup
  local backup_base
  local suffix=0

  [[ -e "$target" || -L "$target" ]] || return 0
  if [[ -e "$source" && "$target" -ef "$source" ]]; then
    return 0
  fi
  [[ -L "$target" ]] && return 0

  if [[ -f "$target" && -f "$source" ]] && cmp -s "$target" "$source"; then
    if [[ -z "$transaction_dir" ]]; then
      transaction_dir="$(mktemp -d "$target_dir/.dotfiles-install.XXXXXX")"
    fi
    backup="$transaction_dir/$temporary_count"
    mv -- "$target" "$backup"
    temporary_backups[$temporary_count]="$backup"
    temporary_count=$((temporary_count + 1))
    rollback_sources[$rollback_count]="$backup"
    rollback_targets[$rollback_count]="$target"
    rollback_count=$((rollback_count + 1))
    return 0
  fi

  backup_base="$target.before-dotfiles-$(date +%Y%m%d%H%M%S)"
  backup="$backup_base"
  while [[ -e "$backup" || -L "$backup" ]]; do
    suffix=$((suffix + 1))
    backup="$backup_base-$suffix"
  done

  mv -- "$target" "$backup"
  rollback_sources[$rollback_count]="$backup"
  rollback_targets[$rollback_count]="$target"
  rollback_count=$((rollback_count + 1))
  printf 'Backed up %s to %s\n' "$target" "$backup"
}

detect_legacy_vim_runtime_dirs() {
  local name
  local source
  local target

  for name in autoload plugged undo backup swap; do
    source="$repo_dir/vim/.vim/$name"
    target="$target_dir/.vim/$name"
    if [[ -d "$source" && -e "$target" && "$target" -ef "$source" ]]; then
      legacy_vim_runtime_dirs[$legacy_vim_runtime_count]="$name"
      legacy_vim_runtime_count=$((legacy_vim_runtime_count + 1))
    fi
  done
}

vim_runtime_was_folded() {
  local index

  for ((index = 0; index < legacy_vim_runtime_count; index++)); do
    [[ "${legacy_vim_runtime_dirs[$index]}" == "$1" ]] && return 0
  done
  return 1
}

validate_vim_runtime_dirs() {
  local name
  local target

  target="$target_dir/.vim"
  if [[ -L "$target" && ! -e "$target" ]]; then
    printf 'Broken Vim directory link must be repaired before install: %s\n' "$target" >&2
    return 1
  fi
  if [[ -e "$target" && ! -d "$target" ]]; then
    printf 'Vim runtime path is not a directory: %s\n' "$target" >&2
    return 1
  fi

  for name in autoload plugged undo backup swap; do
    target="$target_dir/.vim/$name"
    if [[ -L "$target" && ! -e "$target" ]]; then
      printf 'Broken Vim runtime link must be repaired before install: %s\n' "$target" >&2
      return 1
    fi
    if [[ -e "$target" && ! -d "$target" ]]; then
      printf 'Vim runtime path is not a directory: %s\n' "$target" >&2
      return 1
    fi
  done
}

migrate_vim_runtime_dir() {
  local name="$1"
  local source="$repo_dir/vim/.vim/$name"
  local target="$target_dir/.vim/$name"
  local staging
  local legacy_link
  local suffix=0
  local should_migrate=0

  if [[ -d "$source" ]]; then
    if [[ -L "$target" && -d "$target" && "$target" -ef "$source" ]]; then
      should_migrate=1
    elif vim_runtime_was_folded "$name" &&
      [[ ! -e "$target" && ! -L "$target" ]]; then
      should_migrate=1
    fi
  fi

  if ((should_migrate)); then
    staging="$(mktemp -d "$target.local.XXXXXX")"
    if ! cp -R "$source/." "$staging/"; then
      find "$staging" -depth -delete
      return 1
    fi

    if [[ -L "$target" ]]; then
      legacy_link="$target.legacy"
      while [[ -e "$legacy_link" || -L "$legacy_link" ]]; do
        suffix=$((suffix + 1))
        legacy_link="$target.legacy-$suffix"
      done

      mv -- "$target" "$legacy_link"
      if mv -- "$staging" "$target"; then
        unlink "$legacy_link"
      else
        mv -- "$legacy_link" "$target"
        find "$staging" -depth -delete
        return 1
      fi
    elif ! mv -- "$staging" "$target"; then
      find "$staging" -depth -delete
      return 1
    fi

    printf 'Migrated mutable Vim state out of the dotfiles checkout: %s\n' "$target"
  fi

  mkdir -p -- "$target"
}

detect_legacy_bash_local() {
  local source="$repo_dir/bash/.config/bash/local.bash"
  local target="$target_dir/.config/bash/local.bash"

  if [[ -f "$source" && -e "$target" && "$target" -ef "$source" ]]; then
    bash_local_was_folded=1
  fi
}

migrate_bash_local() {
  local source="$repo_dir/bash/.config/bash/local.bash"
  local target="$target_dir/.config/bash/local.bash"
  local staging
  local legacy_link
  local suffix=0

  [[ -f "$source" ]] || return 0

  if [[ -L "$target" && "$target" -ef "$source" ]]; then
    staging="$(mktemp "$target.local.XXXXXX")"
    if ! cp -p "$source" "$staging"; then
      unlink "$staging"
      return 1
    fi
    legacy_link="$target.legacy"
    while [[ -e "$legacy_link" || -L "$legacy_link" ]]; do
      suffix=$((suffix + 1))
      legacy_link="$target.legacy-$suffix"
    done
    mv -- "$target" "$legacy_link"
    if mv -- "$staging" "$target"; then
      unlink "$legacy_link"
    else
      mv -- "$legacy_link" "$target"
      unlink "$staging"
      return 1
    fi
  elif ((bash_local_was_folded)) && [[ ! -e "$target" && ! -L "$target" ]]; then
    cp -p "$source" "$target"
  else
    return 0
  fi

  printf 'Migrated machine-local Bash config out of the dotfiles checkout: %s\n' "$target"
}

if has_package bash; then
  detect_legacy_bash_local
  backup_conflict .bashrc bash/.bashrc
  backup_conflict .bash_profile bash/.bash_profile
fi

if has_package vim; then
  validate_vim_runtime_dirs
  detect_legacy_vim_runtime_dirs
fi

if has_package git; then
  backup_conflict .config/git/config git/.config/git/config
fi

cd "$repo_dir"
if ! preflight_output="$(
  stow --target="$target_dir" --restow --no-folding --simulate "${packages[@]}" 2>&1
)"; then
  printf '%s\n' "$preflight_output" >&2
  printf 'Stow preflight failed; target changes will be rolled back.\n' >&2
  exit 1
fi
stow --target="$target_dir" --restow --no-folding "${packages[@]}"
install_complete=1

if has_package bash; then
  migrate_bash_local
fi

if has_package vim; then
  for runtime_dir in autoload plugged undo backup swap; do
    migrate_vim_runtime_dir "$runtime_dir"
  done
  mkdir -p "$target_dir/.vim/after/ftplugin"
fi

if [[ " ${packages[*]} " == *" cpp "* ]]; then
  mkdir -p "$target_dir/.cache/gdb"
fi

if [[ " ${packages[*]} " == *" emacs "* ]]; then
  mkdir -p "$target_dir/.emacs.d"/{elpa,var/auto-save,var/backup,var/lock}
fi

if has_package terminal && [[ "$(uname -s)" == Darwin && "$target_dir" == "$home_dir" ]]; then
  "$target_dir/.config/terminal/apply"
fi

if has_package wallpaper && [[ "$(uname -s)" == Darwin && "$target_dir" == "$home_dir" ]]; then
  "$target_dir/.config/wallpaper/apply"
fi

printf 'Installed packages: %s\n' "${packages[*]}"
