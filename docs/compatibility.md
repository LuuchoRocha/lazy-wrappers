---
layout: default
title: Compatibility
---

# Compatibility

Wrapper executables plus `PATH` changes—portable across Unix-like systems.

Compatibility also depends on the installer modifying the correct startup file(s) for your shell.

## Shells

Supported for automatic configuration: bash, zsh.

Other shells require manual configuration because the installer writes bash/zsh startup snippets, and the shell hook is bash/zsh-oriented.

For manual setups, verify:

- your `PATH` includes the wrapper directories first
- `which node` resolves to a wrapper before first use
- after the first load, wrapper paths are removed from `PATH`

## Prompt/config frameworks

Oh My Zsh, Starship, and plugin managers generally work fine if ordering is respected:

- lazy-wrappers `PATH` entries must be present before commands resolve
- traditional `nvm`/`rbenv` initialization should be disabled for startup savings

## Non-default manager locations

Set `NVM_DIR` and/or `RBENV_DIR` before installation, then verify the wrapper can locate them.
