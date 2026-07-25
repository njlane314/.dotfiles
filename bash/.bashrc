# ~/.bashrc

BASH_CONFIG="$HOME/.config/bash"

# Only run interactive shell config for interactive shells.
case "$-" in
  *i*) ;;
  *)
    [ -f "$BASH_CONFIG/local.bash" ] && . "$BASH_CONFIG/local.bash"
    return 0
    ;;
esac

[ -f "$BASH_CONFIG/aliases.bash" ] && . "$BASH_CONFIG/aliases.bash"
[ -f "$BASH_CONFIG/functions.bash" ] && . "$BASH_CONFIG/functions.bash"
[ -f "$BASH_CONFIG/prompt.bash" ] && . "$BASH_CONFIG/prompt.bash"

# Machine-specific interactive overrides come last.
[ -f "$BASH_CONFIG/local.bash" ] && . "$BASH_CONFIG/local.bash"
