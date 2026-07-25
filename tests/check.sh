#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-check.XXXXXX")"
tmux_socket="$test_root/tmux.sock"
tmux_started=0
checks=0

cleanup() {
  local status=$?

  trap - EXIT
  if ((tmux_started)); then
    tmux -S "$tmux_socket" kill-server >/dev/null 2>&1 || true
  fi

  case "$test_root" in
    "${TMPDIR:-/tmp}"/dotfiles-check.* | /tmp/dotfiles-check.* | /private/tmp/dotfiles-check.*)
      [[ -d "$test_root" ]] && find "$test_root" -depth -delete
      ;;
    *)
      printf 'Refusing to remove unexpected test directory: %s\n' "$test_root" >&2
      status=1
      ;;
  esac

  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

pass() {
  checks=$((checks + 1))
  printf 'ok %d - %s\n' "$checks" "$1"
}

skip() {
  checks=$((checks + 1))
  printf 'ok %d - %s # SKIP\n' "$checks" "$1"
}

fail() {
  printf 'not ok %d - %s\n' "$((checks + 1))" "$1" >&2
  exit 1
}

assert_link() {
  [[ -L "$1" && -e "$1" ]] || fail "expected a valid link at $1"
}

assert_empty_directory() {
  local entry

  [[ -d "$1" && ! -L "$1" ]] || fail "expected a local directory at $1"
  entry="$(find "$1" -mindepth 1 -print -quit)"
  [[ -z "$entry" ]] || fail "expected no runtime state in $1"
}

