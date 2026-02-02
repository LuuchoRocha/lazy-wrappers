#!/bin/bash
set -euo pipefail

# Test wrapper regeneration
# This script verifies that wrappers can be regenerated successfully

echo "Testing wrapper regeneration..."

# Regenerate wrappers
"${HOME}/.lazy-wrappers/scripts/generate_wrappers.sh"

# Verify they still exist
if [[ ! -f "${HOME}/.lazy-wrappers/scripts/bin/node_wrappers/node" ]]; then
  echo "Error: node wrapper not found after regeneration"
  exit 1
fi

if [[ ! -f "${HOME}/.lazy-wrappers/scripts/bin/ruby_wrappers/ruby" ]]; then
  echo "Error: ruby wrapper not found after regeneration"
  exit 1
fi

echo "✓ Wrapper regeneration successful"
