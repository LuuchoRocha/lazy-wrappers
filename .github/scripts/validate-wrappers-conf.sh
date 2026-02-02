#!/bin/bash
set -euo pipefail

# Validate wrappers.conf format
# This script checks that wrappers.conf has valid entries

REPO_ROOT="${1:-.}"
CONFIG_FILE="${REPO_ROOT}/scripts/wrappers.conf"

echo "Validating wrappers.conf format..."

# Check that wrappers.conf exists
if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "Error: wrappers.conf not found at ${CONFIG_FILE}"
  exit 1
fi

error_count=0

# Validate each non-comment line
while IFS=: read -r binary loader || [[ -n "${binary}" ]]; do
  # Skip empty lines and comments
  [[ -z "${binary}" || "${binary}" =~ ^[[:space:]]*# ]] && continue

  # Trim whitespace
  binary=$(echo "${binary}" | xargs)
  loader=$(echo "${loader}" | xargs)

  # Check that binary name is not empty
  if [[ -z "${binary}" ]]; then
    echo "Error: Empty binary name found"
    ((error_count++))
    continue
  fi

  # Check that loader is specified
  if [[ -z "${loader}" ]]; then
    echo "Error: No loader specified for binary '${binary}'"
    ((error_count++))
    continue
  fi

  # Check that loader is valid
  if [[ "${loader}" != "nvm" && "${loader}" != "rbenv" ]]; then
    echo "Error: Invalid loader '${loader}' for binary '${binary}'"
    echo "Must be either 'nvm' or 'rbenv'"
    ((error_count++))
  fi
done < "${CONFIG_FILE}"

if [[ ${error_count} -gt 0 ]]; then
  echo "✗ Validation failed with ${error_count} error(s)"
  exit 1
fi

echo "✓ wrappers.conf validation passed"
