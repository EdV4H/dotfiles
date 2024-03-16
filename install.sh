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

  # Create symbolic links
  print_info "Creating symbolic links..."
  "${current_dir}/scripts/link.sh"

  # Install zim
  print_info "Installing zim..."
  "${current_dir}/scripts/install-zim.sh"

  # Install volta
  print_info "Installing volta..."
  "${current_dir}/scripts/install-volta.sh"

  # Install npm packages
  print_info "Installing npm packages..."
  "${current_dir}/scripts/install-npm-global-packages.sh"

  print_success "All done!"
}

main "$@"
