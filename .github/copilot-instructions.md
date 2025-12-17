# LazyWrappers - AI Agent Instructions

## Project Overview

LazyWrappers is a shell script-based lazy loader system for `nvm` and `rbenv`. It speeds up shell startup by deferring version manager initialization until tools are actually invoked.

**Core Architecture**: Wrapper → Loader → Version Manager

1. **Wrapper scripts** (`scripts/bin/*`): Lightweight executables installed to `~/.local/bin` that intercept commands
2. **Loader scripts** (`scripts/nvmload`, `scripts/rbenvload`): Initialize version managers on-demand and auto-install if missing
3. **Installation system** (`install.sh`, `uninstall.sh`, `scripts/config`): Manages deployment to user environment

## Critical Patterns

### Wrapper Script Pattern
All wrappers in `scripts/bin/` follow this exact structure:
```bash
#!/bin/bash
# Remove wrapper directory from PATH to prevent recursion
WRAPPER_DIR="$(dirname "$(readlink -f "$0")")"
export PATH="${PATH//$WRAPPER_DIR:/}"

# Load the appropriate version manager (nvmload or rbenvload)
. "$WRAPPER_DIR/nvmload" &> /dev/null  # or rbenvload for Ruby tools

# Execute the real command (now found in PATH after loader initialized it)
exec <command> "$@"
```
- **Critical**: Must remove wrapper directory from PATH before calling the real command to prevent infinite recursion
- Use `readlink -f` to resolve symlinks and find loader script
- Suppress loader output with `&> /dev/null` for clean UX
- Use `exec` to replace the wrapper process with the real command

### Loader Script Idempotency
`scripts/nvmload` and `scripts/rbenvload` use environment flags (`NVM_ALREADY_LOADED`, `RBENV_ALREADY_LOADED`) to prevent duplicate initialization. Never remove these guards.

### Shell Configuration Detection
`scripts/config` auto-detects shell type via `basename "$SHELL"` and sets appropriate RC file. Supports bash, zsh, fish, ksh, tcsh, csh, dash, sh.

## Key Design Decisions

- **No background processes**: Wrappers are executable files, not shell functions, to work with shebangs (`#!/usr/bin/env node`)
- **PATH-based interception**: `~/.local/bin` must come before system paths to intercept tool calls
- **Auto-installation**: Loaders clone `nvm`/`rbenv` from GitHub if missing, enabling zero-config setup
- **Fail-safe sourcing**: Loaders use `return 1 2>/dev/null || exit 1` to work in both sourced and executed contexts

## Development Workflows

### Testing Installation
```bash
./install.sh
source ~/.zshrc  # or ~/.bashrc
node --version   # Should lazy-load nvm on first call
```

### Adding New Wrapper
1. Create `scripts/bin/<tool>` following the wrapper pattern
2. Determine if it needs `nvmload` (Node tools) or `rbenvload` (Ruby tools)
3. Update install/uninstall scripts to include the new wrapper name
4. Test with `./install.sh` and verify lazy loading works

### Shell-Specific Testing
Test across multiple shells since wrapper logic differs slightly:
- Zsh: Uses `eval "$(rbenv init - zsh)"`
- Bash: Uses `eval "$(rbenv init - bash)"`

## Common Pitfalls

- **PATH recursion**: Wrappers call themselves infinitely if `WRAPPER_DIR` isn't removed from PATH before executing the real command
- **Don't use relative paths** in wrappers - must use `readlink -f "$0"` for symlink resolution
- **Preserve `set -euo pipefail`** in config script for strict error handling during installation
- **Backup RC files** before modification - `install.sh` creates timestamped backups
- **Handle missing git gracefully** - loaders check for git before cloning
- **Don't source RC files in install.sh** - can cause exit due to `set -e` when RC contains non-zero exits

## File Structure Logic

- `scripts/config`: Shared configuration sourced by install/uninstall
- `scripts/bin/`: All wrapper executables (installed to `~/.local/bin`)
- `scripts/nvmload`, `scripts/rbenvload`: Installed to `~/.local/bin/` as companions to wrappers
- Root-level `install.sh`/`uninstall.sh`: User-facing entry points (run from project root)

When modifying installation paths, update both `BIN_DEST` in `scripts/config` and the wrapper path resolution logic.
