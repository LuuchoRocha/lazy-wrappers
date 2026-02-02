#!/bin/bash
set -euo pipefail

# Test lazy-wrappers uninstallation
# This script runs the uninstaller and verifies cleanup

REPO_ROOT="${1:-.}"

echo "Testing uninstallation..."

# Run uninstaller (non-interactive)
echo "n" | "${REPO_ROOT}/uninstall.sh"

# Verify RC files were cleaned
if grep -q "lazy-wrappers" "${HOME}/.bashrc" 2>/dev/null; then
  echo "Error: .bashrc still contains lazy-wrappers references"
  exit 1
fi

if grep -q "lazy-wrappers" "${HOME}/.zshrc" 2>/dev/null; then
  echo "Error: .zshrc still contains lazy-wrappers references"
  exit 1
fi

echo "✓ Uninstallation successful"
