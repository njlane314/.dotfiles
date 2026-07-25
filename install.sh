#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${DOTFILES_TARGET:-$HOME}"
package_file="$repo_dir/packages/stow"
dry_run=0
apply_visuals=0
requested_packages=()

usage() {
  cat <<'EOF'
Usage: ./install.sh [OPTIONS] [PACKAGE...]

Install all managed dotfile packages, or only the packages named on the
command line.

Options:
  -h, --help       show this help and exit
  --dry-run        preview Stow operations without changing the target
  --apply-visuals  apply Terminal and wallpaper settings after installation

DOTFILES_TARGET selects an alternate home-shaped target. Visual settings are
applied only to the real home directory on macOS.
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
    --apply-visuals)
      apply_visuals=1
      ;;
    *)
      requested_packages+=("$1")
      ;;
  esac
  shift
done

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

if ((${#requested_packages[@]} == 0)); then
  packages=("${available_packages[@]}")
else
  packages=("${requested_packages[@]}")
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

home_dir="$(cd -- "$HOME" && pwd -P)"

has_package() {
  local package
  for package in "${packages[@]}"; do
    [[ "$package" == "$1" ]] && return 0
  done
  return 1
}

if ((dry_run)); then
  simulation_target="$target_dir"
  temporary_target=

  if [[ -d "$simulation_target" ]]; then
    simulation_target="$(cd -- "$simulation_target" && pwd -P)"
    target_dir="$simulation_target"
  else
    temporary_target="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")"
    simulation_target="$temporary_target"
    printf 'Would create target: %s\n' "$target_dir"
  fi

  cd "$repo_dir"
  if ! stow_output="$(
    stow --target="$simulation_target" --restow --no-folding \
      --simulate --verbose=1 "${packages[@]}" 2>&1
  )"; then
    [[ -n "$temporary_target" ]] && rmdir "$temporary_target"
    printf '%s\n' "$stow_output" >&2
    printf 'Stow dry run failed; no links were installed.\n' >&2
    exit 1
  fi
  [[ -n "$stow_output" ]] && printf '%s\n' "$stow_output"
  [[ -n "$temporary_target" ]] && rmdir "$temporary_target"

  printf 'Would install packages: %s\n' "${packages[*]}"
  if ((apply_visuals)) && [[ "$(uname -s)" == Darwin && "$target_dir" == "$home_dir" ]]; then
    has_package terminal && printf 'Would apply Terminal settings.\n'
    has_package wallpaper && printf 'Would apply desktop wallpaper.\n'
  fi
  exit 0
fi

mkdir -p -- "$target_dir"
target_dir="$(cd -- "$target_dir" && pwd -P)"
vim_data_home="$target_dir/.local/share"
vim_state_home="$target_dir/.local/state"
vim_cache_home="$target_dir/.cache"

if [[ "$target_dir" == "$home_dir" ]]; then
  [[ ${XDG_DATA_HOME:-} == /* ]] && vim_data_home="$XDG_DATA_HOME"
  [[ ${XDG_STATE_HOME:-} == /* ]] && vim_state_home="$XDG_STATE_HOME"
  [[ ${XDG_CACHE_HOME:-} == /* ]] && vim_cache_home="$XDG_CACHE_HOME"
fi

rollback_sources=()
rollback_targets=()
temporary_backups=()
rollback_count=0
temporary_count=0
transaction_dir=
install_complete=0
bash_local_was_folded=0

finish_install() {
  local status=$?
  local index
  local source
  local target

  trap - EXIT

  if ((install_complete)); then
    for ((index = 0; index < temporary_count; index++)); do
      source="${temporary_backups[$index]}"
      if [[ -d "$source" && ! -L "$source" ]]; then
        rmdir "$source"
      elif [[ -e "$source" || -L "$source" ]]; then
        unlink "$source"
      fi
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

register_rollback() {
  rollback_sources[$rollback_count]="$1"
  rollback_targets[$rollback_count]="$2"
  rollback_count=$((rollback_count + 1))
}

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
    register_rollback "$backup" "$target"
    return 0
  fi

  backup_base="$target.before-dotfiles-$(date +%Y%m%d%H%M%S)"
  backup="$backup_base"
  while [[ -e "$backup" || -L "$backup" ]]; do
    suffix=$((suffix + 1))
    backup="$backup_base-$suffix"
  done

  mv -- "$target" "$backup"
  register_rollback "$backup" "$target"
  printf 'Backed up %s to %s\n' "$target" "$backup"
}

stage_path_for_removal() {
  local path="$1"
  local staging

  if [[ -z "$transaction_dir" ]]; then
    transaction_dir="$(mktemp -d "$target_dir/.dotfiles-install.XXXXXX")"
  fi
  staging="$transaction_dir/$temporary_count"
  mv -- "$path" "$staging"
  temporary_backups[$temporary_count]="$staging"
  temporary_count=$((temporary_count + 1))
  register_rollback "$staging" "$path"
}

vim_runtime_destination() {
  case "$1" in
    autoload | plugged) printf '%s/vim/%s\n' "$vim_data_home" "$1" ;;
    undo) printf '%s/vim/undo\n' "$vim_state_home" ;;
    backup | swap) printf '%s/vim/%s\n' "$vim_cache_home" "$1" ;;
  esac
}

legacy_vim_runtime_source() {
  local name="$1"
  local checkout="$repo_dir/vim/.vim/$name"
  local installed="$target_dir/.vim/$name"
  local checkout_state
  local installed_state

  if [[ "$target_dir" != "$home_dir" ]]; then
    if [[ -d "$installed" &&
      ( ! -d "$checkout" || ! "$installed" -ef "$checkout" ) ]]; then
      printf '%s\n' "$installed"
    fi
    return 0
  fi

  if [[ -d "$checkout" && -d "$installed" && ! "$checkout" -ef "$installed" ]]; then
    checkout_state="$(find "$checkout" -mindepth 1 -print -quit)"
    installed_state="$(find "$installed" -mindepth 1 -print -quit)"
    if [[ -n "$checkout_state" && -n "$installed_state" ]]; then
      printf 'Cannot merge mutable Vim state from both %s and %s\n' \
        "$checkout" "$installed" >&2
      return 1
    fi
    [[ -n "$checkout_state" ]] && printf '%s\n' "$checkout" ||
      printf '%s\n' "$installed"
  elif [[ -d "$checkout" ]]; then
    printf '%s\n' "$checkout"
  elif [[ -d "$installed" ]]; then
    printf '%s\n' "$installed"
  fi

  return 0
}

validate_vim_runtime_dirs() {
  local checkout
  local destination
  local legacy_source
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
    checkout="$repo_dir/vim/.vim/$name"
    target="$target_dir/.vim/$name"
    if [[ "$target_dir" != "$home_dir" && -d "$checkout" &&
      -d "$target" && "$target" -ef "$checkout" ]]; then
      printf 'Cannot migrate checkout Vim state into an alternate target: %s\n' \
        "$target" >&2
      return 1
    fi
    if [[ -L "$checkout" || -e "$checkout" && ! -d "$checkout" ]]; then
      printf 'Checkout Vim runtime path must be a real directory: %s\n' \
        "$checkout" >&2
      return 1
    fi
    if [[ -L "$target" && ! -e "$target" ]]; then
      printf 'Broken Vim runtime link must be repaired before install: %s\n' "$target" >&2
      return 1
    fi
    if [[ -e "$target" && ! -d "$target" ]]; then
      printf 'Vim runtime path is not a directory: %s\n' "$target" >&2
      return 1
    fi
    if [[ -L "$target" ]]; then
      if [[ ! -d "$checkout" || ! "$target" -ef "$checkout" ]]; then
        printf 'Legacy Vim runtime symlink has an unknown target: %s\n' \
          "$target" >&2
        return 1
      fi
    fi

    legacy_source="$(legacy_vim_runtime_source "$name")" || return 1
    destination="$(vim_runtime_destination "$name")"
    if [[ -L "$destination" && ! -e "$destination" ]]; then
      printf 'Broken Vim runtime destination link: %s\n' "$destination" >&2
      return 1
    fi
    if [[ -e "$destination" && ! -d "$destination" ]]; then
      printf 'Vim runtime destination is not a directory: %s\n' \
        "$destination" >&2
      return 1
    fi
    if [[ -n "$legacy_source" && -L "$destination" ]]; then
      printf 'Cannot migrate legacy Vim state into a symlink: %s\n' \
        "$destination" >&2
      return 1
    fi
    if [[ -n "$legacy_source" && -d "$destination" &&
      -n "$(find "$destination" -mindepth 1 -print -quit)" ]]; then
      printf 'Cannot merge legacy Vim state into non-empty directory: %s\n' \
        "$destination" >&2
      return 1
    fi
  done
}

migrate_vim_runtime_dir() {
  local name="$1"
  local checkout="$repo_dir/vim/.vim/$name"
  local installed="$target_dir/.vim/$name"
  local source
  local destination

  source="$(legacy_vim_runtime_source "$name")"
  destination="$(vim_runtime_destination "$name")"
  [[ -n "$source" ]] || return 0

  mkdir -p -- "$(dirname -- "$destination")"
  [[ -d "$destination" ]] && stage_path_for_removal "$destination"

  mv -- "$source" "$destination"
  register_rollback "$destination" "$source"

  if [[ "$source" == "$checkout" ]] &&
    [[ -L "$installed" || -d "$installed" ]]; then
    stage_path_for_removal "$installed"
  fi

  printf 'Migrated mutable Vim state to %s\n' "$destination"
}

detect_legacy_bash_local() {
  local source="$repo_dir/bash/.config/bash/local.bash"
  local target="$target_dir/.config/bash/local.bash"

  if [[ -f "$source" && -e "$target" && "$target" -ef "$source" ]]; then
    if [[ "$target_dir" != "$home_dir" ]]; then
      printf 'Cannot migrate checkout Bash config into an alternate target: %s\n' \
        "$target" >&2
      return 1
    fi
    bash_local_was_folded=1
  fi
}

migrate_bash_local() {
  local source="$repo_dir/bash/.config/bash/local.bash"
  local target="$target_dir/.config/bash/local.bash"
  local staging
  local legacy_link
  local suffix=0

  [[ "$target_dir" == "$home_dir" ]] || return 0
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

stow_preflight() {
  local output

  if ! output="$(
    stow --target="$target_dir" --restow --no-folding --simulate "${packages[@]}" 2>&1
  )"; then
    printf '%s\n' "$output" >&2
    printf 'Stow preflight failed; no links were installed.\n' >&2
    return 1
  fi
}

if has_package bash; then
  detect_legacy_bash_local
  backup_conflict .bashrc bash/.bashrc
  backup_conflict .bash_profile bash/.bash_profile
fi

if has_package vim; then
  validate_vim_runtime_dirs
fi

if has_package git; then
  backup_conflict .config/git/config git/.config/git/config
fi

cd "$repo_dir"
stow_preflight

if has_package vim; then
  for runtime_dir in autoload plugged undo backup swap; do
    migrate_vim_runtime_dir "$runtime_dir"
    mkdir -p -- "$(vim_runtime_destination "$runtime_dir")"
  done
  stow_preflight
fi

stow --target="$target_dir" --restow --no-folding "${packages[@]}"
install_complete=1

if has_package bash; then
  migrate_bash_local
fi

if has_package cpp; then
  mkdir -p "$target_dir/.cache/gdb"
fi

if has_package emacs; then
  mkdir -p "$target_dir/.emacs.d"/{elpa,var/auto-save,var/backup}
fi

if ((apply_visuals)) && has_package terminal &&
  [[ "$(uname -s)" == Darwin && "$target_dir" == "$home_dir" ]]
then
  "$target_dir/.config/terminal/apply"
fi

if ((apply_visuals)) && has_package wallpaper &&
  [[ "$(uname -s)" == Darwin && "$target_dir" == "$home_dir" ]]
then
  "$target_dir/.config/wallpaper/apply"
fi

printf 'Installed packages: %s\n' "${packages[*]}"

if ((!apply_visuals)) && [[ "$(uname -s)" == Darwin && "$target_dir" == "$home_dir" ]] &&
  { has_package terminal || has_package wallpaper; }
then
  printf 'Visual settings were not applied; use --apply-visuals when wanted.\n'
fi
