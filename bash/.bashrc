# ~/.bashrc

export BASH_SILENCE_DEPRECATION_WARNING=1

BASH_CONFIG="$HOME/.config/bash"

# Only run interactive shell config for interactive shells.
case "$-" in
  *i*) ;;
  *)
    [ -f "$BASH_CONFIG/local.bash" ] && . "$BASH_CONFIG/local.bash"
    return 0
    ;;
esac

shopt -s histappend
HISTSIZE=10000
HISTFILESIZE=20000

_dotfiles_history_sync() {
  local status=$?
  if [ -n "${HISTFILE:-}" ] && [ -s "$HISTFILE" ] && history -a; then
    history -n
  fi
  return "$status"
}

case ";${PROMPT_COMMAND:-};" in
  *';_dotfiles_history_sync;'*) ;;
  *) PROMPT_COMMAND="_dotfiles_history_sync${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

[ -f "$BASH_CONFIG/aliases.bash" ] && . "$BASH_CONFIG/aliases.bash"
[ -f "$BASH_CONFIG/prompt.bash" ] && . "$BASH_CONFIG/prompt.bash"

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook bash)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

# Machine-specific interactive overrides come last.
[ -f "$BASH_CONFIG/local.bash" ] && . "$BASH_CONFIG/local.bash"