find_llvm_tool() {
  local candidate
  local name="$1"

  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return 0
  fi

  for candidate in \
    "/opt/homebrew/opt/llvm/bin/$name" \
    "/usr/local/opt/llvm/bin/$name" \
    "/home/linuxbrew/.linuxbrew/opt/llvm/bin/$name"
  do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

wait_for_file_text() {
  local attempt
  local file="$1"
  local value="$2"

  for ((attempt = 0; attempt < 100; attempt++)); do
    grep -F -- "$value" "$file" >/dev/null 2>&1 && return 0
    sleep 0.05
  done

  return 1
}

wait_for_tmux_session_exit() {
  local attempt
  local session="$2"
  local socket="$1"

  for ((attempt = 0; attempt < 100; attempt++)); do
    if ! tmux -S "$socket" has-session -t "$session" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.05
  done

  return 1
}

while IFS= read -r file; do
  [[ -f "$repo_dir/$file" ]] || continue
  bash -n "$repo_dir/$file"
done < <(
  git -C "$repo_dir" ls-files \
    --cached --others --exclude-standard \
    '*.bash' '*.sh' '*/apply' '*/pager' 'tests/fixtures/*'
)
pass "shell files parse with Bash"

[[ -z "$(find "$repo_dir" -mindepth 2 -name .git -print -quit)" ]] ||
  fail "a nested Git repository remains inside the dotfiles checkout"
for moved_path in bootstrap templates terminal wallpaper repos; do
  [[ ! -e "$repo_dir/$moved_path" ]] ||
    fail "out-of-scope path remains in dotfiles: $moved_path"
done
pass "repository contains only home configuration responsibilities"

"$repo_dir/install.sh" --help >"$test_root/install-help.out"
grep -F -- '--dry-run' "$test_root/install-help.out" >/dev/null ||
  fail "installer help does not describe dry runs"
"$repo_dir/migrations/2026-07-xdg-state.sh" --help \
  >"$test_root/migration-help.out"

dry_run_target="$test_root/dry-run-home"
DOTFILES_TARGET="$dry_run_target" "$repo_dir/install.sh" --dry-run bash \
  >"$test_root/install-dry-run.out"
[[ ! -e "$dry_run_target" ]] ||
  fail "installer dry run changed a missing target"
pass "installer and migration help work, and install dry runs are inert"

migration_target="$test_root/migration-home"
mkdir -p "$migration_target/.vim/undo"
printf 'legacy undo\n' >"$migration_target/.vim/undo/state"
DOTFILES_TARGET="$migration_target" \
  "$repo_dir/migrations/2026-07-xdg-state.sh" --dry-run \
  >"$test_root/migration-dry-run.out"
[[ -f "$migration_target/.vim/undo/state" ]] ||
  fail "migration dry run moved legacy Vim state"
[[ ! -e "$migration_target/.local/state/vim/undo" ]] ||
  fail "migration dry run created an XDG state directory"
DOTFILES_TARGET="$migration_target" \
  "$repo_dir/migrations/2026-07-xdg-state.sh" \
  >"$test_root/migration.out"
grep -Fx 'legacy undo' "$migration_target/.local/state/vim/undo/state" \
  >/dev/null || fail "one-time migration did not preserve Vim undo state"
pass "versioned migration previews safely and preserves legacy Vim state"

migration_conflict_target="$test_root/migration-conflict-home"
mkdir -p \
  "$migration_conflict_target/.vim/autoload" \
  "$migration_conflict_target/.vim/swap" \
  "$migration_conflict_target/.cache/vim/swap"
printf 'must stay put\n' >"$migration_conflict_target/.vim/autoload/state"
printf 'source conflict\n' >"$migration_conflict_target/.vim/swap/source"
printf 'destination conflict\n' \
  >"$migration_conflict_target/.cache/vim/swap/destination"
if DOTFILES_TARGET="$migration_conflict_target" \
  "$repo_dir/migrations/2026-07-xdg-state.sh" \
  >"$test_root/migration-conflict.out" 2>&1
then
  fail "migration merged two non-empty state directories"
fi
[[ -f "$migration_conflict_target/.vim/autoload/state" ]] ||
  fail "migration moved state before completing its preflight"
[[ ! -e "$migration_conflict_target/.local/share/vim/autoload" ]] ||
  fail "failed migration left partially moved Vim state"

migration_ancestor_target="$test_root/migration-ancestor-home"
mkdir -p \
  "$migration_ancestor_target/.vim/autoload" \
  "$migration_ancestor_target/.vim/undo" \
  "$migration_ancestor_target/.local"
printf 'must also stay put\n' \
  >"$migration_ancestor_target/.vim/autoload/state"
printf 'legacy undo\n' >"$migration_ancestor_target/.vim/undo/state"
printf 'blocks the state root\n' >"$migration_ancestor_target/.local/state"
if DOTFILES_TARGET="$migration_ancestor_target" \
  "$repo_dir/migrations/2026-07-xdg-state.sh" \
  >"$test_root/migration-ancestor.out" 2>&1
then
  fail "migration ignored a non-directory destination ancestor"
fi
[[ -f "$migration_ancestor_target/.vim/autoload/state" ]] ||
  fail "migration moved state before validating destination ancestors"
[[ -f "$migration_ancestor_target/.vim/undo/state" ]] ||
  fail "failed destination validation moved legacy undo state"
[[ ! -e "$migration_ancestor_target/.local/share/vim/autoload" ]] ||
  fail "destination validation left partially moved Vim state"
pass "migration preflights every Vim state move before changing the target"

folded_config_target="$test_root/migration-folded-config-home"
mkdir -p "$folded_config_target"
ln -s "$repo_dir/bash/.config" "$folded_config_target/.config"
DOTFILES_TARGET="$folded_config_target" \
  "$repo_dir/migrations/2026-07-xdg-state.sh" --dry-run \
  >"$test_root/migration-folded-config-dry-run.out"
[[ -L "$folded_config_target/.config" ]] ||
  fail "migration dry run unfolded the legacy config link"
DOTFILES_TARGET="$folded_config_target" \
  "$repo_dir/migrations/2026-07-xdg-state.sh" \
  >"$test_root/migration-folded-config.out"
[[ ! -L "$folded_config_target/.config" ]] ||
  fail "migration left the legacy folded config link in place"
if [[ -f "$repo_dir/bash/.config/bash/local.bash" ]]; then
  cmp -s "$repo_dir/bash/.config/bash/local.bash" \
    "$folded_config_target/.config/bash/local.bash" ||
    fail "migration did not preserve local.bash while unfolding config"
  [[ ! -L "$folded_config_target/.config/bash/local.bash" ]] ||
    fail "migration preserved local.bash as another managed link"
else
  [[ ! -e "$folded_config_target/.config/bash/local.bash" ]] ||
    fail "migration invented a machine-local Bash file"
fi
pass "migration unfolds legacy config with or without machine-local state"

target_dir="$test_root/home"
DOTFILES_TARGET="$target_dir" "$repo_dir/install.sh" >"$test_root/install.out" 2>&1

for path in \
  .bash_profile \
  .bashrc \
  .config/bash/aliases.bash \
  .config/git/config \
  .config/git/pager \
  .config/gdb/gdbinit \
  .editorconfig \
  .emacs.d/early-init.el \
  .emacs.d/init.el \
  .emacs.d/lisp/dotfiles-format.el \
  .emacs.d/lisp/dotfiles-packages.el \
  .tmux.conf \
  .vimrc
do
  assert_link "$target_dir/$path"
done

for path in \
  .local/share/vim/autoload \
  .local/share/vim/plugged \
  .local/state/vim/undo \
  .cache/vim/backup \
  .cache/vim/swap \
  .emacs.d/elpa \
  .emacs.d/var/auto-save \
  .emacs.d/var/backup
do
  assert_empty_directory "$target_dir/$path"
done

for path in autoload backup plugged swap undo; do
  [[ ! -e "$target_dir/.vim/$path" && ! -L "$target_dir/.vim/$path" ]] ||
    fail "legacy Vim runtime path was recreated: $target_dir/.vim/$path"
done

[[ ! -e "$target_dir/.config/bash/local.bash" ]] ||
  fail "machine-local Bash config leaked into the target"

while IFS= read -r link; do
  [[ -e "$link" ]] || fail "broken link created at $link"
done < <(find "$target_dir" -type l -print)

DOTFILES_TARGET="$target_dir" "$repo_dir/install.sh" >"$test_root/reinstall.out" 2>&1
pass "clean and repeated installs are isolated and idempotent"

ignore_probe="$test_root/ignore-probe"
mkdir -p "$ignore_probe/source" "$ignore_probe/targets"
for package in bash vim emacs git; do
  mkdir -p "$ignore_probe/source/$package" "$ignore_probe/targets/$package"
  cp "$repo_dir/$package/.stow-local-ignore" \
    "$ignore_probe/source/$package/.stow-local-ignore"
  printf 'lock\n' >"$ignore_probe/source/$package/.#lock"
  printf 'autosave\n' >"$ignore_probe/source/$package/#autosave#"
  printf 'backup\n' >"$ignore_probe/source/$package/config~"
  stow --dir="$ignore_probe/source" --target="$ignore_probe/targets/$package" "$package"
  for artifact in ".#lock" "#autosave#" "config~"; do
    [[ ! -e "$ignore_probe/targets/$package/$artifact" ]] ||
      fail "$package Stow package leaked an editor artifact: $artifact"
  done
done
pass "Stow packages ignore editor lock, autosave, and backup files"

override_dir="$test_root/override"
mkdir -p "$override_dir"
if DOTFILES_TARGET="$target_dir" "$repo_dir/install.sh" vim "--target=$override_dir" \
  >"$test_root/invalid-package.out" 2>&1
then
  fail "an option-like package argument was accepted"
fi
grep -F "Unknown option" "$test_root/invalid-package.out" >/dev/null ||
  fail "invalid option failure was not actionable"
[[ ! -e "$override_dir/.vimrc" ]] || fail "an argument overrode DOTFILES_TARGET"
pass "package arguments cannot inject Stow options"

rollback_dir="$test_root/rollback"
mkdir -p "$rollback_dir/.config/bash"
printf 'original bashrc\n' >"$rollback_dir/.bashrc"
printf 'blocking aliases\n' >"$rollback_dir/.config/bash/aliases.bash"
if DOTFILES_TARGET="$rollback_dir" "$repo_dir/install.sh" bash \
  >"$test_root/rollback.out" 2>&1
then
  fail "an unresolved Stow conflict unexpectedly succeeded"
fi
grep -Fx "original bashrc" "$rollback_dir/.bashrc" >/dev/null ||
  fail "the original bashrc was not restored"
grep -Fx "blocking aliases" "$rollback_dir/.config/bash/aliases.bash" >/dev/null ||
  fail "the unrelated conflict was changed"
[[ -z "$(find "$rollback_dir" -name '.bashrc.before-dotfiles-*' -print -quit)" ]] ||
  fail "a failed install left a permanent backup"
pass "failed installs roll back automatic conflict backups"

interrupt_dir="$test_root/interrupted-install"
interrupt_bin="$test_root/interrupted-install-bin"
interrupt_tmp="$test_root/interrupted-install-tmp"
mkdir -p "$interrupt_dir" "$interrupt_bin" "$interrupt_tmp"
printf 'original bashrc\n' >"$interrupt_dir/.bashrc"
cat >"$interrupt_bin/mv" <<'EOF'
#!/usr/bin/env bash
set -e
"${DOTFILES_REAL_MV:?}" "$@"
if [[ ! -e "${DOTFILES_INTERRUPT_MARKER:?}" ]]; then
  : >"$DOTFILES_INTERRUPT_MARKER"
  kill -TERM "$PPID"
fi
EOF
chmod +x "$interrupt_bin/mv"
if DOTFILES_REAL_MV="$(command -v mv)" \
  DOTFILES_INTERRUPT_MARKER="$test_root/interrupted-install.marker" \
  TMPDIR="$interrupt_tmp" \
  PATH="$interrupt_bin:$PATH" \
  DOTFILES_TARGET="$interrupt_dir" "$repo_dir/install.sh" bash \
  >"$test_root/interrupted-install.out" 2>&1
then
  fail "installer ignored an interruption while staging a conflict"
fi
grep -Fx 'original bashrc' "$interrupt_dir/.bashrc" >/dev/null ||
  fail "interrupted conflict staging stranded the original bashrc"
[[ -z "$(find "$interrupt_dir" -name '.bashrc.before-dotfiles-*' \
  -print -quit)" ]] || fail "interrupted install left a shell backup behind"
[[ -z "$(find "$interrupt_tmp" -mindepth 1 -print -quit)" ]] ||
  fail "interrupted install leaked its transaction directory"
pass "interruptions during conflict staging restore the original file"

state_failure_dir="$test_root/state-directory-failure"
mkdir -p "$state_failure_dir"
printf 'original bashrc\n' >"$state_failure_dir/.bashrc"
printf 'blocks the XDG data root\n' >"$state_failure_dir/.local"
if DOTFILES_TARGET="$state_failure_dir" "$repo_dir/install.sh" bash vim \
  >"$test_root/state-directory-failure.out" 2>&1
then
  fail "installer ignored a blocked Vim state directory"
fi
grep -Fx 'original bashrc' "$state_failure_dir/.bashrc" >/dev/null ||
  fail "state setup failure did not restore a staged shell conflict"
[[ -z "$(find "$state_failure_dir" -name '.bashrc.before-dotfiles-*' \
  -print -quit)" ]] || fail "state setup failure left a shell backup behind"
[[ ! -e "$state_failure_dir/.vimrc" && ! -L "$state_failure_dir/.vimrc" ]] ||
  fail "failed state setup left Vim configuration installed"
pass "state-directory failures roll back conflicts before Stow changes the target"

backup_dir="$test_root/backup"
mkdir -p "$backup_dir"
printf 'original bashrc\n' >"$backup_dir/.bashrc"
DOTFILES_TARGET="$backup_dir" "$repo_dir/install.sh" bash >"$test_root/backup.out" 2>&1
assert_link "$backup_dir/.bashrc"
backup_path="$(find "$backup_dir" -maxdepth 1 -name '.bashrc.before-dotfiles-*' -print -quit)"
[[ -n "$backup_path" ]] || fail "a replaced bashrc was not backed up"
grep -Fx "original bashrc" "$backup_path" >/dev/null ||
  fail "the bashrc backup did not preserve its contents"
pass "successful installs preserve conflicting shell entry points"

identical_dir="$test_root/identical"
mkdir -p "$identical_dir"
cp "$repo_dir/bash/.bash_profile" "$identical_dir/.bash_profile"
DOTFILES_TARGET="$identical_dir" "$repo_dir/install.sh" bash \
  >"$test_root/identical.out" 2>&1
assert_link "$identical_dir/.bash_profile"
[[ -z "$(find "$identical_dir" -name '.bash_profile.before-dotfiles-*' -print -quit)" ]] ||
  fail "an identical file left an unnecessary backup"
pass "identical files become links without backup clutter"

git config --file "$target_dir/.config/git/config" --list >/dev/null
pager_output="$(
  printf 'fallback\n' |
    HOME="$target_dir" PATH=/usr/bin:/bin \
      "$target_dir/.config/git/pager" --color-only
)"
[[ "$pager_output" == "fallback" ]] || fail "Git pager fallback changed its input"

