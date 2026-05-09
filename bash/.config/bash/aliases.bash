# listing
if command -v eza >/dev/null 2>&1; then
  alias l='eza --group-directories-first'
  alias la='eza -la --group-directories-first'
  alias ll='eza -lh --git --group-directories-first'
  alias lt='eza --tree --level=2 --group-directories-first'
else
  alias l='ls'
  alias la='ls -la'
  alias ll='ls -lh'
  alias lt='find . -maxdepth 2 -print'
fi

# viewing
alias v='_dotfiles_bat'
alias vp='_dotfiles_bat --paging=always'
alias catp='_dotfiles_bat --style=plain --paging=never'

# search
alias r='rg'
alias rf='rg --files'
alias f='_dotfiles_fd'
alias ff='_dotfiles_fd --type f'
alias fdg='_dotfiles_fd --hidden --exclude .git'

# disk / system
command -v dust >/dev/null 2>&1 && alias dus='dust'
command -v duf >/dev/null 2>&1 && alias df='duf'
if command -v btop >/dev/null 2>&1; then
  alias top='btop'
elif command -v btm >/dev/null 2>&1; then
  alias top='btm'
fi
command -v htop >/dev/null 2>&1 && alias h='htop'
command -v procs >/dev/null 2>&1 && alias psx='procs'

# git
alias g='git'
alias gs='git status --short --branch'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --decorate --graph --all'
alias gp='git pull --ff-only'
alias gps='git push'
alias gpf='git push --force-with-lease'
alias gco='git switch'
alias gcob='git switch -c'
alias gb='git branch'
alias gba='git branch --all'

# GitHub
alias prs='gh pr status'
alias prv='gh pr view --web'
alias prc='gh pr checkout'
alias prl='gh pr list'
alias issues='gh issue list'

# project workflow
alias j='just'
alias jw='watchexec -r -- just'
alias bench='hyperfine'
alias loc='tokei'
alias serve='python3 -m http.server'

# structured data
alias jqr='jq -r'
alias yaml='yq'
alias headers='http --headers'
