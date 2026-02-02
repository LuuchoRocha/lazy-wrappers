# lazy-wrappers

Speed up your shell startup by lazy-loading `nvm` and `rbenv`. Instead of loading these version managers on every terminal session, they're loaded only when you actually use `node`, `ruby`, or related commands.

**Key Features:**
- ⚡ ~96% faster shell startup (see [benchmarks](#benchmarks))
- 🔧 Auto-installs nvm/rbenv if missing
- 🎯 Works with shebangs (`#!/usr/bin/env node`)
- 🛠️ Easy to customize and extend

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/LuuchoRocha/lazy-wrappers/main/simple_install.sh | bash
```

Or install manually:

```bash
git clone https://github.com/LuuchoRocha/lazy-wrappers.git
cd lazy-wrappers
./install.sh
```

## Why?

Loading `nvm` can add 200-400ms to every shell startup. That adds up when you're opening terminals all day. With lazy-wrappers, your shell starts instantly and version managers load on-demand.

See detailed [performance analysis](BENCHMARK.md) or run `./benchmark.sh` on your system.

## What gets wrapped?

By default: `node`, `npm`, `npx`, `yarn`, `pnpm`, `ruby`, `gem`, `bundle`, `rails`, and [many more](scripts/wrappers.conf).

### Customizing Wrappers

Edit `scripts/wrappers.conf` to add your own:

```bash
# Format: binary_name:loader
my-tool:nvm      # wraps my-tool to load nvm first
my-gem:rbenv     # wraps my-gem to load rbenv first
```

Then regenerate wrappers:
```bash
~/.lazy-wrappers/scripts/generate_wrappers.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details on adding wrappers.

## How it works

1. Wrapper scripts are added to your PATH before the real binaries
2. When you run `node`, the wrapper checks if nvm is loaded
3. If not, it sources nvm, then runs the real `node`
4. A shell hook removes wrappers from PATH after loading
5. **All subsequent commands go directly to the real binary with zero overhead**

## Benchmarks

Run `./benchmark.sh` to measure the impact on your system. See [BENCHMARK.md](BENCHMARK.md) for detailed analysis.

**TL;DR:** ~96% faster shell startup, ~1ms overhead on first command only (wrappers then removed from PATH).

## Uninstall

```bash
./uninstall.sh
```

This will:
1. Remove lazy-wrappers configuration from your shell RC files
2. Optionally delete the `~/.lazy-wrappers` directory
3. Create backups before modifying any files

## Troubleshooting

### Wrappers not working after installation

**Symptom**: Running `node` or `ruby` doesn't trigger lazy loading.

**Solution**: 
1. Restart your terminal or run: `source ~/.bashrc` (or `~/.zshrc` for zsh)
2. Verify wrappers are in PATH: `which node` should show `~/.lazy-wrappers/scripts/bin/node_wrappers/node`
3. Check that your RC file was modified: `grep lazy-wrappers ~/.bashrc`

### Version manager already loaded on startup

**Symptom**: Shell still loads nvm/rbenv on startup despite lazy-wrappers.

**Solution**:
1. Check your RC files for existing nvm/rbenv initialization:
   ```bash
   grep -n "nvm.sh" ~/.bashrc ~/.bash_profile ~/.profile 2>/dev/null
   grep -n "rbenv init" ~/.bashrc ~/.bash_profile ~/.profile 2>/dev/null
   ```
2. Comment out or remove the traditional nvm/rbenv loading lines
3. Keep only the lazy-wrappers configuration (marked with `# lazy-wrappers:`)

### Git not installed error

**Symptom**: Error message about git being required.

**Solution**: Install git:
```bash
# Ubuntu/Debian
sudo apt-get install git

# macOS
brew install git

# Fedora
sudo dnf install git
```

### Permission denied errors

**Symptom**: Cannot execute wrapper scripts or write to installation directory.

**Solution**:
1. Ensure installation directory is writable: `ls -ld ~/.lazy-wrappers`
2. Fix permissions if needed: `chmod -R u+rwX ~/.lazy-wrappers`
3. Make wrappers executable: `chmod +x ~/.lazy-wrappers/scripts/bin/*/*`

### Wrapper recursion or infinite loops

**Symptom**: Commands hang or repeatedly call themselves.

**Solution**: This should not happen with the current implementation, but if it does:
1. Check that PATH modification in wrappers is working: `echo $PATH`
2. Verify version manager is properly installed
3. Try reinstalling: `./uninstall.sh && ./install.sh`

### Performance not improving

**Symptom**: Shell startup is still slow.

**Solution**:
1. Run benchmarks to confirm: `./benchmark.sh`
2. Check for other slow RC file operations: `time source ~/.bashrc`
3. Verify nvm/rbenv aren't being loaded elsewhere in your RC files
4. Profile your shell startup to find other bottlenecks

### Compatibility with specific shells

**Supported shells**: bash, zsh, fish, ksh, tcsh, csh, dash, sh

**Unsupported shell**: If you use a different shell, lazy-wrappers will warn you and try to use `.profile`. You may need to manually add the wrapper directories to your PATH.

## Configuration

### Environment Variables

- `NVM_DIR`: Location of nvm installation (default: `~/.nvm`)
- `RBENV_DIR`: Location of rbenv installation (default: `~/.rbenv`)

Set these before running `install.sh` if you use non-standard locations:

```bash
export NVM_DIR="/custom/nvm/path"
export RBENV_DIR="/custom/rbenv/path"
./install.sh
```

### Customizing Installation Location

The default installation location is `~/.lazy-wrappers`. To change this, edit `scripts/config` before installing.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Code standards  
- Testing guidelines
- How to submit changes

## License

MIT License - See [LICENSE](LICENSE) file for details.
