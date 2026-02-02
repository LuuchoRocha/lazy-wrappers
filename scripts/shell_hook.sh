#!/bin/bash
# Shell hook for lazy-wrappers
# This runs after each command and removes wrapper directories from PATH
# once the corresponding version manager has been loaded, replacing them
# with the actual version manager paths

# Use flag files to track which version managers have been loaded
__LAZY_WRAPPERS_FLAGS_DIR="${XDG_RUNTIME_DIR:-/tmp}/lazy-wrappers-$$"

__lazy_wrappers_cleanup() {
    # Remove node_wrappers from PATH and add nvm paths if flag exists
    if [[ -f "$__LAZY_WRAPPERS_FLAGS_DIR/nvm_loaded" && "$PATH" == *"node_wrappers"* ]]; then
        PATH="${PATH//$HOME\/.lazy-wrappers\/scripts\/bin\/node_wrappers:/}"
        PATH="${PATH//:$HOME\/.lazy-wrappers\/scripts\/bin\/node_wrappers/}"
        # Load nvm into this shell if not already loaded
        if [[ -z "$NVM_ALREADY_LOADED" ]]; then
            export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
            [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
            export NVM_ALREADY_LOADED=1
        fi
        export PATH
    fi
    
    # Remove ruby_wrappers from PATH and add rbenv paths if flag exists
    if [[ -f "$__LAZY_WRAPPERS_FLAGS_DIR/rbenv_loaded" && "$PATH" == *"ruby_wrappers"* ]]; then
        PATH="${PATH//$HOME\/.lazy-wrappers\/scripts\/bin\/ruby_wrappers:/}"
        PATH="${PATH//:$HOME\/.lazy-wrappers\/scripts\/bin\/ruby_wrappers/}"
        # Load rbenv into this shell if not already loaded
        if [[ -z "$RBENV_ALREADY_LOADED" ]]; then
            export RBENV_DIR="${RBENV_DIR:-$HOME/.rbenv}"
            if [[ -x "$RBENV_DIR/bin/rbenv" ]]; then
                eval "$("$RBENV_DIR/bin/rbenv" init - "${ZSH_VERSION:+zsh}" "${BASH_VERSION:+bash}")"
                export RBENV_ALREADY_LOADED=1
            fi
        fi
        export PATH
    fi
}

# Create the flags directory for this shell session
mkdir -p "$__LAZY_WRAPPERS_FLAGS_DIR" 2>/dev/null

# Clean up flags directory on shell exit
trap 'rm -rf "$__LAZY_WRAPPERS_FLAGS_DIR" 2>/dev/null' EXIT

# Install the hook based on shell type
if [[ -n "$ZSH_VERSION" ]]; then
    # Zsh: use precmd hook
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd __lazy_wrappers_cleanup
elif [[ -n "$BASH_VERSION" ]]; then
    # Bash: use PROMPT_COMMAND
    if [[ "$PROMPT_COMMAND" != *"__lazy_wrappers_cleanup"* ]]; then
        PROMPT_COMMAND="__lazy_wrappers_cleanup${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
    fi
fi

# Export the flags dir so wrappers can use it
export __LAZY_WRAPPERS_FLAGS_DIR
