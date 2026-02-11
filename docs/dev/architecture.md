---
layout: default
title: Architecture
---

# Architecture overview

## What lazy-wrappers does

lazy-wrappers defers loading of version managers (`nvm` for Node.js, `rbenv` for Ruby) until a command actually needs them. Instead of eagerly initializing these tools on every shell startup, it places lightweight wrapper scripts earlier in `PATH` that trigger loading on demand.

## Why it exists

Every new terminal session pays the cost of version manager initialization. `nvm` typically adds 200–400 ms; `rbenv` adds 60–100 ms. Across dozens of terminals per day, this adds up. If you open a terminal to run `ls` or `git status`, paying 300 ms to load nvm is pure waste.

lazy-wrappers eliminates this by:

1. Making shell startup near-instant (~5–10 ms vs 200–400 ms)
2. Loading managers only when needed (first `node`/`ruby` invocation)
3. Removing wrappers from `PATH` after loading, so subsequent commands have zero overhead

## Pros and cons

### Pros

- **~90 % faster shell startup** — version manager init is deferred entirely
- **Zero overhead after first use** — wrappers are removed from `PATH` by the shell hook
- **Auto-installs managers** — nvm/rbenv are cloned from GitHub if not present
- **Shebang compatible** — `#!/usr/bin/env node` works because wrappers use `exec`
- **Customizable** — add/remove binaries via `wrappers.conf`, regenerate instantly
- **Multi-shell support** — bash, zsh, and detection for fish/ksh/etc.

### Cons

- **First-command latency** — the first invocation of a wrapped binary triggers the full version manager load (~200–400 ms for nvm)
- **PATH complexity** — the system relies on PATH ordering, wrapper directory removal, and a shell hook
- **Shell hook runs on every prompt** — `__lazy_wrappers_cleanup` executes before every prompt (though it is very lightweight—just two file-existence checks)
- **Subshell / parent shell gap** — wrappers run in subshells via `exec`, so the parent shell does not see the loaded manager without the shell hook

## Component map

```
┌─────────────────────────────────────────────────────────────────────┐
│                        install.sh                                   │
│  Entry point: copies to ~/.lazy-wrappers, generates wrappers,       │
│  modifies shell RC files                                            │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     scripts/config                                  │
│  Shell detection, path variables (INSTALL_DIR, RC_FILES[], etc.)    │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                  scripts/wrappers.conf                               │
│  Single source of truth: "binary_name:loader" entries               │
│  (e.g., node:nvm, ruby:rbenv)                                       │
└─────────────────────┬───────────────────────────────────────────────┘
                      │ read by
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│               scripts/generate_wrappers                             │
│  Reads wrappers.conf → generates wrapper scripts via heredoc        │
│  templates + sed placeholder replacement                            │
│  Outputs to: bin/node_wrappers/ and bin/ruby_wrappers/              │
│  Skips static wrappers: nvm, rbenv (hand-crafted)                   │
└─────────────────────┬───────────────────────────────────────────────┘
                      │ generates
                      ▼
┌──────────────────────────────┐  ┌───────────────────────────────────┐
│   bin/node_wrappers/         │  │    bin/ruby_wrappers/             │
│   nvm (static, hand-crafted) │  │    rbenv (static, hand-crafted)  │
│   node (generated)           │  │    ruby (generated)              │
│   npm (generated)            │  │    gem (generated)               │
│   npx, yarn, pnpm, ...      │  │    bundle, rails, rake, ...      │
└──────────────┬───────────────┘  └──────────────┬────────────────────┘
               │ when invoked, source:            │
               ▼                                  ▼
┌──────────────────────────┐     ┌────────────────────────────────────┐
│    scripts/nvmload       │     │    scripts/rbenvload               │
│  Auto-clones nvm if      │     │  Auto-clones rbenv + ruby-build   │
│  missing, sources nvm.sh │     │  if missing, runs rbenv init      │
│  Sets NVM_ALREADY_LOADED │     │  Sets RBENV_ALREADY_LOADED        │
│  Creates flag file       │     │  Creates flag file                 │
└──────────────────────────┘     └────────────────────────────────────┘
               │                                  │
               │ flag files written to:           │
               ▼                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│          /tmp/lazy-wrappers-$$/                                     │
│          nvm_loaded  (flag file)                                    │
│          rbenv_loaded (flag file)                                   │
└─────────────────────┬───────────────────────────────────────────────┘
                      │ read by
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  scripts/shell_hook                                  │
│  Installs precmd (zsh) / PROMPT_COMMAND (bash) hook                 │
│  On each prompt: checks flag files → removes wrapper dirs from PATH │
│  → re-loads version manager into parent shell                       │
│  Cleans up flags dir on shell EXIT                                  │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                   bin/commands/                                      │
│  lw-benchmark  — measures startup time and per-command overhead      │
│  lw-recreate   — edits wrappers.conf and regenerates wrappers       │
│  lw-uninstall  — removes installation and cleans shell RC files     │
└─────────────────────────────────────────────────────────────────────┘
```

## Data flow: first command invocation

This sequence shows what happens when a user types `node --version` for the first time in a session.

```
User types: node --version

1. Shell resolves "node" → ~/.lazy-wrappers/scripts/bin/node_wrappers/node
   (wrapper has higher PATH priority)

2. Wrapper script runs (in a subshell):
   a. Sets recursion guard env var
   b. Removes node_wrappers/ from its own PATH
   c. "command -v node" → not found (nvm not loaded yet)
   d. Sources nvmload
   e. nvmload clones nvm if missing, sources nvm.sh
   f. nvmload touches /tmp/lazy-wrappers-$$/nvm_loaded
   g. "exec node --version" → replaces wrapper process with real node

3. Real node runs, prints version, exits

4. Back in parent shell, prompt is about to render
   a. PROMPT_COMMAND / precmd fires __lazy_wrappers_cleanup
   b. Checks: /tmp/lazy-wrappers-$$/nvm_loaded exists? yes
   c. Removes node_wrappers/ from parent's PATH
   d. Sources nvm.sh into parent shell
   e. Sets NVM_ALREADY_LOADED=1

5. All future "node" calls resolve directly to the real binary
```

## File ownership

| File | Role | Modified at install? | Modified at runtime? |
|------|------|---------------------|---------------------|
| `install.sh` | Installer | No (source) | No |
| `scripts/config` | Configuration | No | No |
| `scripts/wrappers.conf` | Binary list | No | User can edit, then `lw-recreate` |
| `scripts/generate_wrappers` | Generator | No | No |
| `scripts/nvmload` | nvm loader | No | No |
| `scripts/rbenvload` | rbenv loader | No | No |
| `scripts/shell_hook` | PATH cleanup hook | No | No |
| `bin/node_wrappers/nvm` | Static wrapper | Copied at install | No |
| `bin/ruby_wrappers/rbenv` | Static wrapper | Copied at install | No |
| `bin/node_wrappers/*` | Generated wrappers | Generated at install | No |
| `bin/ruby_wrappers/*` | Generated wrappers | Generated at install | No |
| `~/.bashrc` / `~/.zshrc` | Shell RC files | Yes (lines appended) | No |
| `/tmp/lazy-wrappers-$$/` | Runtime flags | No | Yes (created/deleted per session) |
