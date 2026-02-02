# Changelog

All notable changes to lazy-wrappers will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2026-02-01

### 🎉 Initial Release

First public release of lazy-wrappers — a tool to dramatically speed up your shell startup by lazy-loading `nvm` and `rbenv`.

### Features

#### Core Functionality
- **Lazy-loading for nvm (Node.js)** — Load nvm only when you actually use `node`, `npm`, `npx`, or related commands
- **Lazy-loading for rbenv (Ruby)** — Load rbenv only when you use `ruby`, `gem`, `bundle`, or related commands
- **Auto-installation** — Automatically clones nvm or rbenv if not already installed on your system
- **Shell hook** — Removes wrappers from PATH after first command, ensuring zero overhead for subsequent commands

#### Wrapped Binaries
Out of the box, the following commands are wrapped:

**Node.js (nvm):**
- `node`, `npm`, `npx`, `nvm`, `yarn`, `pnpm`, `corepack`
- `eslint`, `prettier`, `tsc`

**Ruby (rbenv):**
- `ruby`, `gem`, `rbenv`
- `bundle`, `rails`, `rake`, `rspec`, `rubocop`, `solargraph`

#### Shell Support
- **bash** — Full support via `.bash_profile` (or `.profile`) and `.bashrc`
- **zsh** — Full support via `.zprofile` and `.zshrc`
- **fish** — Support via `.config/fish/config.fish`
- **ksh** — Support via `.kshrc`
- **tcsh/csh** — Support via `.tcshrc` / `.cshrc`
- **dash** — Support via `.profile`

#### Installation & Uninstallation
- One-line installer: `curl -fsSL https://raw.githubusercontent.com/LuuchoRocha/lazy-wrappers/main/simple_install.sh | bash`
- Manual installation via `install.sh`
- Clean uninstallation via `uninstall.sh` with automatic backup of modified files

#### Customization
- Single configuration file (`wrappers.conf`) to add or remove wrapped binaries
- Simple format: `binary_name:loader` (where loader is `nvm` or `rbenv`)
- Regenerate wrappers anytime with `generate_wrappers.sh`

#### Developer Tools
- Comprehensive benchmarking script (`benchmark.sh`) to measure performance on your system
- ShellCheck-compliant scripts for reliability
- Detailed documentation and troubleshooting guide

### Performance

Typical results show **~95% faster shell startup** compared to traditional nvm/rbenv loading:

| Configuration | Startup Time |
|--------------|--------------|
| Baseline (no version managers) | ~6ms |
| Traditional nvm loading | ~250ms |
| Traditional rbenv loading | ~70ms |
| **With lazy-wrappers** | **~10ms** |

After the first command in a session, wrappers are removed from PATH — all subsequent commands run at native speed with **zero overhead**.

### Documentation

- [README.md](README.md) — Quick start and overview
- [BENCHMARK.md](BENCHMARK.md) — Detailed performance analysis
- [CONTRIBUTING.md](CONTRIBUTING.md) — Guidelines for contributors
- [docs/](docs/) — Full documentation site

---

[0.0.1]: https://github.com/LuuchoRocha/lazy-wrappers/releases/tag/v0.0.1
