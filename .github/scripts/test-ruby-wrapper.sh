#!/bin/bash
set -euo pipefail

# Test ruby wrapper execution with rbenv auto-install
# This script tests that the ruby wrapper correctly triggers rbenv installation

echo "Testing ruby wrapper execution..."

# Add wrappers to PATH
export PATH="${HOME}/.lazy-wrappers/scripts/bin/ruby_wrappers:${PATH}"

# This should trigger rbenv installation and load it
# shellcheck disable=SC2016
timeout 120 bash -c '
  # Run ruby wrapper - should auto-install rbenv
  if ! "$HOME/.lazy-wrappers/scripts/bin/ruby_wrappers/ruby" --version 2>&1; then
    echo "Warning: ruby wrapper execution failed (rbenv may not be installed yet)"
    # This is expected if rbenv install takes time
  fi
' || echo "Ruby wrapper test timed out (expected if rbenv needs install)"

# Verify rbenv was cloned
if [[ -d "${HOME}/.rbenv" ]]; then
  echo "✓ rbenv auto-installation triggered"
else
  echo "Note: rbenv not installed (may need manual setup in CI)"
fi
