---
layout: default
title: shell-hook
---

# shell-hook

> Source: `scripts/shell-hook`

## The problem it solves

Wrappers run in subshells. When `node_wrappers/node` sources nvm and execs the real node, all of that happens in a child process. After it exits, the parent shell still has no nvm loaded and the wrapper directories are still in PATH.

Without the hook, every subsequent `node` call would go through the wrapper again.

The shell hook:

1. Detects that a version manager was loaded (via flag files)
2. Removes the wrapper directories from the parent shell's PATH
3. Loads the version manager into the parent shell
4. Ensures all future commands bypass wrappers entirely

## Initialization (runs once at shell startup)

```bash
# Per-session flags directory (PID-scoped)
_LW_FLAGS_DIR="${XDG_RUNTIME_DIR:-/tmp}/lazy-wrappers-$$"

mkdir -p "$_LW_FLAGS_DIR" 2>/dev/null
trap 'rm -rf "$_LW_FLAGS_DIR" 2>/dev/null' EXIT
export _LW_FLAGS_DIR
```

### Why PID-scoped flags?

`$$` is the parent shell's PID. This ensures:

- Each terminal session has its own flags directory.
- Multiple terminals do not interfere with each other.
- Flag files created by wrapper subshells land in the correct parent's directory (child processes inherit `$_LW_FLAGS_DIR`).

### XDG_RUNTIME_DIR fallback

Uses `$XDG_RUNTIME_DIR` (typically `/run/user/1000/`) when available — a tmpfs mount, making flag-file I/O essentially free. Falls back to `/tmp` otherwise.

## Hook registration

```bash
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd __lazy_wrappers_cleanup
elif [[ -n "$BASH_VERSION" ]]; then
    if [[ "$PROMPT_COMMAND" != *"__lazy_wrappers_cleanup"* ]]; then
        PROMPT_COMMAND="__lazy_wrappers_cleanup${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
    fi
fi
```

| Shell | Mechanism                        | When it fires      |
| ----- | -------------------------------- | ------------------ |
| zsh   | `precmd` hook via `add-zsh-hook` | Before each prompt |
| bash  | `PROMPT_COMMAND`                 | Before each prompt |

Notes on the bash registration:

- Checks if already registered (prevents duplicates from re-sourcing).
- **Prepends** to ensure cleanup runs before other prompt commands.
- `${PROMPT_COMMAND:+; $PROMPT_COMMAND}` handles an empty or unset PROMPT_COMMAND gracefully.

## The cleanup function

```bash
__lazy_wrappers_cleanup() {
    if [[ -f "$_LW_FLAGS_DIR/nvm_loaded" \
       && "$PATH" == *"node_wrappers"* ]]; then
        # Remove node_wrappers from PATH (while loop for duplicates)
        PATH=":$PATH:"
        while [[ "$PATH" == *":$_LW_NODE_DIR:"* ]]; do
            PATH="${PATH//:$_LW_NODE_DIR:/:}"
        done
        PATH="${PATH#:}"; PATH="${PATH%:}"
        # Load nvm into THIS (parent) shell
        if [[ -z "${NVM_ALREADY_LOADED:-}" ]]; then
            __lazy_wrappers_load_nvm_into_parent_shell
        fi
        export PATH
    fi
    # Same logic for rbenv...
}
```

### Two-condition guard

Both conditions must be true:

1. **Flag file exists** — a wrapper actually loaded the manager in this session.
2. **Wrapper dir still in PATH** — cleanup has not already happened.

This means:

- If the manager was never used → no work done (fast path).
- If cleanup already ran → no work done (idempotent).
- Only on the first prompt after the first wrapped command → actual cleanup.

### Why re-load into the parent shell?

The wrapper's `exec` replaces the wrapper process with the real binary. The nvm that was loaded inside the wrapper subshell is gone. The parent shell needs its own `nvm` function and PATH modifications from `nvm use`.

`__lazy_wrappers_load_nvm_into_parent_shell` sources `nvm.sh` in the parent shell's context, where it persists for the rest of the session.

## Parent shell loaders

### nvm

```bash
__lazy_wrappers_load_nvm_into_parent_shell() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [[ ! -s "$NVM_DIR/nvm.sh" ]] && return 0
    . "$NVM_DIR/nvm.sh"
    # zsh completion compatibility
    if [[ -s "$NVM_DIR/bash_completion" ]]; then
        if [[ -n "${ZSH_VERSION:-}" ]] && ! type complete >/dev/null 2>&1; then
            autoload -Uz bashcompinit 2>/dev/null || true
            bashcompinit 2>/dev/null || true
        fi
        type complete >/dev/null 2>&1 && . "$NVM_DIR/bash_completion"
    fi
    export NVM_ALREADY_LOADED=1
}
```

### rbenv

```bash
__lazy_wrappers_load_rbenv_into_parent_shell() {
    export RBENV_DIR="${RBENV_DIR:-$HOME/.rbenv}"
    [[ ! -x "$RBENV_DIR/bin/rbenv" ]] && return 0
    # Shell-aware init
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        eval "$("$RBENV_DIR/bin/rbenv" init - zsh)"
        # fpath + completion setup...
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        eval "$("$RBENV_DIR/bin/rbenv" init - bash)"
    fi
    export RBENV_ALREADY_LOADED=1
}
```

## Performance characteristics

| Scenario                              | Cost                                          |
| ------------------------------------- | --------------------------------------------- |
| No wrapper invoked yet                | ~0 ms (two `-f` checks on non-existent files) |
| After a manager loaded, first cleanup | ~200–400 ms (sources nvm.sh / rbenv init)     |
| After cleanup already ran             | ~0 ms (PATH check fast-fails)                 |
| Steady state                          | ~0 ms (flag exists but PATH check fails)      |

The cleanup cost is one-time per session and happens between command completion and prompt display, so it is barely perceptible.

## IPC flow: wrapper → flag file → hook

```
Wrapper (subshell)                   Parent Shell
──────────────────                   ────────────
1. source nvmload
2. nvmload touches flag file ──────▶ /tmp/lazy-wrappers-$$/nvm_loaded
3. exec real binary
4. process exits
                                     5. PROMPT_COMMAND fires
                                     6. __lazy_wrappers_cleanup reads flag
                                     7. removes wrapper dir from PATH
                                     8. sources nvm.sh into parent
                                     9. sets NVM_ALREADY_LOADED=1
```

The exported `$_LW_FLAGS_DIR` is how the child process knows where to write the flag — it inherits this variable from the parent shell where `shell-hook` set it up.

## Cleanup on exit

```bash
trap 'rm -rf "$_LW_FLAGS_DIR" 2>/dev/null' EXIT
```

When the session ends, the flags directory is removed. This prevents stale flags from accumulating in `/tmp`.
