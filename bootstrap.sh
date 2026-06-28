#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"
ZSHRC_SOURCE="$SCRIPT_DIR/.zshrc"
ZSHRC_TARGET="$HOME/.zshrc"

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

echo "==> Installing software"
brew bundle --file="$BREWFILE"

echo "==> Installing zsh configuration"
if [[ ! -f "$ZSHRC_SOURCE" ]]; then
  echo "Missing source zsh config: $ZSHRC_SOURCE" >&2
  exit 1
fi

if [[ -f "$ZSHRC_TARGET" ]] && cmp -s "$ZSHRC_SOURCE" "$ZSHRC_TARGET"; then
  echo "Existing $ZSHRC_TARGET is already up to date"
else
  if [[ -e "$ZSHRC_TARGET" || -L "$ZSHRC_TARGET" ]]; then
    backup="$ZSHRC_TARGET.backup.$(date +%Y%m%d%H%M%S)"
    cp -p "$ZSHRC_TARGET" "$backup"
    echo "Backed up existing $ZSHRC_TARGET to $backup"
  fi

  install -m 0644 "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
  echo "Installed $ZSHRC_TARGET"
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
defaults write com.apple.dock tilesize -int 40
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
