---
layout: default
title: Gotchas
---

# Gotchas and troubleshooting

Common pitfalls, tricky behaviors, and debugging tips for contributors.

## The subshell / parent shell gap

This is the most important thing to understand.

When a wrapper runs `exec node "$@"`, the wrapper process is replaced by the real node. Everything that happened in that process—sourcing nvm, modifying PATH—is gone once node exits. The parent (interactive) shell never saw any of it.

This is why `shell-hook` exists. It re-loads the version manager into the parent shell after the wrapped command finishes. Without it, every wrapped command would go through the wrapper again.

**If something feels broken, check whether the hook is running.** Common symptoms:

- `nvm` works from a wrapper call but `nvm use 18` later says "nvm not found."
- Running `node` always takes 200 ms instead of being instant after the first call.

Debug: run `echo $PROMPT_COMMAND` (bash) or `print -l ${precmd_functions}` (zsh) to check the hook is registered.

## Flag file race window

There is a brief window between a wrapper creating a flag file and the hook running. If the user runs two commands rapidly (e.g., `node -v && npm -v` in a one-liner), both wrappers will run before the hook fires. This is fine because:

- Both wrappers independently remove the wrapper directory from their own PATH and source nvmload.
- nvmload's `NVM_ALREADY_LOADED` guard means the second invocation of `node -v` (after `npm -v` via `&&`) may source nvm again in its own subshell, but it's harmless.
- The hook will clean up the parent shell on the next prompt regardless.

## Duplicate entries in wrappers.conf

The current conf has duplicates (`prettier`, `eslint`, `rubocop`). These are harmless — `generate_wrappers` writes to the same file path twice, so the second write simply overwrites the first. But they make maintenance confusing.

## PATH manipulation fragility

The colon-padding technique (`PATH=":$PATH:"`) is robust but unfamiliar to many shell developers. A few things to keep in mind:

- The approach handles directories at any position (start, middle, end).
- It handles multiple occurrences via the while loop.
- It does **not** handle directories that are substrings of other PATH entries. For example, if PATH has `/foo/bar` and you try to remove `/foo`, the current logic would not match because it requires colon boundaries. This is correct and safe.
- The `${PATH#:}` and `${PATH%:}` at the end are essential. Without them, PATH would have a leading or trailing colon, which bash interprets as the current directory (`.`).

## nvm is a function, not a binary

This trips up many people. `nvm` is defined by sourcing `nvm.sh`. It lives in shell memory. You cannot:

- `exec nvm` — there is no nvm executable.
- `which nvm` — it is not in PATH.
- Call it from a subprocess that has not sourced `nvm.sh`.

This is why the `nvm` wrapper calls `nvm "$@"` (function call) instead of `exec nvm "$@"`.

Use `declare -f nvm` (not `command -v`) to check if it exists.

## rbenv init creates a shell function too

After `eval "$(rbenv init - bash)"`, rbenv creates a shell function that wraps the real `rbenv` binary. This function intercepts commands like `rbenv shell` that need to modify the current shell environment. The static rbenv wrapper must ensure init runs before delegating.

## `return` vs `exit` in loaders

The loaders (nvmload, rbenvload) use `return 0 2>/dev/null || exit 0` because they can be:

- **Sourced** (from a wrapper via `. nvmload`) → `return` works, `exit` would kill the calling script.
- **Executed** (directly, for testing) → `return` fails with an error, `exit` works.

The `2>/dev/null` hides the "return: can only return from a function" error in the execution case.

## Stale flag files

Flag files live in `/tmp/lazy-wrappers-$$` and are cleaned up by the EXIT trap. If the shell crashes (SIGKILL) or the trap does not fire, stale directories may remain. These are harmless — they use the dead PID, so no new shell session will pick them up. `/tmp` is typically cleaned on reboot.

## Shell-specific quirks

### zsh: BASH_SOURCE vs $0

`shell-hook` needs to find its own directory. In bash the canonical way is `${BASH_SOURCE[0]}`. In zsh, `$0` gives the path of the sourced script. The hook handles both:

```bash
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    _LW_HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    _LW_HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
```

### zsh completion (bashcompinit)

nvm's completion uses bash's `complete` builtin. zsh needs `bashcompinit` loaded first. Both `nvmload` and `shell-hook`'s parent-shell loader handle this.

### Other shells (fish, ksh, etc.)

Automatic RC file configuration only supports bash and zsh. The wrappers and shell hook are bash scripts. Other shells (fish, ksh, tcsh, etc.) would require native wrapper scripts and shell-specific hooks. Users on other shells can manually add wrapper directories to PATH.

## Testing changes

```bash
# Install from your working copy
./install.sh --local

# Source your shell config to pick up changes
source ~/.bashrc    # or source ~/.zshrc

# Test a wrapped command
node --version      # Should trigger lazy load

# Verify hook ran (wrapper dirs should be gone from PATH)
echo $PATH | tr ':' '\n' | grep lazy-wrappers

# After the first command, only "commands" should be in PATH
# node_wrappers and ruby_wrappers should be removed

# Uninstall cleanly
lw-uninstall
```

## Regenerating wrappers after changes

If you edit `wrappers.conf` in the installed copy:

```bash
lw-recreate     # Opens editor, then regenerates
```

Or manually:

```bash
~/.lazy-wrappers/scripts/generate_wrappers
```
