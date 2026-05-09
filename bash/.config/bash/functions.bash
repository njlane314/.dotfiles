cdf() {
  local dir
  dir="$(_dotfiles_fd --type d --hidden --exclude .git . "${1:-.}" | fzf)" &&
    cd "$dir"
}

vf() {
  local file
  file="$(_dotfiles_fd --type f --hidden --exclude .git . "${1:-.}" | fzf)" &&
    "${EDITOR:-vim}" "$file"
}

rgf() {
  local match file line
  match="$(rg --line-number --column --hidden --glob '!.git' "${*:-.}" |
    fzf --delimiter : --preview 'file={1}; line={2}; if command -v bat >/dev/null 2>&1; then bat --color=always --highlight-line "$line" "$file"; elif command -v batcat >/dev/null 2>&1; then batcat --color=always --highlight-line "$line" "$file"; else sed -n "${line}p" "$file"; fi')" || return
  file="$(printf '%s' "$match" | cut -d: -f1)"
  line="$(printf '%s' "$match" | cut -d: -f2)"
  "${EDITOR:-vim}" "+$line" "$file"
}

mkcd() {
  if [[ $# -ne 1 ]]; then
    printf 'usage: mkcd DIR\n' >&2
    return 2
  fi
  mkdir -p "$1" && cd "$1"
}

extract() {
  if [[ $# -ne 1 || ! -f "$1" ]]; then
    printf 'usage: extract FILE\n' >&2
    return 2
  fi

  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.bz2)     bunzip2 "$1" ;;
    *.rar)     unrar x "$1" ;;
    *.gz)      gunzip "$1" ;;
    *.tar)     tar xf "$1" ;;
    *.tbz2)    tar xjf "$1" ;;
    *.tgz)     tar xzf "$1" ;;
    *.zip)     unzip "$1" ;;
    *.7z)      7z x "$1" ;;
    *)         printf 'unknown archive type: %s\n' "$1" >&2; return 1 ;;
  esac
}
