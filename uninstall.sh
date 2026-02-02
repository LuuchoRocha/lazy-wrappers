#!/bin/bash
# Lazy-wrappers uninstaller
# Removes wrapper scripts and configuration from shell RC files

set -euo pipefail

# Colors and formatting
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Find config file - check multiple possible locations
# 1. When run from repo root or ~/.lazy-wrappers: ./scripts/config
# 2. When run as lw-uninstall from commands dir: ../../../scripts/config (relative to bin/commands)
CONFIG_FILE=""
if [[ -f "$SCRIPT_SOURCE_DIR/scripts/config" ]]; then
    CONFIG_FILE="$SCRIPT_SOURCE_DIR/scripts/config"
elif [[ -f "$SCRIPT_SOURCE_DIR/../../config" ]]; then
    # Running from scripts/bin/commands/
    CONFIG_FILE="$SCRIPT_SOURCE_DIR/../../config"
fi

if [[ -z "$CONFIG_FILE" ]]; then
    echo "Error: Configuration file not found"
    exit 1
fi

# shellcheck source=scripts/config
. "$CONFIG_FILE"

echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║${NC}             ${BOLD}lazy-wrappers uninstaller${NC}                       ${BOLD}${CYAN}║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${BOLD}→ Cleaning shell configuration${NC}"

# Remove PATH reference from all shell configuration files
for RC_FILE in "${RC_FILES[@]}"; do
    if [[ -f "$RC_FILE" ]]; then
        if cp "$RC_FILE" "${RC_FILE}.bak"; then
            # Use portable sed syntax (works on both GNU and BSD/macOS sed)
            # Create temporary file and move it back to preserve permissions
            sed \
              -e '\#lazy-wrappers:#d' \
              -e "\#$NODE_WRAPPERS_DIR#d" \
              -e "\#$RUBY_WRAPPERS_DIR#d" \
              -e "\#$COMMANDS_DIR#d" \
              -e '\#shell_hook.sh#d' \
              "$RC_FILE" > "${RC_FILE}.tmp" && mv "${RC_FILE}.tmp" "$RC_FILE" || {
                echo -e "  ${RED}✗ Error:${NC} Failed to modify $RC_FILE"
                echo -e "    ${DIM}Backup available at ${RC_FILE}.bak${NC}"
                rm -f "${RC_FILE}.tmp"
                continue
              }
            # Remove any empty lines left at the end
            sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$RC_FILE" > "${RC_FILE}.tmp" && mv "${RC_FILE}.tmp" "$RC_FILE"
            echo -e "  ${GREEN}✓${NC} $RC_FILE ${DIM}(cleaned)${NC}"
        else
            echo -e "  ${YELLOW}⚠ Warning:${NC} Failed to create backup of $RC_FILE, skipping"
        fi
    else
        echo -e "  ${DIM}─${NC} $RC_FILE ${DIM}(not found, skipped)${NC}"
    fi
done

# Remove the installation directory
echo -e "\n${BOLD}→ Removing installation${NC}"
if [[ -d "$INSTALL_DIR" ]]; then
    if rm -rf "$INSTALL_DIR"; then
        echo -e "  ${GREEN}✓${NC} Removed $INSTALL_DIR"
    else
        echo -e "  ${RED}✗ Error:${NC} Failed to remove $INSTALL_DIR"
        exit 1
    fi
else
    echo -e "  ${DIM}─${NC} $INSTALL_DIR ${DIM}(not found, skipped)${NC}"
fi

echo -e "\n${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║${NC}           ${GREEN}${BOLD}✓ Uninstallation completed successfully${NC}          ${GREEN}${BOLD}║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${BOLD}Next step:${NC} Restart your terminal to apply changes.\n"
exit 0
