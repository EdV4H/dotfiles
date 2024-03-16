#!/usr/bin/env bash

set -ue

function volta() {
  if command -v volta >/dev/null 2>&1; then
    echo "volta is already installed"
  else
    curl https://get.volta.sh | bash
  fi
}

volta
