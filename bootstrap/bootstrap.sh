#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
os="$(uname -s)"

if command -v brew >/dev/null 2>&1; then
  brew bundle --file="$repo_dir/Brewfile"
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
  brew bundle --file="$repo_dir/Brewfile"
  exit 0
fi

if [[ "$os" == Linux && -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew bundle --file="$repo_dir/Brewfile"
  exit 0
fi

if [[ "$os" == Linux ]] && command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update

  packages=(
    bat
    bottom
    btop
    clang
    clang-format
    clang-tidy
    clangd
    cppcheck
    direnv
    duf
    du-dust
    emacs
    entr
    eza
    fd-find
    fzf
    gh
    git
    htop
    httpie
    hyperfine
    jq
    just
    lazygit
    make
    procs
    ripgrep
    sd
    starship
    stow
    tealdeer
    tmux
    tokei
    uv
    vim
    watchexec
    yq
    zoxide
  )

  installable=()
  missing=()
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
  exit 0
fi

cat >&2 <<'EOF'
No supported package manager found.

Use Homebrew/Linuxbrew with the repo Brewfile, or install the bootstrap tools
manually for this platform.
EOF
exit 1
