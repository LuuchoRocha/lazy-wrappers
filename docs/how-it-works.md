---
layout: default
title: How it works
---

# How it works

At a high level:

1. Wrapper executables are generated for common Node and Ruby commands.
2. The wrapper directories are added to your `PATH` before the real binaries.
3. When you run a wrapped command (for example `node`), the wrapper checks whether the required manager is available.
4. If needed, the wrapper loads the manager and then runs the real command.
5. A shell hook removes wrapper directories from `PATH` after the manager has been loaded.
6. From that point on, your shell runs the real binaries directly.

## Why executables instead of shell functions

Wrappers are regular executables found via `PATH`. This matters for shebang-based scripts:

```bash
#!/usr/bin/env node
```

`/usr/bin/env` resolves `node` by searching `PATH`. If the wrapper is first, it can reliably trigger lazy loading even when the command is executed outside an interactive prompt.

## Auto-install on first use

If `nvm` or `rbenv` isn't installed, lazy-wrappers installs the required manager the first time you invoke a command that needs it.

## What gets wrapped

By default:

- `node`, `npm`, `npx`, `nvm`, `yarn`, `pnpm`, `corepack`, `tsc`, `eslint`, `prettier`, `vite`, `webpack`, and more
- `ruby`, `gem`, `rbenv`, `bundle`, `rails`, `rake`, `rspec`, `rubocop`, `solargraph`, `irb`, and more
- see `scripts/wrappers.conf` for the full list

The goal is practical coverage—tools that commonly fail if the manager isn't initialized.

## Custom wrappers

Wrappers are configured in `scripts/wrappers.conf`.

Format:

```bash
binary_name:loader
my-tool:nvm
my-gem:rbenv
```

After editing, regenerate wrappers:

```bash
~/.lazy-wrappers/scripts/generate_wrappers
```

## After first use: no overhead

Many lazy-load approaches keep interception logic in place permanently.

lazy-wrappers removes itself from the hot path by rewriting `PATH` after the first manager load:

- Before first call: wrappers exist and can trigger loading
- After first call: wrappers are removed; everything runs normally
