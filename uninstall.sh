#!/bin/bash

. ./scripts/config

# Remove installed files
echo "Removing installed files..."
rm -f "$ALIASES_DEST" "$RBENV_DEST" "$NVM_DEST" "$WRAPPERS_DEST"
echo "Files removed."

# Remove references from the shell configuration file
if [ -f "$RC_FILE" ]; then
    echo "🔍 Removing references from $RC_FILE (backup: ${RC_FILE}.bak)…"
    sed -i.bak \
      -e '\# Load custom nvm/rbenv aliases#d' \
      -e "\#[ -s \"$ALIASES_DEST\" ] && \. \"$ALIASES_DEST\"#d" \
      -e '\# Load custom nvm/rbenv wrappers#d' \
      -e "\#[ -s \"$WRAPPERS_DEST\" ] && \. \"$WRAPPERS_DEST\"#d" \
      "$RC_FILE"
    echo "✅ References removed. Backup: ${RC_FILE}.bak"
else
    echo "File $RC_FILE does not exist. No changes made."
fi

echo "Uninstallation completed successfully."
exit 0
