# Shared Bash helpers for managed dotfiles.

DOTFILES_OS="$(uname -s 2>/dev/null || printf unknown)"
case "$DOTFILES_OS" in
  Darwin) DOTFILES_PLATFORM=macos ;;
  Linux)  DOTFILES_PLATFORM=linux ;;
  *)      DOTFILES_PLATFORM=unknown ;;
esac
export DOTFILES_PLATFORM

_dotfiles_path_prepend() {
  [[ -n "${1:-}" && -d "$1" ]] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

_dotfiles_path_append() {
  [[ -n "${1:-}" && -d "$1" ]] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$PATH:$1" ;;
  esac
}

_dotfiles_brew_init() {
  local brew_bin

  if command -v brew >/dev/null 2>&1; then
    brew_bin="$(command -v brew)"
  else
    case "$DOTFILES_PLATFORM" in
      macos)
        if [[ -x /opt/homebrew/bin/brew ]]; then
          brew_bin=/opt/homebrew/bin/brew
        elif [[ -x /usr/local/bin/brew ]]; then
          brew_bin=/usr/local/bin/brew
        fi
        ;;
      linux)
        if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
          brew_bin=/home/linuxbrew/.linuxbrew/bin/brew
        fi
        ;;
    esac
  fi

  if [[ -n "${brew_bin:-}" && -x "$brew_bin" ]]; then
    eval "$("$brew_bin" shellenv)"
  fi
}

_dotfiles_fd() {
  if command -v fd >/dev/null 2>&1; then
    fd "$@"
  elif command -v fdfind >/dev/null 2>&1; then
    fdfind "$@"
  else
    printf 'fd is not installed\n' >&2
    return 127
  fi
}

_dotfiles_bat() {
  local bat_cmd arg
  local args=()

  if command -v bat >/dev/null 2>&1; then
    bat_cmd=bat
  elif command -v batcat >/dev/null 2>&1; then
    bat_cmd=batcat
  fi

  if [[ -n "${bat_cmd:-}" ]]; then
    "$bat_cmd" "$@"
    return
  fi

  while (($#)); do
    arg="$1"
    case "$arg" in
      --paging=*|--style=*|--color=*|--highlight-line=*)
        shift
        ;;
      --highlight-line)
        shift
        (($#)) && shift
        ;;
      *)
        args+=("$arg")
        shift
        ;;
    esac
  done

  cat "${args[@]}"
}
