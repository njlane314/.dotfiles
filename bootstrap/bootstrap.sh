#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
packages_dir="$repo_dir/packages"
os="$(uname -s)"

read_package_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    printf 'Missing package manifest: %s\n' "$file" >&2
    exit 1
  fi

  sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$file"
}

manifest_packages() {
  local file="$1"
  local package

  while IFS= read -r package; do
    printf '%s\n' "$package"
  done < <(read_package_file "$file")
}

apply_wallpaper() {
  local apply="$repo_dir/wallpaper/.config/wallpaper/apply"
  local image="$repo_dir/wallpaper/.config/wallpaper/desktop.webp"

  [[ "$os" == Darwin ]] || return 0
  [[ -x "$apply" && -f "$image" ]] || return 0

  "$apply" "$image"
}

install_brew_packages() {
  brew bundle --file="$packages_dir/macos.brewfile"
}

install_apt_packages() {
  local package
  local packages=()
  local installable=()
  local missing=()

  while IFS= read -r package; do
    packages+=("$package")
  done < <(manifest_packages "$packages_dir/linux.apt")

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
  local packages=()
  local installable=()
  local missing=()

  while IFS= read -r package; do
    packages+=("$package")
  done < <(manifest_packages "$packages_dir/linux.pacman")

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

if command -v brew >/dev/null 2>&1; then
  install_brew_packages
  apply_wallpaper
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

if [[ "$os" == Linux && -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  install_brew_packages
  apply_wallpaper
  exit 0
fi

if [[ "$os" == Linux && -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  install_brew_packages
  apply_wallpaper
  exit 0
fi

if [[ "$os" == Linux ]] && command -v apt-get >/dev/null 2>&1; then
  install_apt_packages
  apply_wallpaper
  exit 0
fi

if [[ "$os" == Linux ]] && command -v pacman >/dev/null 2>&1; then
  install_pacman_packages
  apply_wallpaper
  exit 0
fi

cat >&2 <<'EOF'
No supported package manager found.

Use Homebrew/Linuxbrew with packages/macos.brewfile, or install the bootstrap
tools manually for this platform.
EOF
exit 1
