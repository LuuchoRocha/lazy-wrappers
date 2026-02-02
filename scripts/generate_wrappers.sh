#!/bin/bash
# Generate all wrapper scripts from wrappers.conf
# This script reads the configuration file and creates wrapper scripts
# for each binary that should be lazy-loaded

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/wrappers.conf"
NODE_WRAPPERS_DIR="$SCRIPT_DIR/bin/node_wrappers"
RUBY_WRAPPERS_DIR="$SCRIPT_DIR/bin/ruby_wrappers"

# Validate configuration file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file $CONFIG_FILE not found"
    exit 1
fi

# Ensure wrapper directories exist
if ! mkdir -p "$NODE_WRAPPERS_DIR" "$RUBY_WRAPPERS_DIR"; then
    echo "Error: Failed to create wrapper directories"
    exit 1
fi

# Template for nvm-based wrappers (Node.js/npm)
# Creates a wrapper script that:
# 1. Checks if nvm is already loaded (fast path)
# 2. Removes wrapper directory from PATH to prevent recursion
# 3. Loads nvm if the binary is not found
# 4. Executes the real binary
generate_nvm_wrapper() {
    local binary_name="$1"
    local wrapper_path="$NODE_WRAPPERS_DIR/$binary_name"
    
    # Validate binary name
    if [[ -z "$binary_name" ]]; then
        echo "Error: Binary name cannot be empty"
        return 1
    fi
    
    # Use single quotes for heredoc to prevent expansion, then sed for replacements
    cat > "$wrapper_path" << 'WRAPPER_EOF'
#!/bin/bash
# Lazy wrapper for __BINARY__

# Prevent infinite recursion
if [[ -n "${__LAZY_WRAPPERS_LOADING___BINARY__:-}" ]]; then
    echo "Error: wrapper recursion detected for __BINARY__" >&2
    exit 1
fi
export __LAZY_WRAPPERS_LOADING___BINARY__=1

# Remove wrapper directory from PATH FIRST to prevent recursion
WRAPPER_DIR="__NODE_WRAPPERS__"
PATH=":$PATH:"
PATH="${PATH//:$WRAPPER_DIR:/:}"
PATH="${PATH#:}"
PATH="${PATH%:}"
export PATH

# Load nvm if binary not found in PATH
if ! command -v __BINARY__ &>/dev/null; then
    . "__SCRIPTS__/nvmload" 2>/dev/null || true
fi

# Find and exec the real binary
if command -v __BINARY__ &>/dev/null; then
    exec __BINARY__ "$@"
else
    echo "Error: __BINARY__ not found. Is __BINARY__ installed?" >&2
    exit 1
fi
WRAPPER_EOF

    # Replace placeholders (cross-platform sed without -i)
    sed -e "s|__BINARY__|$binary_name|g" \
        -e "s|__NODE_WRAPPERS__|$NODE_WRAPPERS_DIR|g" \
        -e "s|__SCRIPTS__|$SCRIPT_DIR|g" \
        "$wrapper_path" > "$wrapper_path.tmp" && mv "$wrapper_path.tmp" "$wrapper_path"
    
    if ! chmod +x "$wrapper_path"; then
        echo "Warning: Failed to make $wrapper_path executable"
        return 1
    fi
}

