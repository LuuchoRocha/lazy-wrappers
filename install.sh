#!/bin/bash

. ./scripts/config

# Check if required files exist before proceeding
for file in "$SCRIPT_DIR/nvmload" "$SCRIPT_DIR/rbenvload" "$SCRIPT_DIR/aliases" "$SCRIPT_DIR/wrappers"; do
    if [ ! -f "$file" ]; then
        echo "Error: File $file does not exist."
        exit 1
    fi
done

# Install files with proper permissions
install -m 755 -D "$SCRIPT_DIR/nvmload" "$NVM_DEST"
install -m 755 -D "$SCRIPT_DIR/rbenvload" "$RBENV_DEST"

# Backup the shell configuration file
RC_BACKUP="${RC_FILE}.backup-$(date +%Y%m%d%H%M%S)"
if [ -f "$RC_FILE" ]; then
    cp "$RC_FILE" "$RC_BACKUP"
    echo "Backup of $RC_FILE saved as $RC_BACKUP"
else
    echo "File $RC_FILE does not exist. A new one will be created."
fi

# Ask the user for their preference: aliases or wrappers
echo "How would you like to configure the commands? (1 for aliases, 2 for wrappers)"
read -r USER_CHOICE

if [ "$USER_CHOICE" -eq 1 ]; then
    # Install aliases file
    install -m 755 -D "$SCRIPT_DIR/aliases" "$ALIASES_DEST"
    
    # Add reference to aliases file if not already present
    if [ -f "$RC_FILE" ]; then
        if ! grep -qF ". \"$ALIASES_DEST\"" "$RC_FILE"; then
            echo "Adding reference to $ALIASES_DEST in $RC_FILE..."
            {
                echo ""
                echo "# Load custom nvm/rbenv aliases"
                echo "[ -s \"$ALIASES_DEST\" ] && . \"$ALIASES_DEST\""
            } >> "$RC_FILE"
            echo "$RC_FILE modified"
        else
            echo "$ALIASES_DEST is already referenced in $RC_FILE"
        fi
    else
        echo "File $RC_FILE does not exist. Creating a new one..."
        {
            echo "# Load custom nvm/rbenv aliases"
            echo "[ -s \"$ALIASES_DEST\" ] && . \"$ALIASES_DEST\""
        } > "$RC_FILE"
        echo "$RC_FILE created"
    fi
    echo "Setup completed using aliases."
elif [ "$USER_CHOICE" -eq 2 ]; then
    # Install wrappers file
    install -m 755 -D "$SCRIPT_DIR/wrappers" "$WRAPPERS_DEST"
    
    # Add reference to wrappers file if not already present
    if [ -f "$RC_FILE" ]; then
        if ! grep -qF ". \"$WRAPPERS_DEST\"" "$RC_FILE"; then
            echo "Adding reference to $WRAPPERS_DEST in $RC_FILE..."
            {
                echo ""
                echo "# Load custom nvm/rbenv wrappers"
                echo "[ -s \"$WRAPPERS_DEST\" ] && . \"$WRAPPERS_DEST\""
            } >> "$RC_FILE"
            echo "$RC_FILE modified"
        else
            echo "$WRAPPERS_DEST is already referenced in $RC_FILE"
        fi
    else
        echo "File $RC_FILE does not exist. Creating a new one..."
        {
            echo "# Load custom nvm/rbenv wrappers"
            echo "[ -s \"$WRAPPERS_DEST\" ] && . \"$WRAPPERS_DEST\""
        } > "$RC_FILE"
        echo "$RC_FILE created"
    fi
    echo "Setup completed using wrappers."
else
    echo "Invalid option. Please run the script again and choose 1 or 2."
    exit 1
fi

. $RC_FILE &> /dev/null

# Print success message
echo "Installation completed successfully."
# Print instructions for the user
echo "To apply the changes, run:"
echo "source $RC_FILE"
echo "or restart your terminal."
echo "To check that everything works, you can use the 'nvm' and 'rbenv' commands."
exit 0
