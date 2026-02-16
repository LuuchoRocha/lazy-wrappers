#!/bin/bash
# Lazy-wrappers simple installer
# Downloads and runs the installer script from the GitHub repository

set -euo pipefail

# Define temporary directory for cloning the repository
REPO_DIR="/tmp/lazy-wrappers-$(date +%s)"
# Delete any existing directory
rm -rf "$REPO_DIR" || true
# Clone the repository
git clone https://github.com/LuuchoRocha/lazy-wrappers.git "$REPO_DIR" 2>/dev/null || {
    echo "Error: Failed to clone repository. Please check your internet connection and try again."
    exit 1
}
# Make the installer script executable
chmod +x "$REPO_DIR/scripts/install"
# Run the installer script
"$REPO_DIR/scripts/install"
exit 0
