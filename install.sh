#!/bin/bash
# Lazy-wrappers simple installer
# Downloads and runs the installer script from the GitHub repository

set -euo pipefail

VERSION=$(cat "./VERSION")
REPO_DIR="/tmp/lazy-wrappers-$(date +%s)"
INSTALL_SCRIPT="scripts/install"

cleanup() {
  rm -rf "$REPO_DIR" || true
}

print_version() {
  echo "lazy-wrappers installer version $VERSION"
}

print_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]
Options:
  -h, --help      Show this help message and exit
  -v, --version   Show the installer version and exit
  --local         Install from the local repository
EOF
}

install_local() {
  if [[ -f "$INSTALL_SCRIPT" ]]; then
    chmod +x "$INSTALL_SCRIPT"
    "$INSTALL_SCRIPT"
    cleanup
  else
    echo "Error: Installer script not found in the current directory. Please run this script from the root of the lazy-wrappers repository or use the --help option for more information."
    exit 1
  fi
}

install_remote() {
  # Define temporary directory for cloning the repository
  # Delete any existing directory
  rm -rf "$REPO_DIR" || true

  # Clone the repository
  git clone https://github.com/LuuchoRocha/lazy-wrappers.git "$REPO_DIR" 2>/dev/null || {
    echo "Error: Failed to clone repository. Please check your internet connection and try again."
    exit 1
  }
  # Make the installer script executable
  chmod +x "$REPO_DIR/$INSTALL_SCRIPT"
  # Run the installer script
  "$REPO_DIR/$INSTALL_SCRIPT"
  # Clean up the cloned repository after installation
  cleanup
}

# Set up trap to clean up temporary files if the script is interrupted
trap cleanup TERM KILL INT ERR

case "$1" in
--version | -v)
  print_version
  exit 0
  ;;
--help | -h)
  print_help
  exit 0
  ;;
--local | -l | --offline | -o)
  install_local
  exit 0
  ;;
"")
  install_remote
  exit 0
  ;;
*)
  echo "Error: Invalid option: $1"
  print_help
  exit 1
  ;;
esac

exit 0