unborn_repo="$test_root/unborn-git"
mkdir -p "$unborn_repo"
git -C "$unborn_repo" init -q
printf 'first\n' >"$unborn_repo/first"
git -C "$unborn_repo" add first
HOME="$target_dir" git -C "$unborn_repo" unstage
[[ "$(git -C "$unborn_repo" status --short)" == "?? first" ]] ||
  fail "git unstage failed on an unborn branch"
if HOME="$target_dir" git config --get alias.undo >/dev/null; then
  fail "the unsafe git undo alias is still configured"
fi
pass "Git config, pager fallback, and unborn-branch unstage work"

HOME="$target_dir" /bin/bash --noprofile --rcfile "$target_dir/.bashrc" \
  -ic 'alias ll >/dev/null; [[ "$PS1" == "\\u@\\h:\\w\\$ " ]]' 2>/dev/null
pass "Bash config loads in an isolated home"

mkdir -p "$target_dir/project"
printf 'int main() { return 0; }\n' >"$target_dir/project/main.cpp"
printf '{"value": true}\n' >"$target_dir/project/data.json"
printf 'all:\n\t@true\n' >"$target_dir/project/base.mk"

if command -v vim >/dev/null 2>&1; then
  vim_with_test_home() {
    HOME="$target_dir" \
      XDG_DATA_HOME="$target_dir/.local/share" \
      XDG_STATE_HOME="$target_dir/.local/state" \
      XDG_CACHE_HOME="$target_dir/.cache" \
      vim "$@"
  }

  if command -v cc >/dev/null 2>&1; then
    c_source="$test_root/hello !#% world.c"
    printf 'int main(void) { return 0; }\n' >"$c_source"
    vim_with_test_home -Nu "$target_dir/.vimrc" -i NONE -n -es "$c_source" \
      '+set nomore' \
      '+call feedkeys("\<Space>b", "xt")' \
      '+if v:shell_error | cquit | endif' \
      '+call feedkeys("\<Space>x", "xt")' \
      '+if v:shell_error | cquit | endif' \
      '+qall!'
    [[ -x "${c_source%.c}" ]] ||
      fail "Vim did not quote a C filename containing Ex metacharacters"
  fi

  if command -v c++ >/dev/null 2>&1; then
    cpp_source="$test_root/hello !#% world.cpp"
    printf 'int main() { return 0; }\n' >"$cpp_source"
    vim_with_test_home -Nu "$target_dir/.vimrc" -i NONE -n -es "$cpp_source" \
      '+set nomore' \
      '+call feedkeys("\<Space>b", "xt")' \
      '+if v:shell_error | cquit | endif' \
      '+call feedkeys("\<Space>x", "xt")' \
      '+if v:shell_error | cquit | endif' \
      '+qall!'
    [[ -x "${cpp_source%.cpp}" ]] ||
      fail "Vim did not quote a C++ filename containing Ex metacharacters"
  fi

  DOTFILES_VIM_HOME="$target_dir" \
    DOTFILES_ORIGINAL_PATH="$PATH" \
    vim_with_test_home -Nu "$target_dir/.vimrc" -i NONE -n -es \
      -S "$repo_dir/tests/vim-config-test.vim"

  pass "Vim config loads with global C++, ALE, and EditorConfig settings"
