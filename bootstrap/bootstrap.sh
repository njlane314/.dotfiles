#!/usr/bin/env bash
set -euo pipefail

if command -v brew >/dev/null 2>&1; then
  brew install \
    cppcheck \
    emacs \
    htop \
    llvm \
    ripgrep \
    stow \
    tokei \
    tmux \
    vim
  exit 0
fi

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y \
    clang \
    clang-format \
    clang-tidy \
    clangd \
    cppcheck \
    emacs \
    htop \
    make \
    ripgrep \
    stow \
    tokei \
    tmux \
    vim
  exit 0
fi

cat >&2 <<'EOF'
No supported package manager found.

Install the required packages manually:
  stow vim emacs tmux htop tokei llvm/clang ripgrep cppcheck make
EOF
exit 1
