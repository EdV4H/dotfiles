#!/usr/bin/env bash

set -ue

function zim() {
  if [ -d "$ZDOTDIR/.zim" ]; then
    echo "zim is already installed"
  else
    curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
  fi
}

zim
