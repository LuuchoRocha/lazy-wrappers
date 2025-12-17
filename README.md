# LazyWrappers

Simple, lazy-loading shell wrappers for `nvm` and `rbenv`, plus helpers for `node`, `npm`, `ruby`, `gem`, and more — designed to speed up your zsh/bash startup without sacrificing convenience. **LazyWrappers can even auto-install `nvm` or `rbenv` if they are missing, so you can get started with zero manual setup.**

## What is it?

LazyWrappers is a small collection of shell scripts that provide:

- **On-demand initialization** of `nvm` and `rbenv` only when they're actually needed
- **Faster shell startup times**, especially useful in large projects or slow terminals
- **Auto-installation of missing tools** (`nvm` or `rbenv`) if not already installed
- **Transparent wrapper scripts** for common CLI tools like `node`, `npm`, `npx`, `yarn`, `pnpm`, `ruby`, and `gem`
- **Works with `/usr/bin/env`** and other tools that search for binaries in PATH
- **Safe and clean integration** with your existing shell setup (bash or zsh)

Everything is modular and easy to uninstall. No more loading heavy version managers on every shell session just to check your `git status`.

## Features

- ⚡ Lazy loading of `nvm` and `rbenv`
- 📦 Automatic cloning if not installed
- 🐚 Compatible with Bash and Zsh
- 🔧 Wrapper scripts for: `rbenv`, `nvm`, `ruby`, `gem`, `node`, `npm`, `npx`, `yarn`, `pnpm`
- 🔍 Works with `/usr/bin/env` and shebang lines
- 🧼 Clean uninstall support

## How it works

LazyWrappers installs lightweight wrapper scripts to `~/.local/bin` that only load `nvm` or `rbenv` when you actually use them. This means:

1. Your shell starts instantly without waiting for version managers to initialize
2. The first time you run `node`, `npm`, `ruby`, etc., the appropriate version manager is loaded
3. Subsequent calls work normally since the version manager is now loaded
4. Tools like shebangs (`#!/usr/bin/env node`) work perfectly because the wrappers are real executable files in your PATH

## Installation

Run the installation script to set up the wrappers, automatically install `nvm` or `rbenv` if missing, and add `~/.local/bin` to your PATH:

```bash
./install.sh
