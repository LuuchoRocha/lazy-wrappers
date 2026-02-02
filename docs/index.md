---
layout: page
title: lazy-wrappers
---

# lazy-wrappers

Fast shell startup matters when you live in a terminal.

Most developer setups load `nvm` and `rbenv` in every new shell—convenient, but you pay the initialization cost even when you just need a terminal for:

- checking git status or diffs
- moving files and grepping logs
- running `htop` or watching a process
- quick one-off commands unrelated to Node or Ruby

lazy-wrappers defers version-manager initialization until the moment you actually run a related command. It does this by placing lightweight wrappers earlier in your `PATH`, and then removing those wrappers after the version manager is loaded so subsequent commands run at native speed.

**Result:** ~90% faster shell startup with ~1ms one-time overhead on first command.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/LuuchoRocha/lazy-wrappers/main/simple_install.sh | bash
```

Manual install:

```bash
git clone https://github.com/LuuchoRocha/lazy-wrappers.git
cd lazy-wrappers
./install.sh
```

## What you get

- Faster interactive shell startup by default
- No change to how you use Node or Ruby once they are needed
- Works with shebangs like `#!/usr/bin/env node`
- Extensible wrappers list (wrap your own tools)

## The trade-off

Traditional initialization pays the `nvm`/`rbenv` cost at shell startup, every time.

lazy-wrappers moves that cost to the first wrapped command you actually run. In exchange:

- shells start quickly even when you open many tabs/windows
- the first `node` or `ruby` call pays a one-time setup cost
- after that, wrappers are removed from `PATH` and commands run directly

If your workflow is “one terminal open all day and constant Node/Ruby usage”, you may notice less improvement. If your workflow includes many short-lived terminals, the difference is immediate.

## Learn more

- [Why this exists](why) — the motivation
- [How it works](how-it-works) — what happens under the hood
- [Install](install) — setup and configuration
- [Benchmarks](benchmarks) — real measurements
- [FAQ](faq) — common questions
- [Compatibility](compatibility) — shells and frameworks
