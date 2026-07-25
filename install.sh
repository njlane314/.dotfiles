#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${DOTFILES_TARGET:-$HOME}"
manifest="$repo_dir/packages/stow"
dry_run=0
requested=()

usage() {
  cat <<'EOF'
Usage: ./install.sh [OPTIONS] [PACKAGE...]

Stow all managed dotfiles into $HOME, or install only the named packages.

Options:
  -h, --help  show this help and exit
  --dry-run   validate and preview without changing the target

DOTFILES_TARGET selects an alternate home-shaped target.
EOF
}

while (($#)); do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    --dry-run)
      dry_run=1
      ;;
    --*)
      printf 'Unknown option: %s\n' "$1" >&2
      exit 2
      ;;
    *)
      requested+=("$1")
      ;;
  esac
  shift
done

[[ -f "$manifest" ]] || {
  printf 'Missing package manifest: %s\n' "$manifest" >&2
  exit 1
}

available=()
while IFS= read -r package; do
  case "$package" in
    '' | \#*) continue ;;
  esac
  if [[ ! "$package" =~ ^[a-z0-9][a-z0-9_-]*$ ]] ||
    [[ ! -d "$repo_dir/$package" ]]
  then
    printf 'Invalid package in %s: %s\n' "$manifest" "$package" >&2
    exit 1
  fi
  available+=("$package")
done <"$manifest"

((${#available[@]})) || {
  printf 'No packages are listed in %s\n' "$manifest" >&2
  exit 1
}

package_is_available() {
  local candidate
  for candidate in "${available[@]}"; do
    [[ "$candidate" == "$1" ]] && return 0
  done
  return 1
}

if ((${#requested[@]})); then
  packages=("${requested[@]}")
else
  packages=("${available[@]}")
fi

for package in "${packages[@]}"; do
  if ! package_is_available "$package"; then
    printf 'Unknown dotfiles package: %s\n' "$package" >&2
    printf 'Available packages: %s\n' "${available[*]}" >&2
    exit 2
  fi
done

command -v stow >/dev/null 2>&1 || {
  printf 'GNU Stow is required. Install it before running this script.\n' >&2
  exit 1
}

has_package() {
  local candidate
  for candidate in "${packages[@]}"; do
    [[ "$candidate" == "$1" ]] && return 0
  done
  return 1
}

stow_preflight() {
  stow --dir="$repo_dir" --target="$1" --restow --no-folding \
    --simulate "${packages[@]}"
}

if ((dry_run)); then
  preview_target="$target_dir"
  temporary_target=
  if [[ -d "$preview_target" ]]; then
    preview_target="$(cd -- "$preview_target" && pwd -P)"
  else
    temporary_target="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-dry-run.XXXXXX")"
    preview_target="$temporary_target"
    printf 'Would create target: %s\n' "$target_dir"
  fi

  if ! stow_preflight "$preview_target"; then
    [[ -n "$temporary_target" ]] && rmdir "$temporary_target"
    printf 'Stow dry run failed; no files were changed.\n' >&2
    exit 1
  fi
  [[ -n "$temporary_target" ]] && rmdir "$temporary_target"
  printf 'Would install packages: %s\n' "${packages[*]}"
  exit 0
fi

mkdir -p -- "$target_dir"
target_dir="$(cd -- "$target_dir" && pwd -P)"
transaction_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")"
rollback_sources=()
rollback_targets=()
discard_on_success=()
rollback_count=0
discard_count=0
install_complete=0

finish_install() {
  local status=$?
  local index

  trap - EXIT
  if ((install_complete)); then
    for ((index = 0; index < discard_count; index++)); do
      [[ -e "${discard_on_success[$index]}" ||
        -L "${discard_on_success[$index]}" ]] &&
        unlink "${discard_on_success[$index]}"
    done
  else
    for ((index = rollback_count - 1; index >= 0; index--)); do
      if [[ -e "${rollback_sources[$index]}" ||
        -L "${rollback_sources[$index]}" ]]
      then
        [[ -e "${rollback_targets[$index]}" ||
          -L "${rollback_targets[$index]}" ]] &&
          unlink "${rollback_targets[$index]}"
        mkdir -p -- "$(dirname -- "${rollback_targets[$index]}")"
        mv -- "${rollback_sources[$index]}" "${rollback_targets[$index]}"
      fi
    done
  fi
  rmdir "$transaction_dir" 2>/dev/null || true
  exit "$status"
}
trap finish_install EXIT

stage_conflict() {
  local package="$1"
  local relative="$2"
  local source="$repo_dir/$package/$relative"
  local target="$target_dir/$relative"
  local backup
  local suffix=0

  has_package "$package" || return 0
  [[ -f "$target" && ! -L "$target" ]] || return 0
  [[ "$target" -ef "$source" ]] && return 0

  if cmp -s "$target" "$source"; then
    backup="$transaction_dir/$discard_count"
    discard_on_success[$discard_count]="$backup"
    discard_count=$((discard_count + 1))
  else
    backup="$target.before-dotfiles-$(date +%Y%m%d%H%M%S)"
    while [[ -e "$backup" || -L "$backup" ]]; do
      suffix=$((suffix + 1))
      backup="$target.before-dotfiles-$(date +%Y%m%d%H%M%S)-$suffix"
    done
    printf 'Backed up %s to %s\n' "$target" "$backup"
  fi

  rollback_sources[$rollback_count]="$backup"
  rollback_targets[$rollback_count]="$target"
  rollback_count=$((rollback_count + 1))
  mv -- "$target" "$backup"
}

preflight_output=
if ! preflight_output="$(stow_preflight "$target_dir" 2>&1)"; then
  stage_conflict bash .bash_profile
  stage_conflict bash .bashrc
  stage_conflict git .config/git/config

  if ! stow_preflight "$target_dir"; then
    printf '%s\n' "$preflight_output" >&2
    printf 'Stow preflight failed; no links were installed.\n' >&2
    exit 1
  fi
fi

if has_package vim; then
  vim_data_home="$target_dir/.local/share"
  vim_state_home="$target_dir/.local/state"
  vim_cache_home="$target_dir/.cache"
  if [[ "$target_dir" == "$(cd -- "$HOME" && pwd -P)" ]]; then
    [[ ${XDG_DATA_HOME:-} == /* ]] && vim_data_home="$XDG_DATA_HOME"
    [[ ${XDG_STATE_HOME:-} == /* ]] && vim_state_home="$XDG_STATE_HOME"
    [[ ${XDG_CACHE_HOME:-} == /* ]] && vim_cache_home="$XDG_CACHE_HOME"
  fi
  mkdir -p -- \
    "$vim_data_home/vim/autoload" \
    "$vim_data_home/vim/plugged" \
    "$vim_state_home/vim/undo" \
    "$vim_cache_home/vim/backup" \
    "$vim_cache_home/vim/swap"
fi

has_package cpp && mkdir -p -- "$target_dir/.cache/gdb"
has_package emacs && mkdir -p -- \
  "$target_dir/.emacs.d/elpa" \
  "$target_dir/.emacs.d/var/auto-save" \
  "$target_dir/.emacs.d/var/backup"

stow --dir="$repo_dir" --target="$target_dir" --restow --no-folding \
  "${packages[@]}"
install_complete=1

printf 'Installed packages: %s\n' "${packages[*]}"
