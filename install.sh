#!/bin/bash
# Lazy-wrappers installer
# Installs wrapper scripts to defer loading of nvm and rbenv until needed

set -euo pipefail

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
    echo "Warning: git is not installed. It will be required if nvm or rbenv need to be cloned."
fi

# Copy the entire project to ~/.lazy-wrappers
echo "Installing lazy-wrappers to $INSTALL_DIR..."
if ! cp --recursive --dereference "$SCRIPT_SOURCE_DIR" "$INSTALL_DIR"; then
    echo "Error: Failed to copy files to $INSTALL_DIR"
    exit 1
fi

rm -rf "$INSTALL_DIR/.git" 2>/dev/null || true

# Generate all wrapper scripts from wrappers.conf
if [[ ! -f "$INSTALL_DIR/scripts/generate_wrappers.sh" ]]; then
    echo "Error: Wrapper generator script not found"
    exit 1
fi

chmod +x "$INSTALL_DIR/scripts/generate_wrappers.sh"
if ! "$INSTALL_DIR/scripts/generate_wrappers.sh"; then
    echo "Error: Failed to generate wrapper scripts"
    exit 1
fi

# Make wrapper scripts executable
if [[ -d "$NODE_WRAPPERS_DIR" ]] && [[ -n "$(ls -A "$NODE_WRAPPERS_DIR" 2>/dev/null)" ]]; then
    if ! chmod +x "$NODE_WRAPPERS_DIR"/* 2>/dev/null; then
        echo "Warning: Failed to make some node wrappers executable"
        echo "You may need to run: chmod +x $NODE_WRAPPERS_DIR/*"
    fi
fi

if [[ -d "$RUBY_WRAPPERS_DIR" ]] && [[ -n "$(ls -A "$RUBY_WRAPPERS_DIR" 2>/dev/null)" ]]; then
    if ! chmod +x "$RUBY_WRAPPERS_DIR"/* 2>/dev/null; then
        echo "Warning: Failed to make some ruby wrappers executable"
        echo "You may need to run: chmod +x $RUBY_WRAPPERS_DIR/*"
    fi
fi

for script in nvmload rbenvload shell_hook.sh; do
    if [[ -f "$INSTALL_DIR/scripts/$script" ]]; then
        chmod +x "$INSTALL_DIR/scripts/$script"
    fi
done

# The lines we'll add to RC files
PATH_COMMENT="# lazy-wrappers: Add wrapper scripts to PATH and load shell hook"
PATH_EXPORT="export PATH=\"$NODE_WRAPPERS_DIR:$RUBY_WRAPPERS_DIR:\$PATH\""
HOOK_SOURCE=". \"$INSTALL_DIR/scripts/shell_hook.sh\""

# Process each RC file to add PATH
for RC_FILE in "${RC_FILES[@]}"; do
    # Backup the shell configuration file if it exists
    if [[ -f "$RC_FILE" ]]; then
        RC_BACKUP="${RC_FILE}.backup-$(date +%Y%m%d%H%M%S)"
        if cp "$RC_FILE" "$RC_BACKUP"; then
            echo "Backup of $RC_FILE saved as $RC_BACKUP"
        else
            echo "Warning: Failed to create backup of $RC_FILE"
        fi
    else
        # Create the RC file if it doesn't exist
        if ! touch "$RC_FILE" 2>/dev/null; then
            echo "Warning: Cannot create $RC_FILE, skipping"
            continue
        fi
    fi

    # Check if already installed
    if [[ -f "$RC_FILE" ]] && grep -qF "lazy-wrappers" "$RC_FILE"; then
        echo "lazy-wrappers is already configured in $RC_FILE"
    else
        echo "Adding lazy-wrappers to $RC_FILE..."
        {
            echo ""
            echo "$PATH_COMMENT"
            echo "$PATH_EXPORT"
            echo "$HOOK_SOURCE"
        } >> "$RC_FILE" || {
            echo "Error: Failed to modify $RC_FILE"
            continue
        }
        echo "$RC_FILE modified"
    fi
done

# Print success message
echo ""
echo "Installation completed successfully."
echo ""
echo "Installed to: $INSTALL_DIR"
echo "Node wrappers (node, npm, npx, yarn, pnpm, nvm): $NODE_WRAPPERS_DIR"
echo "Ruby wrappers (ruby, gem, rbenv): $RUBY_WRAPPERS_DIR"
echo ""
echo "Modified configuration files:"
for RC_FILE in "${RC_FILES[@]}"; do
    echo "  - $RC_FILE"
done
echo ""
echo "To apply the changes, either:"
echo "  1. Log out and log back in (recommended for GUI apps)"
echo "  2. Run: source ${RC_FILES[0]}"
echo "  3. Or restart your terminal"
echo ""
echo "To check that everything works, you can use commands like:"
echo "  node --version"
echo "  ruby --version"
exit 0
