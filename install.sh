#!/usr/bin/env bash

set -ue # exit on error

# Help message
function helpmsg() {
  print_error "[WIP] Not implemented yet"
}

function main() {
  # Get current dir
  local current_dir
  current_dir=$(dirname "${BASH_SOURCE[0]:-$0}")

  # Load util functions
  source "${current_dir}/scripts/utilfuncs.sh"

  # Parse arguments
  while getopts :h opt; do
    case $opt in
      h)
        helpmsg
        exit 0
        ;;
      \?)
        echo "Invalid option: -$OPTARG"
        exit 1
        ;;
    esac
  done

  # Initialize
  print_info "Initializing system..."
  "${current_dir}/scripts/init.sh"

  print_success "All done!"
}

main "$@"
