#!/bin/bash

. ./scripts/config

# Check if required files exist before proceeding
for file in "$SCRIPT_DIR/nvmload" "$SCRIPT_DIR/rbenvload"; do
    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist."
        exit 1
    fi
done

# Check if bin directory and wrapper scripts exist
if [ ! -d "$SCRIPT_DIR/bin" ]; then
    echo "Error: Directory $SCRIPT_DIR/bin does not exist."
    exit 1
fi

# Install loader files with proper permissions
install -m 755 -D "$SCRIPT_DIR/nvmload" "$NVM_DEST"
install -m 755 -D "$SCRIPT_DIR/rbenvload" "$RBENV_DEST"

# Install wrapper scripts to ~/.local/bin
echo "Installing wrapper scripts to $BIN_DEST..."
for script in "$SCRIPT_DIR/bin"/*; do
    if [ -f "$script" ]; then
        install -m 755 -D "$script" "$BIN_DEST/$(basename "$script")"
        echo "  Installed: $(basename "$script")"
    fi
done

# Backup the shell configuration file
RC_BACKUP="${RC_FILE}.backup-$(date +%Y%m%d%H%M%S)"
if [ -f "$RC_FILE" ]; then
    cp "$RC_FILE" "$RC_BACKUP"
    echo "Backup of $RC_FILE saved as $RC_BACKUP"
else
    echo "File $RC_FILE does not exist. A new one will be created."
fi

# Add ~/.local/bin to PATH if not already present
if [ -f "$RC_FILE" ]; then
    if ! grep -qF "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$RC_FILE"; then
        echo "Adding $BIN_DEST to PATH in $RC_FILE..."
        {
            echo ""
            echo "# Add local bin directory to PATH for lazy wrappers"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
        } >> "$RC_FILE"
        echo "$RC_FILE modified"
    else
        echo "$BIN_DEST is already in PATH in $RC_FILE"
    fi
else
    echo "File $RC_FILE does not exist. Creating a new one..."
    {
        echo "# Add local bin directory to PATH for lazy wrappers"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    } > "$RC_FILE"
    echo "$RC_FILE created"
fi

. $RC_FILE &> /dev/null

# Print success message
echo "Installation completed successfully."
echo ""
echo "Installed wrapper scripts: rbenv, nvm, ruby, gem, node, npm, npx, yarn, pnpm"
echo ""
echo "To apply the changes, run:"
echo "  source $RC_FILE"
echo "or restart your terminal."
echo ""
echo "To check that everything works, you can use commands like:"
echo "  node --version"
echo "  ruby --version"
exit 0
