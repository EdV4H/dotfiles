#!/usr/bin/env bash

set -ue # exit on error

# Help message
function helpmsg() {
  echo "[WIP] Not implemented yet"
}

# Install brew
function install_brew() {
  # Check if brew is installed
  if command -v brew &> /dev/null; then
    echo "brew is already installed"
    return
  fi
  echo "Installing brew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# Install Rosetta 2
function install_rosetta() {
  # Check if Rosetta 2 is installed
  if [[ "$(sysctl -in sysctl.proc_translated)" == "1" ]]; then
    echo "Rosetta 2 is already installed"
    return
  fi
  echo "Installing Rosetta 2..."
  softwareupdate --install-rosetta --agree-to-license
}

function main() {
  # Install brew when OS is macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    install_brew
  fi

  # Install Rosetta 2 for Apple Silicon when CPU is M1
  if [[ "$(uname -m)" == "arm64" ]]; then
    install_rosetta
  fi
}

main "$@"
