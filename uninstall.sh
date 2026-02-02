#!/bin/bash
# Lazy-wrappers uninstaller
# Removes wrapper scripts and configuration from shell RC files

set -euo pipefail

SCRIPT_SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source configuration file
if [[ ! -f "$SCRIPT_SOURCE_DIR/scripts/config" ]]; then
    echo "Error: Configuration file not found at $SCRIPT_SOURCE_DIR/scripts/config"
    exit 1
fi

# shellcheck source=scripts/config
. "$SCRIPT_SOURCE_DIR/scripts/config"

# Remove PATH reference from all shell configuration files
for RC_FILE in "${RC_FILES[@]}"; do
    if [[ -f "$RC_FILE" ]]; then
        echo "Removing lazy-wrappers from $RC_FILE..."
        if cp "$RC_FILE" "${RC_FILE}.bak"; then
            # Use portable sed syntax (works on both GNU and BSD/macOS sed)
            # Create temporary file and move it back to preserve permissions
            sed \
              -e '\#lazy-wrappers:#d' \
              -e "\#$NODE_WRAPPERS_DIR#d" \
              -e "\#$RUBY_WRAPPERS_DIR#d" \
              -e '\#shell_hook.sh#d' \
              "$RC_FILE" > "${RC_FILE}.tmp" && mv "${RC_FILE}.tmp" "$RC_FILE" || {
                echo "Error: Failed to modify $RC_FILE"
                echo "Backup available at ${RC_FILE}.bak"
                rm -f "${RC_FILE}.tmp"
                continue
              }
            # Remove any empty lines left at the end
            sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$RC_FILE" > "${RC_FILE}.tmp" && mv "${RC_FILE}.tmp" "$RC_FILE"
            echo "  Done. Backup: ${RC_FILE}.bak"
        else
            echo "Warning: Failed to create backup of $RC_FILE, skipping"
        fi
    else
        echo "File $RC_FILE does not exist. No changes made."
    fi
done

# Ask about removing the installation directory
echo ""
if [[ -d "$INSTALL_DIR" ]]; then
    read -p "Remove $INSTALL_DIR? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if rm -rf "$INSTALL_DIR"; then
            echo "Removed $INSTALL_DIR"
        else
            echo "Error: Failed to remove $INSTALL_DIR"
            exit 1
        fi
    else
        echo "Kept $INSTALL_DIR"
    fi
else
    echo "$INSTALL_DIR does not exist, nothing to remove"
fi

echo ""
echo "Uninstallation completed."
echo "Please restart your terminal or run: source ${RC_FILES[0]}"
exit 0
