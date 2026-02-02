---
layout: default
title: Compatibility
---

# Compatibility

Wrapper executables plus `PATH` changes—portable across Unix-like systems.

Compatibility also depends on the installer modifying the correct startup file(s) for your shell.

## Shells

Supported: bash, zsh, fish, ksh, tcsh, csh, dash, sh.

Primarily tested on bash and zsh. Other shells should work if they honor `PATH` set early in the session.

For less common shells, verify:

- your `PATH` includes the wrapper directories first
- `which node` resolves to a wrapper before first use
- after the first load, wrapper paths are removed from `PATH`

## Prompt/config frameworks

Oh My Zsh, Starship, and plugin managers generally work fine if ordering is respected:

- lazy-wrappers `PATH` entries must be present before commands resolve
- traditional `nvm`/`rbenv` initialization should be disabled for startup savings

## Non-default manager locations

Set `NVM_DIR` and/or `RBENV_DIR` before installation, then verify the wrapper can locate them.