else
  skip "Vim is not installed"
fi

if command -v emacs >/dev/null 2>&1; then
  emacs --batch -Q \
    --eval "(with-temp-buffer (insert-file-contents \"$repo_dir/emacs/.emacs.d/early-init.el\") (emacs-lisp-mode) (check-parens))" \
    --eval "(with-temp-buffer (insert-file-contents \"$repo_dir/emacs/.emacs.d/init.el\") (emacs-lisp-mode) (check-parens))" \
    --eval "(with-temp-buffer (insert-file-contents \"$repo_dir/emacs/.emacs.d/lisp/dotfiles-packages.el\") (emacs-lisp-mode) (check-parens))"
  printf '(setq use-package-always-ensure t)\n' \
    >"$target_dir/.emacs.d/var/custom.el"
  HOME="$target_dir" emacs --batch -Q \
    --eval "(progn (require 'package) (advice-add 'package-refresh-contents :override (lambda (&rest _) (error \"network access during startup\"))) (advice-add 'package-install :override (lambda (&rest _) (error \"package install during startup\"))))" \
    -l "$target_dir/.emacs.d/init.el" \
    --eval "(unless create-lockfiles (error \"Emacs lockfiles are disabled\"))" \
    --eval "(when (and (featurep 'use-package) use-package-always-ensure) (error \"Custom re-enabled package installation\"))" \
    --eval "(unless (bound-and-true-p editorconfig-mode) (error \"EditorConfig is disabled\"))" \
    --eval "(with-current-buffer (find-file-noselect \"$target_dir/project/base.mk\") (unless (and indent-tabs-mode (= tab-width 8)) (error \"Make EditorConfig settings were not applied\")))"
  DOTFILES_TEST_FIXTURES="$repo_dir/tests/fixtures" \
    emacs --batch -Q \
      -L "$repo_dir/emacs/.emacs.d/lisp" \
      -l "$repo_dir/tests/emacs-format-test.el"
  pass "Emacs starts offline with EditorConfig and preserves failed formats"
