# LazyWrappers

Simple, lazy-loading shell wrappers for `nvm` and `rbenv`, plus helpers for `node`, `npm`, `ruby`, and more — designed to speed up your zsh/bash startup without sacrificing convenience.

## What is it?

LazyWrappers is a small collection of shell scripts that provide:

- **On-demand initialization** of `nvm` and `rbenv` only when they're actually needed
- **Faster shell startup times**, especially useful in large projects or slow terminals
- **Auto-installation of missing tools** (`nvm` or `rbenv`) if not already installed
- **Convenient aliases and helpers** for common CLI tools like `node`, `npm`, `npx`, `yarn`, `pnpm`, and `ruby`
- **Safe and clean integration** with your existing shell setup (bash or zsh)

Everything is modular and easy to uninstall. No more loading heavy version managers on every shell session just to check your `git status`.

## Features

- ⚡ Lazy loading of `nvm` and `rbenv`
- 📦 Automatic cloning if not installed
- 🐚 Compatible with Bash and Zsh
- 🔧 Supports `node`, `npm`, `npx`, `yarn`, `pnpm`, and `ruby`
- 🧼 Clean uninstall support

## Installation

Run the installation script to set up the wrappers and patch your shell config file (`.bashrc` or `.zshrc`):

```bash
./install.sh
````

Then reload your shell configuration:

```bash
source ~/.bashrc
# or
source ~/.zshrc
```

## Uninstallation

To completely remove the wrappers and undo any changes to your shell config, run:

```bash
./uninstall.sh
```

This will clean up any files or lines added during installation.

## Notes

* The wrapper scripts are installed to `~/.local/bin`
* Your shell config is only modified if necessary, and changes are idempotent
* Works great for developers who want `nvm` and `rbenv` available *without* always loading them

---

Happy coding 🚀
