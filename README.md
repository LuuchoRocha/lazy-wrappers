# lazy-wrappers

**90% faster shell startup.** Defer loading of `nvm` and `rbenv` until you actually run `node`, `ruby`, or related commands.

Traditional shell configs load version managers eagerly on every terminal session—`nvm` typically adds 200-400ms of startup time. With lazy-wrappers, your shell starts in milliseconds and version managers load on-demand.

**Measured improvements:**

- Shell startup: **90% faster** vs traditional nvm loading (5-10ms vs 200-400ms)
- First command: ~1-2ms one-time overhead to load the version manager
- Subsequent commands: **zero overhead**—wrappers are removed from PATH after first use

**Additional features:**

- 🔧 Auto-installs nvm/rbenv if missing
- 🎯 Works with shebangs (`#!/usr/bin/env node`)
- 🛠️ Easy to customize and extend

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/LuuchoRocha/lazy-wrappers/main/install.sh | bash
```

Or install manually:

```bash
git clone https://github.com/LuuchoRocha/lazy-wrappers.git
cd lazy-wrappers
./install.sh --local
```

## Performance

**What normally slows shells down:**

- Traditional shell configs eagerly load version managers like `nvm` and `rbenv` at startup
- `nvm` initialization alone adds 200-400ms to every new terminal
- This cost is paid on every shell restart, multiplied across dozens of terminals per day

**What lazy-wrappers defers:**

- Version manager initialization is skipped at shell startup
- Loading only happens when you first run a wrapped command (`node`, `npm`, `ruby`, `gem`, etc.)
- After the first command, wrappers are removed from PATH—subsequent calls have zero overhead

**When the speedup is most noticeable:**

- Opening new terminal windows/tabs (instant startup vs 200-400ms delay)
- Frequent shell restarts during development
- Running quick commands that don't require node/ruby (shell starts fast, no unnecessary loading)
- Opening multiple terminals simultaneously (each one starts instantly)

Run `lw-benchmark` on your system to measure the exact improvement.

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
~/.lazy-wrappers/scripts/generate_wrappers
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for more details on adding wrappers.

## How it works

1. Wrapper scripts are added to your PATH before the real binaries
2. When you run `node`, the wrapper checks if nvm is loaded
3. If not, it sources nvm, then runs the real `node`
4. A shell hook removes wrappers from PATH after loading
5. **All subsequent commands go directly to the real binary with zero overhead**

## Benchmarks

Run `lw-benchmark` to measure the impact on your system. The benchmark compares shell startup time and first-command overhead across different configurations.

### Example Results

```plain
┌──────────────────────────────────────────────────────────────────┐
│  PART 1: Shell Startup Time                                       │
└──────────────────────────────────────────────────────────────────┘

  Configuration                         Avg      Min      Max
  ──────────────────────────────── ──────── ──────── ────────
  Baseline (no managers)                6ms      5ms      8ms
  Traditional nvm                     245ms    237ms    254ms
  Traditional rbenv                    67ms     63ms    101ms
  lazy-wrappers                         9ms      9ms     13ms

  ✓ vs nvm:   -236ms (96% faster)
  ✓ vs rbenv: -58ms (86% faster)

┌──────────────────────────────────────────────────────────────────┐
│  PART 2: First-Command Overhead                                   │
└──────────────────────────────────────────────────────────────────┘

  Binary          Wrapper     Direct   Overhead        Pct
  ──────────── ────────── ────────── ────────── ──────────
  node                8ms        7ms       +1ms      +14%
  npm                65ms       64ms       +1ms       +1%
  npx                66ms       65ms       +1ms       +1%
  ruby               50ms       49ms       +1ms       +2%
  gem               121ms      120ms       +1ms       +0%
  bundle            139ms      138ms       +1ms       +0%

┌──────────────────────────────────────────────────────────────────┐
│  PART 3: Break-Even Analysis                                      │
└──────────────────────────────────────────────────────────────────┘

  Shell startup savings:      236ms
  First-command overhead:     1ms (one-time, then wrappers removed)
  Subsequent commands:        0ms overhead (direct binary execution)

  Verdict:
  ✓ lazy-wrappers is beneficial for virtually all workflows
```

### What Was Measured

**Part 1 - Shell Startup Time:**
Measures the time to spawn a new shell with different configurations. Baseline is a shell with no version managers. Traditional nvm/rbenv load the version manager in the shell config file. lazy-wrappers uses the wrapper approach.

**Part 2 - First-Command Overhead:**
Measures the one-time cost when running a wrapped command for the first time in a session. This includes the time to load the version manager and execute the binary. After this first command, wrappers are removed from PATH.

**Part 3 - Break-Even:**
Since wrappers are removed from PATH after the first command, there's no ongoing overhead. All subsequent commands execute at native speed.

### What the Delta Means

**Shell startup:** 236ms saved per new terminal. If you open 20 terminals per day, that's **4.7 seconds saved daily**, **28 minutes per year**.

**First-command overhead:** ~1ms one-time cost when you first use a wrapped binary in a session. Negligible compared to the 236ms startup savings.

**Net result:** More than **96% faster** shell startup with effectively zero ongoing cost. The savings compound with every new terminal window, tab, or shell restart.

## Uninstall

```bash
lw-uninstall
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
3. Try reinstalling: `lw-uninstall && ./install.sh --local`

### Performance not improving

**Symptom**: Shell startup is still slow.

**Solution**:

1. Run benchmarks to confirm: `lw-benchmark`
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

Set these before running `install.sh --local` if you use non-standard locations:

```bash
export NVM_DIR="/custom/nvm/path"
export RBENV_DIR="/custom/rbenv/path"
./install.sh --local
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
