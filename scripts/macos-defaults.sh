#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS defaults script can only run on Darwin" >&2
  exit 1
fi

log() {
  printf '\033[1;34m==>\033[0m %s\n' "$*"
}

log 'applying macOS defaults'

# Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# Keyboard
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false

killall Finder >/dev/null 2>&1 || true
killall Dock >/dev/null 2>&1 || true
killall SystemUIServer >/dev/null 2>&1 || true

log 'macOS defaults applied'
