#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
target_dir="${DOTFILES_TARGET:-$HOME}"
dry_run=0
validate_only=0

usage() {
  cat <<'EOF'
Usage: migrations/2026-07-xdg-state.sh [--dry-run]

One-time migration for deployments made before July 2026. It unfolds the old
Bash/Vim links and moves mutable Vim state into XDG data, state, and cache
directories. Run ./install.sh afterwards.
EOF
}

case "${1:-}" in
  '') ;;
  --dry-run) dry_run=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
(($# <= 1)) || {
  usage >&2
  exit 2
}

[[ -d "$target_dir" ]] || {
  printf 'Migration target does not exist: %s\n' "$target_dir" >&2
  exit 1
}
target_dir="$(cd -- "$target_dir" && pwd -P)"

data_home="$target_dir/.local/share"
state_home="$target_dir/.local/state"
cache_home="$target_dir/.cache"
if [[ "$target_dir" == "$(cd -- "$HOME" && pwd -P)" ]]; then
  [[ ${XDG_DATA_HOME:-} == /* ]] && data_home="$XDG_DATA_HOME"
  [[ ${XDG_STATE_HOME:-} == /* ]] && state_home="$XDG_STATE_HOME"
  [[ ${XDG_CACHE_HOME:-} == /* ]] && cache_home="$XDG_CACHE_HOME"
fi

validate_move_parent() {
  local path="$1"
  local role="$2"
  local ancestor
  local parent

  parent="$(dirname -- "$path")"
  ancestor="$parent"
  while [[ ! -e "$ancestor" && ! -L "$ancestor" ]]; do
    [[ "$(dirname -- "$ancestor")" != "$ancestor" ]] || break
    ancestor="$(dirname -- "$ancestor")"
  done

  [[ -d "$ancestor" ]] || {
    printf 'Migration %s parent is not a directory: %s\n' \
      "$role" "$ancestor" >&2
    return 1
  }
  [[ -w "$ancestor" && -x "$ancestor" ]] || {
    printf 'Migration %s parent is not writable: %s\n' \
      "$role" "$ancestor" >&2
    return 1
  }
}

move_directory() {
  local source="$1"
  local destination="$2"
  local source_entry
  local destination_entry

  [[ -e "$source" || -L "$source" ]] || return 0
  [[ -d "$source" && ! -L "$source" ]] || {
    printf 'Expected a real directory: %s\n' "$source" >&2
    return 1
  }
  [[ -e "$destination" || -L "$destination" ]] || destination_entry=
  if [[ -e "$destination" || -L "$destination" ]]; then
    [[ -d "$destination" && ! -L "$destination" ]] || {
      printf 'Migration destination is not a real directory: %s\n' \
        "$destination" >&2
      return 1
    }
    [[ "$source" -ef "$destination" ]] && return 0
    source_entry="$(find "$source" -mindepth 1 -print -quit)"
    destination_entry="$(find "$destination" -mindepth 1 -print -quit)"
    if [[ -n "$source_entry" && -n "$destination_entry" ]]; then
      printf 'Refusing to merge two non-empty directories:\n  %s\n  %s\n' \
        "$source" "$destination" >&2
      return 1
    fi
    [[ -z "$source_entry" ]] && return 0
  fi

  validate_move_parent "$source" source
  validate_move_parent "$destination" destination
  ((validate_only)) && return 0
  printf 'Move %s -> %s\n' "$source" "$destination"
  ((dry_run)) && return 0
  mkdir -p -- "$(dirname -- "$destination")"
  [[ -d "$destination" ]] && rmdir "$destination"
  mv -- "$source" "$destination"
}

vim_root="$target_dir/.vim"
checkout_vim="$repo_dir/vim/.vim"
folded_vim=0
if [[ -L "$vim_root" ]]; then
  [[ -d "$vim_root" ]] || {
    printf 'Broken legacy Vim link: %s\n' "$vim_root" >&2
    exit 1
  }
  if [[ "$(cd -- "$vim_root" && pwd -P)" != \
    "$(cd -- "$checkout_vim" && pwd -P)" ]]
  then
    printf 'Legacy Vim link has an unknown target: %s\n' "$vim_root" >&2
    exit 1
  fi
  folded_vim=1
  vim_root="$checkout_vim"
fi

migrate_vim_directories() {
  local destination
  local name

  for name in autoload plugged undo backup swap; do
    case "$name" in
      autoload | plugged) destination="$data_home/vim/$name" ;;
      undo) destination="$state_home/vim/undo" ;;
      backup | swap) destination="$cache_home/vim/$name" ;;
    esac
    move_directory "$vim_root/$name" "$destination"
  done
}

validate_only=1
migrate_vim_directories
validate_only=0
migrate_vim_directories

if ((folded_vim)); then
  printf 'Unfold %s\n' "$target_dir/.vim"
  ((dry_run)) || unlink "$target_dir/.vim"
fi

checkout_local="$repo_dir/bash/.config/bash/local.bash"
target_local="$target_dir/.config/bash/local.bash"
folded_config=0
if [[ -L "$target_dir/.config" && -d "$target_dir/.config" ]] &&
  [[ "$(cd -- "$target_dir/.config" && pwd -P)" == \
    "$(cd -- "$repo_dir/bash/.config" && pwd -P)" ]]
then
  folded_config=1
fi

if ((folded_config)); then
  if [[ -f "$checkout_local" ]]; then
    printf 'Preserve %s and unfold %s\n' "$target_local" "$target_dir/.config"
  else
    printf 'Unfold %s\n' "$target_dir/.config"
  fi
  if ((!dry_run)); then
    temporary_local=
    if [[ -f "$checkout_local" ]]; then
      temporary_local="$(mktemp "${TMPDIR:-/tmp}/dotfiles-local-bash.XXXXXX")"
      cp -p -- "$checkout_local" "$temporary_local"
    fi
    unlink "$target_dir/.config"
    if [[ -n "$temporary_local" ]]; then
      mkdir -p -- "$(dirname -- "$target_local")"
      mv -- "$temporary_local" "$target_local"
    fi
  fi
elif [[ -f "$checkout_local" && -L "$target_local" ]] &&
  [[ "$target_local" -ef "$checkout_local" ]]
then
  printf 'Replace legacy link with a local file: %s\n' "$target_local"
  if ((!dry_run)); then
    temporary_local="$(mktemp "${TMPDIR:-/tmp}/dotfiles-local-bash.XXXXXX")"
    cp -p -- "$checkout_local" "$temporary_local"
    unlink "$target_local"
    mv -- "$temporary_local" "$target_local"
  fi
fi

printf '%s\n' 'Migration complete. Run ./install.sh to install the current layout.'
