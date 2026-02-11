---
layout: default
title: Lifecycle
---

# Lifecycle — from install to steady state

## 1. Installation

`install.sh` performs these steps in order:

1. **Source configuration** — loads `scripts/config` which detects the user's shell and sets path variables (`INSTALL_DIR`, `RC_FILES[]`, wrapper directory paths).

2. **Create directory structure** — creates `~/.lazy-wrappers/scripts/bin/{node_wrappers,ruby_wrappers,commands}`.

3. **Copy scripts** — copies all files from `scripts/` (config, generate\_wrappers, nvmload, rbenvload, shell\_hook, wrappers.conf) to the install directory.

4. **Copy static wrappers** — copies the hand-crafted `nvm` and `rbenv` wrappers from the source tree.

5. **Copy commands** — copies `lw-benchmark`, `lw-recreate`, `lw-uninstall` to the commands directory.

6. **Generate dynamic wrappers** — runs `generate_wrappers` which reads `wrappers.conf` and creates a wrapper script for every listed binary except the static ones (`nvm`, `rbenv`).

7. **Make everything executable** — `chmod +x` on all wrappers, loaders, and the shell hook.

8. **Modify shell RC files** — appends three lines to the user's shell config (e.g., `~/.bashrc`, `~/.zshrc`):

```bash
# lazy-wrappers: Add wrapper scripts to PATH and load shell hook
[[ ":$PATH:" != *":.../node_wrappers:"* ]] && export PATH=".../node_wrappers:.../ruby_wrappers:.../commands:$PATH"
. ".../scripts/shell_hook"
```

Key details:
- The PATH guard prevents duplicate entries when RC files are re-sourced.
- Wrapper directories are prepended to PATH so they shadow real binaries.
- `shell_hook` is sourced to install the post-command cleanup function.

## 2. Shell startup (after installation)

When a new terminal opens:

1. Shell sources the RC file.
2. The lazy-wrappers PATH line adds wrapper dirs to the front of `$PATH`.
3. `shell_hook` is sourced:
   - Creates a per-session flags directory: `/tmp/lazy-wrappers-$$/` (or `$XDG_RUNTIME_DIR/lazy-wrappers-$$`)
   - Registers `__lazy_wrappers_cleanup` as a `precmd` hook (zsh) or prepends it to `PROMPT_COMMAND` (bash)
   - Sets an `EXIT` trap to clean up the flags directory

**Cost:** ~3–5 ms (PATH manipulation and hook registration only — no version manager loading).

## 3. First command invocation

When the user runs a wrapped command (e.g., `node --version`):

1. Shell resolves `node` to `~/.lazy-wrappers/scripts/bin/node_wrappers/node`.
2. The wrapper script starts in a subshell:
   - Sets a recursion guard env var (`__LAZY_WRAPPERS_LOADING_node=1`).
   - Strips the `node_wrappers/` directory from its own `$PATH`.
   - Runs `command -v node` — not found (nvm is not loaded yet).
   - Sources `nvmload`, which loads nvm (or clones it first if missing).
   - `nvmload` creates a flag file: `/tmp/lazy-wrappers-$$/nvm_loaded`.
   - Executes `exec node "$@"` — replaces itself with the real binary.
3. The real `node` runs and produces output.

## 4. Post-command hook

After the command finishes and before the next prompt renders:

1. `__lazy_wrappers_cleanup` runs (via `PROMPT_COMMAND` / `precmd`).
2. Checks: does `/tmp/lazy-wrappers-$$/nvm_loaded` exist **and** is `node_wrappers` still in PATH?
3. If yes:
   - Removes `node_wrappers/` from PATH (all occurrences).
   - Loads nvm into the **parent shell** (sources `nvm.sh` again, because the wrapper ran in a subshell that is now gone).
   - Sets `NVM_ALREADY_LOADED=1`.
4. Same check for rbenv.
5. Exports the cleaned PATH.

## 5. Subsequent commands

After the hook has run:

- PATH no longer contains wrapper directories.
- `node`, `npm`, etc. resolve directly to the real binaries.
- **Zero overhead** — no wrapper scripts in the path, no flag-file changes, no hook work.

## 6. Uninstallation

`lw-uninstall` reverses installation:

1. Cleans shell RC files — removes all lines referencing `lazy-wrappers`, the wrapper directories, or `shell_hook`.
2. Removes `~/.lazy-wrappers/`.
3. Requires a terminal restart to take effect.

## Visual summary

```
install.sh
    │
    ▼
Shell starts (3–5 ms)
    │
    ▼
User types "node"
    │
    ▼
Wrapper intercepts → loads nvm → exec real node → sets flag
    │
    ▼
shell_hook fires → removes wrappers from PATH → loads nvm into parent
    │
    ▼
All future calls go directly to real binaries (zero overhead)
```
