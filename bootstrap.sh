#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"
CONFIG_DIR="$SCRIPT_DIR/config"
ZSHRC_SOURCE="$CONFIG_DIR/zshrc"
VIMRC_SOURCE="$CONFIG_DIR/vimrc"
TMUX_SOURCE="$CONFIG_DIR/tmux.conf"
GITCONFIG_SOURCE="$CONFIG_DIR/gitconfig"
GITIGNORE_SOURCE="$CONFIG_DIR/gitignore_global"
GHOSTTY_SOURCE="$CONFIG_DIR/ghostty/config"
XDG_CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"
MANAGED_CONFIG_DIR="$XDG_CONFIG_ROOT/macsetup"
MANAGED_ZSHRC_TARGET="$MANAGED_CONFIG_DIR/zshrc"
MANAGED_VIMRC_TARGET="$MANAGED_CONFIG_DIR/vimrc"
MANAGED_TMUX_TARGET="$MANAGED_CONFIG_DIR/tmux.conf"
MANAGED_GITCONFIG_TARGET="$MANAGED_CONFIG_DIR/gitconfig"
MANAGED_GITIGNORE_TARGET="$MANAGED_CONFIG_DIR/gitignore_global"
GHOSTTY_TARGET="$XDG_CONFIG_ROOT/ghostty/config"
ZSHRC_TARGET="$HOME/.zshrc"
VIMRC_TARGET="$HOME/.vimrc"
TMUX_TARGET="$HOME/.tmux.conf"
GITCONFIG_TARGET="$HOME/.gitconfig"
ZSHRC_SOURCE_MARKER="# macsetup managed shell config"
VIMRC_SOURCE_MARKER="\" macsetup managed vim config"
TMUX_SOURCE_MARKER="# macsetup managed tmux config"
GITCONFIG_SOURCE_MARKER="# macsetup managed git config"
read -r -d '' ZSHRC_SOURCE_BLOCK <<'EOF' || true
# macsetup managed shell config
if [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/macsetup/zshrc" ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/macsetup/zshrc"
fi
EOF
read -r -d '' VIMRC_SOURCE_BLOCK <<EOF || true
" macsetup managed vim config
if filereadable("$MANAGED_VIMRC_TARGET")
  source $MANAGED_VIMRC_TARGET
endif
EOF
read -r -d '' TMUX_SOURCE_BLOCK <<EOF || true
# macsetup managed tmux config
if-shell '[ -f "$MANAGED_TMUX_TARGET" ]' "source-file $MANAGED_TMUX_TARGET"
EOF
read -r -d '' GITCONFIG_SOURCE_BLOCK <<EOF || true
# macsetup managed git config
[include]
  path = $MANAGED_GITCONFIG_TARGET
EOF

backup_existing_file() {
  local target="$1"
  local backup="$target.backup.$(date +%Y%m%d%H%M%S)"

  cp -p "$target" "$backup"
  echo "Backed up existing $target to $backup"
}

ensure_parent_dir() {
  mkdir -p "$(dirname "$1")"
}

install_managed_file() {
  local source="$1"
  local target="$2"
  local label="$3"

  if [[ ! -f "$source" ]]; then
    echo "Missing source $label: $source" >&2
    exit 1
  fi

  ensure_parent_dir "$target"

  if [[ -f "$target" ]] && cmp -s "$source" "$target"; then
    echo "$label at $target is already up to date"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_existing_file "$target"
  fi

  install -m 0644 "$source" "$target"
  echo "Installed $label to $target"
}

append_block_if_missing() {
  local target="$1"
  local marker="$2"
  local block="$3"
  local label="$4"

  ensure_parent_dir "$target"

  if [[ -f "$target" ]] && grep -Fqs "$marker" "$target"; then
    echo "$target already includes the managed $label block"
    return
  fi

  if [[ -f "$target" ]]; then
    backup_existing_file "$target"
    printf '\n%s\n' "$block" >>"$target"
  else
    install -m 0644 /dev/null "$target"
    printf '%s\n' "$block" >"$target"
  fi

  echo "Updated $target to include the managed $label block"
}

install_managed_gitconfig() {
  local tmp_file

  if [[ ! -f "$GITCONFIG_SOURCE" ]]; then
    echo "Missing source git config: $GITCONFIG_SOURCE" >&2
    exit 1
  fi

  ensure_parent_dir "$MANAGED_GITCONFIG_TARGET"
  tmp_file="$(mktemp)"
  sed "s|__MACSETUP_GITIGNORE__|$MANAGED_GITIGNORE_TARGET|g" "$GITCONFIG_SOURCE" >"$tmp_file"

  if [[ -f "$MANAGED_GITCONFIG_TARGET" ]] && cmp -s "$tmp_file" "$MANAGED_GITCONFIG_TARGET"; then
    echo "Managed git config at $MANAGED_GITCONFIG_TARGET is already up to date"
    rm -f "$tmp_file"
    return
  fi

  if [[ -e "$MANAGED_GITCONFIG_TARGET" || -L "$MANAGED_GITCONFIG_TARGET" ]]; then
    backup_existing_file "$MANAGED_GITCONFIG_TARGET"
  fi

  install -m 0644 "$tmp_file" "$MANAGED_GITCONFIG_TARGET"
  rm -f "$tmp_file"
  echo "Installed managed git config to $MANAGED_GITCONFIG_TARGET"
}

echo "==> Installing Homebrew (if needed)"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

echo "==> Updating Homebrew"
brew update

echo "==> Installing zsh configuration"
install_managed_file "$ZSHRC_SOURCE" "$MANAGED_ZSHRC_TARGET" "managed zsh config"
append_block_if_missing "$ZSHRC_TARGET" "$ZSHRC_SOURCE_MARKER" "$ZSHRC_SOURCE_BLOCK" "zsh"

echo "==> Installing additional managed configs"
install_managed_file "$VIMRC_SOURCE" "$MANAGED_VIMRC_TARGET" "managed vim config"
append_block_if_missing "$VIMRC_TARGET" "$VIMRC_SOURCE_MARKER" "$VIMRC_SOURCE_BLOCK" "vim"

install_managed_file "$TMUX_SOURCE" "$MANAGED_TMUX_TARGET" "managed tmux config"
append_block_if_missing "$TMUX_TARGET" "$TMUX_SOURCE_MARKER" "$TMUX_SOURCE_BLOCK" "tmux"

install_managed_file "$GITIGNORE_SOURCE" "$MANAGED_GITIGNORE_TARGET" "managed global gitignore"
install_managed_gitconfig
append_block_if_missing "$GITCONFIG_TARGET" "$GITCONFIG_SOURCE_MARKER" "$GITCONFIG_SOURCE_BLOCK" "git"

install_managed_file "$GHOSTTY_SOURCE" "$GHOSTTY_TARGET" "Ghostty config"

echo "==> Installing software"
cask_skip=()

skip_cask_if_app_exists() {
  local cask="$1"
  local app="$2"

  if [[ -e "/Applications/$app" ]] && ! brew list --cask "$cask" >/dev/null 2>&1; then
    cask_skip+=("$cask")
    echo "Skipping $cask because /Applications/$app already exists outside Homebrew"
  fi
}

skip_cask_if_app_exists "visual-studio-code" "Visual Studio Code.app"
skip_cask_if_app_exists "iterm2" "iTerm.app"
skip_cask_if_app_exists "rectangle" "Rectangle.app"
skip_cask_if_app_exists "raycast" "Raycast.app"
skip_cask_if_app_exists "google-chrome" "Google Chrome.app"
skip_cask_if_app_exists "bitwarden" "Bitwarden.app"
skip_cask_if_app_exists "anydesk" "AnyDesk.app"
skip_cask_if_app_exists "chatgpt" "ChatGPT.app"
skip_cask_if_app_exists "codex" "Codex.app"
skip_cask_if_app_exists "ghostty" "Ghostty.app"
skip_cask_if_app_exists "synology-drive" "Synology Drive Client.app"
skip_cask_if_app_exists "stats" "Stats.app"

if ((${#cask_skip[@]})); then
  if ! HOMEBREW_BUNDLE_CASK_SKIP="${cask_skip[*]}" brew bundle --file="$BREWFILE" --no-upgrade; then
    echo "brew bundle hit one or more errors; continuing bootstrap"
  fi
else
  if ! brew bundle --file="$BREWFILE" --no-upgrade; then
    echo "brew bundle hit one or more errors; continuing bootstrap"
  fi
fi

echo "==> Applying common macOS defaults"

# Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Dock
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 56
defaults write com.apple.dock mru-spaces -bool false

# Trackpad
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Keyboard
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Screenshots
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"

# Misc
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

echo "==> Restarting affected services"
killall Finder || true
killall Dock || true
killall SystemUIServer || true

echo
echo "Bootstrap complete."
echo "Open a new terminal or run: source ~/.zshrc"
echo "You may need to log out or reboot for some settings."
