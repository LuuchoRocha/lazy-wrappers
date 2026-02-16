---
layout: default
title: FAQ
---

# FAQ

## Does this replace nvm or rbenv?

No. It defers their initialization. Once loaded, your environment behaves as if you initialized them normally.

## What happens the first time I run node or ruby?

The wrapper loads the corresponding version manager and then runs the command. If the manager is not installed, lazy-wrappers installs it on that first use.

## Will this break scripts?

Wrappers are executables in `PATH`, which helps with shebang-based scripts (`#!/usr/bin/env node`). That said, if you rely on specific non-interactive initialization behavior from your shell RC files, review your setup carefully.

## Is there overhead on every command?

No. After the first load, wrappers are removed from `PATH`, so subsequent commands run directly.

## Why not just optimize my shell config?

You should! Profiling shell startup is valuable, and this doesn't replace good shell hygiene.

lazy-wrappers targets one specific slowdown: initializing version managers in shells that never use them.

## What if nvm/rbenv already load on startup?

You won't see the benefit. Remove or comment out the traditional initialization and keep only lazy-wrappers.

## Is curl | bash required?

No. Clone the repository and run `./install.sh --local` instead.
