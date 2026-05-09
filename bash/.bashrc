# ~/.bashrc

# Only run interactive shell config for interactive shells.
case "$-" in
  *i*) ;;
  *) return ;;
esac

BASH_CONFIG="$HOME/.config/bash"

[ -f "$BASH_CONFIG/aliases.bash" ] && . "$BASH_CONFIG/aliases.bash"
[ -f "$BASH_CONFIG/functions.bash" ] && . "$BASH_CONFIG/functions.bash"
[ -f "$BASH_CONFIG/prompt.bash" ] && . "$BASH_CONFIG/prompt.bash"

# Machine-specific config. Do not commit this.
[ -f "$BASH_CONFIG/local.bash" ] && . "$BASH_CONFIG/local.bash"
