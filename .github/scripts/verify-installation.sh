#!/bin/bash
set -euo pipefail

# Verify lazy-wrappers installation
# This script checks that all components were installed correctly

echo "Verifying lazy-wrappers installation..."

# Check that installation directory exists
if [[ ! -d "${HOME}/.lazy-wrappers" ]]; then
  echo "Error: Installation directory not found"
  exit 1
fi

# Check that wrappers were generated
if [[ ! -d "${HOME}/.lazy-wrappers/scripts/bin/node_wrappers" ]]; then
  echo "Error: Node wrappers directory not found"
  exit 1
fi

if [[ ! -d "${HOME}/.lazy-wrappers/scripts/bin/ruby_wrappers" ]]; then
  echo "Error: Ruby wrappers directory not found"
  exit 1
fi

# Check that at least some wrappers exist
node_count=$(find "${HOME}/.lazy-wrappers/scripts/bin/node_wrappers" -type f | wc -l)
ruby_count=$(find "${HOME}/.lazy-wrappers/scripts/bin/ruby_wrappers" -type f | wc -l)

if [[ ${node_count} -eq 0 ]]; then
  echo "Error: No node wrappers generated"
  exit 1
fi

if [[ ${ruby_count} -eq 0 ]]; then
  echo "Error: No ruby wrappers generated"
  exit 1
fi

echo "✓ Installation successful"
echo "  - Node wrappers: ${node_count}"
echo "  - Ruby wrappers: ${ruby_count}"