else
  skip "Emacs is not installed"
fi

if command -v tmux >/dev/null 2>&1; then
  tmux_started=1
  tmux -S "$tmux_socket" -f "$target_dir/.tmux.conf" new-session -d -s check
  [[ "$(tmux -S "$tmux_socket" show-options -gv mouse)" == "on" ]] ||
    fail "tmux did not load the configured mouse setting"
  if infocmp tmux-256color >/dev/null 2>&1; then
    expected_terminal=tmux-256color
  else
    expected_terminal=screen-256color
  fi
  [[ "$(tmux -S "$tmux_socket" show-options -gv default-terminal)" == \
    "$expected_terminal" ]] || fail "tmux selected the wrong terminal type"
  [[ "$(tmux -S "$tmux_socket" show-options -gv status-style)" == \
    *"bg=colour236"* ]] || fail "tmux did not load the neutral status style"
  tmux -S "$tmux_socket" kill-server
  tmux_started=0

  fresh_history_file="$test_root/fresh-bash-history"
  printf -v fresh_history_shell \
    'env HOME=%q HISTFILE=%q TERM=xterm-256color /bin/bash --noprofile --rcfile %q -i' \
    "$target_dir" "$fresh_history_file" "$target_dir/.bashrc"
  tmux_started=1
  tmux -S "$tmux_socket" -f "$target_dir/.tmux.conf" \
    new-session -d -s fresh-history "$fresh_history_shell"
  fresh_history_pane="$(
    tmux -S "$tmux_socket" list-panes -t fresh-history -F '#{pane_id}'
  )"
  tmux -S "$tmux_socket" send-keys -t "$fresh_history_pane" \
    ': FRESH_HISTORY_MARKER' Enter exit Enter
  wait_for_tmux_session_exit "$tmux_socket" fresh-history ||
    fail "the fresh Bash history pane did not exit"
  tmux_started=0
  wait_for_file_text "$fresh_history_file" ': FRESH_HISTORY_MARKER' ||
    fail "a fresh Bash history file lost its first command"

  history_file="$test_root/bash-history"
  printf 'existing command\n' >"$history_file"
  printf -v history_shell \
    'env HOME=%q HISTFILE=%q TERM=xterm-256color /bin/bash --noprofile --rcfile %q -i' \
    "$target_dir" "$history_file" "$target_dir/.bashrc"
  tmux_started=1
  tmux -S "$tmux_socket" -f "$target_dir/.tmux.conf" \
    new-session -d -s history "$history_shell"
  history_window="$(tmux -S "$tmux_socket" list-windows -t history -F '#{window_id}')"
  tmux -S "$tmux_socket" split-window -d -t "$history_window" "$history_shell"
  history_panes=(
    $(tmux -S "$tmux_socket" list-panes -t "$history_window" -F '#{pane_id}')
  )
  [[ ${#history_panes[@]} == 2 ]] || fail "tmux did not create two history panes"
  tmux -S "$tmux_socket" send-keys -t "${history_panes[0]}" \
    ': PANE_ONE_HISTORY_MARKER' Enter
  tmux -S "$tmux_socket" send-keys -t "${history_panes[1]}" \
    ': PANE_TWO_HISTORY_MARKER' Enter
  wait_for_file_text "$history_file" ': PANE_ONE_HISTORY_MARKER' ||
    fail "the first tmux pane did not append its Bash history"
  wait_for_file_text "$history_file" ': PANE_TWO_HISTORY_MARKER' ||
    fail "the second tmux pane did not append its Bash history"
  history_startup="$(
    tmux -S "$tmux_socket" capture-pane -p -t "$history_window" -S -20
  )"
  [[ "$history_startup" != *"default interactive shell is now zsh"* ]] ||
    fail "Bash still displayed Apple's default-shell warning"
  tmux -S "$tmux_socket" send-keys -t "${history_panes[0]}" exit Enter
  tmux -S "$tmux_socket" send-keys -t "${history_panes[1]}" \
    ': PANE_TWO_LATER_MARKER' Enter
  wait_for_file_text "$history_file" ': PANE_TWO_LATER_MARKER' ||
    fail "the surviving tmux pane did not append its later history"
  tmux -S "$tmux_socket" send-keys -t "${history_panes[1]}" exit Enter
  wait_for_tmux_session_exit "$tmux_socket" history ||
    fail "the Bash history panes did not exit"
  tmux_started=0
  grep -F ': PANE_ONE_HISTORY_MARKER' "$history_file" >/dev/null ||
    fail "the second tmux pane exit overwrote the first pane's history"
  pass "tmux loads and Bash history survives concurrent panes"
else
  skip "tmux is not installed"
fi

if clang_format="$(find_llvm_tool clang-format)"; then
  (
    cd "$repo_dir/cpp"
    printf 'int main(){return 0;}\n' | "$clang_format" --style=file >/dev/null
  )
  pass "clang-format config parses"
else
  skip "clang-format is not installed"
fi

if clang_tidy="$(find_llvm_tool clang-tidy)"; then
  tidy_source="$test_root/clang-tidy.cpp"
  printf 'int add(int left, int right) { return left + right; }\n' >"$tidy_source"
  tidy_checks="$(
    "$clang_tidy" --config-file="$repo_dir/cpp/.clang-tidy" --list-checks
  )"
  if grep -E '^[[:space:]]+(modernize|readability|cppcoreguidelines)-' \
    <<<"$tidy_checks" >/dev/null
  then
    fail "clang-tidy enabled a style-only check family"
  fi
  tidy_output="$(
    "$clang_tidy" --config-file="$repo_dir/cpp/.clang-tidy" \
      "$tidy_source" -- -std=c++20 2>&1
  )"
  [[ "$tidy_output" != *"use a trailing return type"* ]] ||
    fail "clang-tidy still suggests style-only trailing return types"
  pass "clang-tidy uses the quiet correctness and performance policy"
else
  skip "clang-tidy is not installed"
fi

printf '1..%d\n' "$checks"
