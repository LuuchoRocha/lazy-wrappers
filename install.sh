#!/bin/bash
# Lazy-wrappers installer
# Installs wrapper scripts to defer loading of nvm and rbenv until needed

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

# Source configuration file
if [[ ! -f "$SCRIPT_SOURCE_DIR/scripts/config" ]]; then
    echo "Error: Configuration file not found at $SCRIPT_SOURCE_DIR/scripts/config"
    exit 1
fi

# shellcheck source=scripts/config
. "$SCRIPT_SOURCE_DIR/scripts/config"

# Validate prerequisites
if ! command -v git &>/dev/null; then
    echo -e "${YELLOW}⚠ Warning:${NC} git is not installed. It will be required if nvm or rbenv need to be cloned."
fi

echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║${NC}              ${BOLD}lazy-wrappers installer${NC}                       ${BOLD}${CYAN}║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"

# Create installation directory
echo -e "${BOLD}→ Installing to${NC} ${CYAN}$INSTALL_DIR${NC}"
mkdir -p "$INSTALL_DIR/scripts/bin/node_wrappers" "$INSTALL_DIR/scripts/bin/ruby_wrappers" "$INSTALL_DIR/scripts/bin/commands"

# Copy scripts directory (excluding bin subdirectories which will be generated)
echo -e "${DIM}  Copying scripts...${NC}"
for file in "$SCRIPT_SOURCE_DIR/scripts"/*; do
    if [[ -f "$file" ]]; then
        if ! cp -f "$file" "$INSTALL_DIR/scripts/"; then
            echo -e "${RED}✗ Error:${NC} Failed to copy $(basename "$file") to $INSTALL_DIR/scripts/"
            exit 1
        fi
    fi
done

# Copy static wrappers (nvm, rbenv) that are not generated dynamically
echo -e "${DIM}  Copying static wrappers...${NC}"
if [[ -f "$SCRIPT_SOURCE_DIR/scripts/bin/node_wrappers/nvm" ]]; then
    cp -f "$SCRIPT_SOURCE_DIR/scripts/bin/node_wrappers/nvm" "$NODE_WRAPPERS_DIR/"
fi
if [[ -f "$SCRIPT_SOURCE_DIR/scripts/bin/ruby_wrappers/rbenv" ]]; then
    cp -f "$SCRIPT_SOURCE_DIR/scripts/bin/ruby_wrappers/rbenv" "$RUBY_WRAPPERS_DIR/"
fi

# Copy lw-* commands to the commands directory
echo -e "${DIM}  Copying commands...${NC}"
for cmd_file in "$SCRIPT_SOURCE_DIR/scripts/bin/commands"/lw-*; do
    if [[ -f "$cmd_file" ]]; then
        cmd_name=$(basename "$cmd_file")
        if ! cp -f "$cmd_file" "$COMMANDS_DIR/$cmd_name"; then
            echo -e "${RED}✗ Error:${NC} Failed to copy $cmd_name to $COMMANDS_DIR"
            exit 1
        fi
        chmod +x "$COMMANDS_DIR/$cmd_name"
    fi
done

# Generate all wrapper scripts from wrappers.conf
echo -e "${DIM}  Generating wrappers...${NC}"
if [[ ! -f "$INSTALL_DIR/scripts/generate_wrappers" ]]; then
    echo -e "${RED}✗ Error:${NC} Wrapper generator script not found"
    exit 1
fi

chmod +x "$INSTALL_DIR/scripts/generate_wrappers"
if ! "$INSTALL_DIR/scripts/generate_wrappers" >/dev/null; then
    echo -e "${RED}✗ Error:${NC} Failed to generate wrapper scripts"
    exit 1
fi

# Make wrapper scripts executable
if [[ -d "$NODE_WRAPPERS_DIR" ]] && [[ -n "$(ls -A "$NODE_WRAPPERS_DIR" 2>/dev/null)" ]]; then
    if ! chmod +x "$NODE_WRAPPERS_DIR"/* 2>/dev/null; then
        echo -e "${YELLOW}⚠ Warning:${NC} Failed to make some node wrappers executable"
        echo -e "  You may need to run: ${DIM}chmod +x $NODE_WRAPPERS_DIR/*${NC}"
    fi
fi

if [[ -d "$RUBY_WRAPPERS_DIR" ]] && [[ -n "$(ls -A "$RUBY_WRAPPERS_DIR" 2>/dev/null)" ]]; then
    if ! chmod +x "$RUBY_WRAPPERS_DIR"/* 2>/dev/null; then
        echo -e "${YELLOW}⚠ Warning:${NC} Failed to make some ruby wrappers executable"
        echo -e "  You may need to run: ${DIM}chmod +x $RUBY_WRAPPERS_DIR/*${NC}"
    fi
fi

for script in nvmload rbenvload shell_hook; do
    if [[ -f "$INSTALL_DIR/scripts/$script" ]]; then
        chmod +x "$INSTALL_DIR/scripts/$script"
    fi
done

# The lines we'll add to RC files
# Use a guard to prevent duplicate PATH entries when shell config is sourced multiple times
PATH_COMMENT="# lazy-wrappers: Add wrapper scripts to PATH and load shell hook"
PATH_EXPORT="[[ \":\$PATH:\" != *\":$NODE_WRAPPERS_DIR:\"* ]] && export PATH=\"$NODE_WRAPPERS_DIR:$RUBY_WRAPPERS_DIR:$COMMANDS_DIR:\$PATH\""
HOOK_SOURCE=". \"$INSTALL_DIR/scripts/shell_hook\""

echo -e "\n${BOLD}→ Configuring shell${NC}"

# Process each RC file to add PATH
for RC_FILE in "${RC_FILES[@]}"; do
    # Backup the shell configuration file if it exists
    if [[ -f "$RC_FILE" ]]; then
        RC_BACKUP="${RC_FILE}.backup-$(date +%Y%m%d%H%M%S)"
        if cp "$RC_FILE" "$RC_BACKUP"; then
            echo -e "  ${DIM}Backup saved: $RC_BACKUP${NC}"
        else
            echo -e "  ${YELLOW}⚠ Warning:${NC} Failed to create backup of $RC_FILE"
        fi
    else
        # Create the RC file if it doesn't exist
        if ! touch "$RC_FILE" 2>/dev/null; then
            echo -e "  ${YELLOW}⚠ Warning:${NC} Cannot create $RC_FILE, skipping"
            continue
        fi
    fi

    # Check if already installed
    if [[ -f "$RC_FILE" ]] && grep -qF "lazy-wrappers" "$RC_FILE"; then
        echo -e "  ${GREEN}✓${NC} $RC_FILE ${DIM}(already configured)${NC}"
    else
        {
            echo ""
            echo "$PATH_COMMENT"
            echo "$PATH_EXPORT"
            echo "$HOOK_SOURCE"
        } >> "$RC_FILE" || {
            echo -e "  ${RED}✗ Error:${NC} Failed to modify $RC_FILE"
            continue
        }
        echo -e "  ${GREEN}✓${NC} $RC_FILE ${DIM}(configured)${NC}"
    fi
done

# Print success message
echo -e "\n${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║${NC}            ${GREEN}${BOLD}✓ Installation completed successfully${NC}           ${GREEN}${BOLD}║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${BOLD}Installed locations:${NC}"
echo -e "  ${DIM}Base directory:${NC}   $INSTALL_DIR"
echo -e "  ${DIM}Node wrappers:${NC}    $NODE_WRAPPERS_DIR"
echo -e "  ${DIM}Ruby wrappers:${NC}    $RUBY_WRAPPERS_DIR"

echo -e "\n${BOLD}Next steps:${NC}"
echo -e "  ${CYAN}1.${NC} Restart your terminal ${DIM}(or run: source ${RC_FILES[0]})${NC}"
echo -e "  ${CYAN}2.${NC} Test with: ${CYAN}node --version${NC} or ${CYAN}ruby --version${NC}"

echo -e "\n${DIM}Tip: Your shell will now start faster! nvm/rbenv load only when needed.${NC}\n"
exit 0
