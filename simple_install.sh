#!/bin/bash
# Lazy-wrappers simple installer
# Downloads and runs the installer script from the GitHub repository

set -euo pipefail

# Define temporary directory for cloning the repository
REPO_DIR="/tmp/lazy-wrappers"
# Delete any existing directory
rm -rf "$REPO_DIR"
# Clone the repository
git clone https://github.com/LuuchoRocha/lazy-wrappers.git "$REPO_DIR"
# Make the installer script executable
chmod +x "$REPO_DIR/install.sh"
# Run the installer script
"$REPO_DIR/install.sh"
exit 0
