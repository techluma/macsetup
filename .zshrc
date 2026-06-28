# macsetup zsh configuration

# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Paths
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# macOS app paths
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"

# Shell behavior
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt CORRECT
setopt NO_BEEP

export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000
export EDITOR="${EDITOR:-code --wait}"
export VISUAL="$EDITOR"
export PAGER="${PAGER:-less}"
export LESS="-FRX"

# Completion
autoload -Uz compinit

if command -v brew >/dev/null 2>&1; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
fi

mkdir -p "$XDG_CACHE_HOME/zsh"
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select

# fzf
if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git 2>/dev/null'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git 2>/dev/null'
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

  if [[ -o interactive && -t 0 ]]; then
    if [[ -r "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh" ]]; then
      source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
    fi
    if [[ -r "$(brew --prefix)/opt/fzf/shell/completion.zsh" ]]; then
      source "$(brew --prefix)/opt/fzf/shell/completion.zsh"
    fi
  fi
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Better defaults for Brewfile tools
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias less='bat --paging=always'
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lah --group-directories-first --icons=auto --git'
  alias la='eza -a --group-directories-first --icons=auto'
  alias l='eza -lah --group-directories-first --icons=auto'
  alias tree='eza --tree --group-directories-first --icons=auto'
else
  alias ll='ls -lah'
  alias la='ls -A'
  alias l='ls -lah'
fi

if command -v fd >/dev/null 2>&1; then
  alias find='fd'
fi

if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
fi

if command -v jq >/dev/null 2>&1; then
  alias json='jq .'
fi

if command -v code >/dev/null 2>&1; then
  alias c='code'
  alias codehere='code .'
fi

# Git and GitHub
alias g='git'
alias gs='git status --short --branch'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline --decorate --graph --all'
alias gp='git push'
alias gpl='git pull --ff-only'
alias pr='gh pr'

# Homebrew
alias brews='brew list --formula'
alias casks='brew list --cask'
alias bubo='brew update && brew bundle --file="$HOME/Documents/macsetup/Brewfile" && brew cleanup'
alias brewup='brew update && brew upgrade && brew cleanup'

# Docker / Colima
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias cstart='colima start'
alias cstop='colima stop'
alias cstatus='colima status'

# Python, Node, uv, just, tmux
alias py='python3'
alias venv='python3 -m venv .venv'
alias activate='source .venv/bin/activate'
alias ni='npm install'
alias nr='npm run'
alias ux='uvx'
alias j='just'
alias t='tmux'
alias ta='tmux attach -t'
alias tls='tmux ls'

# Convenience
alias reload='source ~/.zshrc'
alias path='print -l $path'
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'
alias serve='python3 -m http.server'
alias weather='curl wttr.in'
alias myip='curl -s https://ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
alias cleanupds='command find . -name .DS_Store -type f -delete'
alias emptytrash='sudo rm -rf ~/.Trash/*'

# macOS helpers
alias o='open'
alias oo='open .'
alias finder='open -a Finder'
alias chrome='open -a "Google Chrome"'
alias preview='open -a Preview'
alias iterm='open -a iTerm'

function cdf() {
  local dir
  dir="$(osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then POSIX path of (target of front Finder window as alias) else POSIX path of (path to desktop folder as alias)')"
  cd "$dir" || return
}

function mkcd() {
  mkdir -p "$1" && cd "$1" || return
}

function take() {
  mkcd "$@"
}

function trash() {
  local item
  for item in "$@"; do
    osascript -e 'on run argv' \
      -e 'tell application "Finder" to delete POSIX file (item 1 of argv)' \
      -e 'end run' "$item"
  done
}

function pbc() {
  if [[ -n "$1" ]]; then
    pbcopy < "$1"
  else
    pbcopy
  fi
}

function pbp() {
  pbpaste
}

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
