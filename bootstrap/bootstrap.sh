#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
packages_dir="$repo_dir/packages"
os="$(uname -s)"

read_package_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    printf 'Missing package manifest: %s\n' "$file" >&2
    return 1
  fi

  sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$file"
}

install_apt_packages() {
  local package
  local package_list
  local packages=()
  local installable=()
  local missing=()

  package_list="$(read_package_file "$packages_dir/linux.apt")" || return 1
  while IFS= read -r package; do
    [[ -n "$package" ]] && packages+=("$package")
  done <<<"$package_list"

  sudo apt-get update

  for package in "${packages[@]}"; do
    if apt-cache show "$package" >/dev/null 2>&1; then
      installable+=("$package")
    else
      missing+=("$package")
    fi
  done

  if ((${#installable[@]})); then
    sudo apt-get install -y "${installable[@]}"
  fi

  if ((${#missing[@]})); then
    printf 'Skipped unavailable apt packages: %s\n' "${missing[*]}" >&2
    cat >&2 <<'EOF'
For the full tool set on Linux, install Linuxbrew and rerun this bootstrap.
EOF
  fi
}

install_pacman_packages() {
  local package
  local package_list
  local packages=()
  local installable=()
  local missing=()

  package_list="$(read_package_file "$packages_dir/linux.pacman")" || return 1
  while IFS= read -r package; do
    [[ -n "$package" ]] && packages+=("$package")
  done <<<"$package_list"

  for package in "${packages[@]}"; do
    if pacman -Si "$package" >/dev/null 2>&1; then
      installable+=("$package")
    else
      missing+=("$package")
    fi
  done

  if ((${#installable[@]})); then
    sudo pacman -S --needed --noconfirm "${installable[@]}"
  fi

  if ((${#missing[@]})); then
    printf 'Skipped unavailable pacman packages: %s\n' "${missing[*]}" >&2
  fi
}

find_brew() {
  local candidate

  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  for candidate in \
    /opt/homebrew/bin/brew \
    /usr/local/bin/brew \
    /home/linuxbrew/.linuxbrew/bin/brew
  do
    if [[ -x "$candidate" ]]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done

  return 1
}

if find_brew; then
  brew bundle --file="$packages_dir/macos.brewfile"
  if [[ "$os" == Darwin ]]; then
    "$repo_dir/wallpaper/.config/wallpaper/apply" \
      "$repo_dir/wallpaper/.config/wallpaper/desktop.webp"
  fi
  exit 0
fi

if [[ "$os" == Darwin ]]; then
  cat >&2 <<'EOF'
Homebrew is required for macOS bootstrap.

Install Homebrew, then rerun:
  ./bootstrap/bootstrap.sh
EOF
  exit 1
fi

if [[ "$os" == Linux ]] && command -v apt-get >/dev/null 2>&1; then
  install_apt_packages
  exit 0
fi

if [[ "$os" == Linux ]] && command -v pacman >/dev/null 2>&1; then
  install_pacman_packages
  exit 0
fi

cat >&2 <<'EOF'
No supported package manager found.

Use Homebrew/Linuxbrew with packages/macos.brewfile, or install the bootstrap
tools manually for this platform.
EOF
exit 1
