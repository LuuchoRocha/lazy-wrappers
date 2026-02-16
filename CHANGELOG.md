# Changelog

All notable changes to lazy-wrappers will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-02-15

### 🚀 Improved

- **Refactored installer architecture** — Moved core install logic from `install.sh` to `scripts/install`; `install.sh` is now a lightweight entry point that supports `--local`, `--version`, and `--help` flags, and can install remotely by cloning the repo
- **Enhanced benchmark** — `lw-benchmark` now includes a combined nvm + rbenv benchmark step (5 steps instead of 4), giving a more realistic comparison against typical setups with both managers loaded
- **Added VERSION file** — Tracks the current release version, used by `install.sh --version`

### 🔧 Changed

- Removed `simple_install.sh` (replaced by `install.sh` remote install mode)
- Removed `benchmark-results.md` (benchmarks are now in the docs site)
- Removed CI workflow (`ci.yml`)
- Updated documentation references from `install.sh` → `install.sh --local` for manual installs, `benchmark.sh` → `lw-benchmark`, `uninstall.sh` → `lw-uninstall`

## [0.1.0] - 2026-02-11

### ✨ Added

- **`lw-recreate` command** — New command to regenerate wrappers after editing `wrappers.conf`, without re-running the full installer
- **`lw-benchmark` command** — Bundled benchmark script as a subcommand accessible from PATH
- **Developer documentation** — Comprehensive dev docs covering architecture, wrapper generation, loaders, shell hook, static wrappers, lifecycle, and gotchas

### 🚀 Improved

- **Performance & simplified wrapper generation** — Streamlined `generate_wrappers` and `shell_hook` scripts; removed `.sh` extensions for cleaner invocation
- **Prevented redundant re-loading** — Static wrappers for `nvm` and `rbenv` now skip loading if already initialized, avoiding unnecessary work
- **Completions support** — Fixed rbenv and nvm completions so tab-completion works correctly after lazy-loading

### 🔧 Changed

- Removed standalone `uninstall.sh`, `benchmark.sh`, `shellcheck.sh`, `BENCHMARK.md`, `CONTRIBUTING.md`, and `LICENSE` from the repo root (functionality moved to subcommands or docs site)
- Selective file copying during install now targets only essential files
- Added `irb` and `erb` to Ruby wrappers in `wrappers.conf`

## [0.0.4] - 2026-02-02

### ✨ Improved

- **Enhanced UI** — Colorful output with box-drawing characters, progress indicators, and better formatting for both installer and uninstaller
- **Selective file copying** — Install now copies only required files (`install.sh`, `uninstall.sh`, `benchmark.sh`, `scripts/**`) instead of the entire repository
- **New commands directory** — Added `scripts/bin/commands/` with `lw-uninstall` and `lw-benchmark` commands accessible from PATH

### 🐛 Fixed

- **Static wrappers not copied** — Fixed bug where `nvm` and `rbenv` static wrappers weren't being copied during installation, causing them to be unavailable until another wrapper loaded them
- **Malformed sed command** — Fixed broken line continuation in uninstall.sh that prevented proper cleanup of shell config files

### 🔧 Changed

- Wrapper generator now properly skips static wrappers (`nvm`, `rbenv`) that have hand-crafted implementations
- Added `nvm:nvm` and `rbenv:rbenv` entries to `wrappers.conf` for documentation purposes
- PATH now includes the commands directory for `lw-*` utilities

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
- One-line installer: `curl -fsSL https://raw.githubusercontent.com/LuuchoRocha/lazy-wrappers/main/install.sh | bash`
- Manual installation via `./install.sh --local`
- Clean uninstallation via `lw-uninstall` with automatic backup of modified files

#### Customization
- Single configuration file (`wrappers.conf`) to add or remove wrapped binaries
- Simple format: `binary_name:loader` (where loader is `nvm` or `rbenv`)
- Regenerate wrappers anytime with `generate_wrappers`

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

[0.1.1]: https://github.com/LuuchoRocha/lazy-wrappers/releases/tag/0.1.1
[0.1.0]: https://github.com/LuuchoRocha/lazy-wrappers/releases/tag/0.1.0
[0.0.4]: https://github.com/LuuchoRocha/lazy-wrappers/releases/tag/v0.0.4
[0.0.1]: https://github.com/LuuchoRocha/lazy-wrappers/releases/tag/v0.0.1