# Template for rbenv-based wrappers (Ruby/gems)
# Creates a wrapper script that:
# 1. Checks if rbenv is already loaded (fast path)
# 2. Removes wrapper directory from PATH to prevent recursion
# 3. Loads rbenv if the binary is not found
# 4. Executes the real binary
generate_rbenv_wrapper() {
    local binary_name="$1"
    local wrapper_path="$RUBY_WRAPPERS_DIR/$binary_name"
    
    # Validate binary name
    if [[ -z "$binary_name" ]]; then
        echo "Error: Binary name cannot be empty"
        return 1
    fi
    
    cat > "$wrapper_path" << 'WRAPPER_EOF'
#!/bin/bash
# Lazy wrapper for __BINARY__

# Prevent infinite recursion
if [[ -n "${__LAZY_WRAPPERS_LOADING___BINARY__:-}" ]]; then
    echo "Error: wrapper recursion detected for __BINARY__" >&2
    exit 1
fi
export __LAZY_WRAPPERS_LOADING___BINARY__=1

# Remove wrapper directory from PATH FIRST to prevent recursion
WRAPPER_DIR="__RUBY_WRAPPERS__"
PATH=":$PATH:"
PATH="${PATH//:$WRAPPER_DIR:/:}"
PATH="${PATH#:}"
PATH="${PATH%:}"
export PATH

# Load rbenv if binary not found in PATH
if ! command -v __BINARY__ &>/dev/null; then
    . "__SCRIPTS__/rbenvload" 2>/dev/null || true
fi

# Find and exec the real binary
if command -v __BINARY__ &>/dev/null; then
    exec __BINARY__ "$@"
else
    echo "Error: __BINARY__ not found. Is rbenv/ruby installed?" >&2
    exit 1
fi
WRAPPER_EOF

    # Replace placeholders (cross-platform sed without -i)
    sed -e "s|__BINARY__|$binary_name|g" \
        -e "s|__RUBY_WRAPPERS__|$RUBY_WRAPPERS_DIR|g" \
        -e "s|__SCRIPTS__|$SCRIPT_DIR|g" \
        "$wrapper_path" > "$wrapper_path.tmp" && mv "$wrapper_path.tmp" "$wrapper_path"
    
    if ! chmod +x "$wrapper_path"; then
        echo "Warning: Failed to make $wrapper_path executable"
        return 1
    fi
}

# Static wrappers that should not be overwritten by generation
# nvm is a shell function, rbenv needs special init handling
STATIC_WRAPPERS=("nvm" "rbenv")

is_static_wrapper() {
    local name="$1"
    for static in "${STATIC_WRAPPERS[@]}"; do
        [[ "$name" == "$static" ]] && return 0
    done
    return 1
}

# Main logic - reads wrappers.conf and generates all wrapper scripts
generate_all_wrappers() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: Config file $CONFIG_FILE not found"
        exit 1
    fi
    
    # Ensure static wrappers are executable
    for wrapper in "$NODE_WRAPPERS_DIR/nvm" "$RUBY_WRAPPERS_DIR/rbenv"; do
        if [[ -f "$wrapper" ]]; then
            chmod +x "$wrapper" 2>/dev/null || true
        fi
    done
    
    # Check if config file has any valid entries
    local has_valid_entries=false
    while IFS=: read -r binary_name loader || [[ -n "$binary_name" ]]; do
        # Skip empty lines and comments
        [[ -z "$binary_name" || "$binary_name" =~ ^[[:space:]]*# ]] && continue
        has_valid_entries=true
        break
    done < "$CONFIG_FILE"
    
    if [[ "$has_valid_entries" == "false" ]]; then
        echo "Error: No valid entries found in $CONFIG_FILE"
        echo "Expected format: binary_name:loader (e.g., node:nvm or ruby:rbenv)"
        exit 1
    fi

    echo "Generating wrappers from $CONFIG_FILE..."
    
    local node_count=0
    local ruby_count=0
    local error_count=0
    
    while IFS=: read -r binary_name loader || [[ -n "$binary_name" ]]; do
        # Skip empty lines and comments
        [[ -z "$binary_name" || "$binary_name" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace
        binary_name=$(echo "$binary_name" | xargs)
        loader=$(echo "$loader" | xargs)
        
        # Validate loader type
        case "$loader" in
            nvm)
                if generate_nvm_wrapper "$binary_name"; then
                    ((node_count++)) || true
                else
                    ((error_count++)) || true
                fi
                ;;
            rbenv)
                if generate_rbenv_wrapper "$binary_name"; then
                    ((ruby_count++)) || true
                else
                    ((error_count++)) || true
                fi
                ;;
            *)
                echo "  Warning: Unknown loader '$loader' for $binary_name, skipping"
                ((error_count++)) || true
                ;;
        esac
    done < "$CONFIG_FILE"
    
    echo "Generated $node_count Node.js wrappers and $ruby_count Ruby wrappers"
    
    if [[ $error_count -gt 0 ]]; then
        echo "Warning: $error_count wrapper(s) failed to generate"
    fi
    
    # Exit with error if no wrappers were generated
    if [[ $node_count -eq 0 && $ruby_count -eq 0 ]]; then
        echo "Error: No wrappers were generated"
        echo "Check that $CONFIG_FILE contains valid entries in the format: binary_name:loader"
        echo "Example: node:nvm or ruby:rbenv"
        exit 1
    fi
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_all_wrappers
fi
