#!/bin/bash

. ./scripts/config

# Remove installed wrapper scripts
echo "Removing installed wrapper scripts from $BIN_DEST..."
for wrapper in rbenv nvm ruby gem node npm npx yarn pnpm; do
    if [ -f "$BIN_DEST/$wrapper" ]; then
        rm -f "$BIN_DEST/$wrapper"
        echo "  Removed: $wrapper"
    fi
done

# Remove loader files
echo "Removing loader files..."
rm -f "$RBENV_DEST" "$NVM_DEST"
echo "Loader files removed."

# Remove PATH reference from the shell configuration file
if [ -f "$RC_FILE" ]; then
    echo "🔍 Removing PATH reference from $RC_FILE (backup: ${RC_FILE}.bak)…"
    sed -i.bak \
      -e '\# Add local bin directory to PATH for lazy wrappers#d' \
      -e '\#export PATH="\$HOME/.local/bin:\$PATH"#d' \
      "$RC_FILE"
    echo "✅ References removed. Backup: ${RC_FILE}.bak"
else
    echo "File $RC_FILE does not exist. No changes made."
fi

echo ""
echo "Uninstallation completed successfully."
echo "Note: $BIN_DEST directory was not removed in case you have other scripts there."
exit 0
