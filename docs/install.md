---
layout: default
title: Install
---

# Install

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/LuuchoRocha/lazy-wrappers/main/install.sh | bash
```

Manual:

```bash
git clone https://github.com/LuuchoRocha/lazy-wrappers.git
cd lazy-wrappers
./install.sh --local
```

## What happens

1. Copies the project to `~/.lazy-wrappers`
2. Modifies your shell startup files to prepend wrapper directories to `PATH` and enable the cleanup hook

Automatic startup-file configuration currently supports bash and zsh.

If your shell already initializes `nvm` or `rbenv` the traditional way, remove or comment out those lines—otherwise you'll still pay the startup cost.

To locate existing initialization:

```bash
grep -n "nvm.sh" ~/.bashrc ~/.bash_profile ~/.profile ~/.zshrc 2>/dev/null
grep -n "rbenv init" ~/.bashrc ~/.bash_profile ~/.profile ~/.zshrc 2>/dev/null
```

## Environment variables

If you use non-default install locations for version managers, set these before installation:

- `NVM_DIR` (default: `~/.nvm`)
- `RBENV_DIR` (default: `~/.rbenv`)

Example:

```bash
export NVM_DIR="/custom/nvm/path"
export RBENV_DIR="/custom/rbenv/path"
./install.sh --local
```

## Uninstall

```bash
lw-uninstall
```

Uninstall removes lazy-wrappers configuration from shell RC files and can optionally delete the installation directory. Backups are created before modifying files.
