# Contributing to lazy-wrappers

Thank you for your interest in contributing to lazy-wrappers! This document provides guidelines and instructions for contributing to the project.

## Development Setup

### Prerequisites

- **Git**: Required for cloning nvm/rbenv if not installed
- **Bash**: Version 4.0 or higher recommended
- **ShellCheck**: For linting shell scripts (optional but recommended)

### Initial Setup

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/lazy-wrappers.git
   cd lazy-wrappers
   ```

2. Install ShellCheck for linting (optional):
   ```bash
   # macOS
   brew install shellcheck
   
   # Ubuntu/Debian
   apt-get install shellcheck
   
   # Fedora
   dnf install ShellCheck
   ```

3. Test the installation locally:
   ```bash
   ./install.sh
   source ~/.bashrc  # or ~/.zshrc
   ```

## Code Standards

### Shell Script Best Practices

1. **Always use strict mode**:
   ```bash
   #!/bin/bash
   set -euo pipefail
   ```

2. **Quote variables**: Always quote variables to prevent word splitting and glob expansion
   ```bash
   # Good
   echo "$variable"
   
   # Bad
   echo $variable
   ```

3. **Check command success**: Verify important operations succeed
   ```bash
   if ! command_that_might_fail; then
       echo "Error: command failed"
       exit 1
   fi
   ```

4. **Provide helpful error messages**: Include context about what failed and how to fix it
   ```bash
   echo "Error: git is required but not installed." >&2
   echo "Please install git and try again." >&2
   ```

### Linting

Before submitting code, run ShellCheck locally:

```bash
# Run with CI-equivalent settings (default)
./shellcheck.sh

# Run with pretty terminal output
./shellcheck.sh -f tty

# Show all issues including style suggestions
./shellcheck.sh -s style -f tty
```

The project includes:
- `shellcheck.sh` - Local linting script that mirrors CI
- `.shellcheckrc` - ShellCheck configuration (disables SC1091, SC2154)

All scripts should pass shellcheck without errors at the `warning` severity level.

## Adding New Wrappers

To add support for wrapping additional binaries:

1. Edit `scripts/wrappers.conf`
2. Add a line in the format: `binary_name:loader`
   - Use `nvm` for Node.js-related binaries
   - Use `rbenv` for Ruby-related binaries

Example:
```
# Add TypeScript compiler
tsc:nvm

# Add RuboCop linter
rubocop:rbenv
```

3. Test the changes:
   ```bash
   ./install.sh
   # Verify the wrapper works
   which tsc  # Should point to wrapper
   tsc --version  # Should trigger nvm load
   ```

## Testing

### Manual Testing

Test your changes thoroughly before submitting:

1. **Test installation**:
   ```bash
   ./install.sh
   ```

2. **Test wrapper functionality**:
   ```bash
   # First invocation should load version manager
   node --version
   
   # Subsequent invocations should be fast
   node --version
   ```

3. **Test uninstallation**:
   ```bash
   ./uninstall.sh
   ```

4. **Test on different shells** (if possible):
   - bash
   - zsh
   - fish (if you use it)

### Running Benchmarks

Test performance impact of your changes:

```bash
./benchmark.sh
```

Compare results before and after your changes to ensure no performance regression.

## Submitting Changes

### Pull Request Process

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the code standards above

3. **Test thoroughly** on your local system

4. **Lint your code**:
   ```bash
   ./shellcheck.sh
   ```

5. **Commit with clear messages**:
   ```bash
   git commit -m "Add support for XYZ binary wrapper"
   ```

6. **Push and create a PR**:
   ```bash
   git push origin feature/your-feature-name
   ```

### PR Guidelines

- **Clear title**: Summarize the change in one line
- **Description**: Explain what the PR does and why
- **Testing**: Describe how you tested the changes
- **Screenshots**: If applicable, include before/after comparisons

## Project Structure

```
lazy-wrappers/
├── install.sh              # Main installer script
├── uninstall.sh            # Uninstaller script  
├── benchmark.sh            # Performance benchmarking tool
├── scripts/
│   ├── config              # Shell detection and path configuration
│   ├── wrappers.conf       # List of binaries to wrap
│   ├── generate_wrappers.sh # Generates wrapper scripts
│   ├── nvmload             # Lazy loader for nvm
│   ├── rbenvload           # Lazy loader for rbenv
│   ├── shell_hook.sh       # Post-command PATH cleanup hook
│   └── bin/
│       ├── node_wrappers/  # Generated Node.js wrappers (not in git)
│       └── ruby_wrappers/  # Generated Ruby wrappers (not in git)
├── README.md               # User documentation
├── BENCHMARK.md            # Benchmarking documentation
└── CONTRIBUTING.md         # This file
```

## Architecture

### How Wrappers Work

1. **Installation**: `install.sh` copies the project to `~/.lazy-wrappers` and modifies shell RC files to add wrapper directories to PATH

2. **Wrapper Generation**: `generate_wrappers.sh` reads `wrappers.conf` and creates a wrapper script for each binary

3. **Wrapper Execution**: When a wrapped binary is invoked:
   - Check if version manager is already loaded (fast path)
   - If not, remove wrapper directory from PATH
   - Load the version manager (nvmload/rbenvload)
   - Execute the real binary

4. **Shell Hook**: After each command, the shell hook removes wrapper directories from PATH if the version manager is loaded

### Key Design Principles

- **Lazy Loading**: Version managers load only when needed
- **No Recursion**: Wrappers remove themselves from PATH before loading
- **Fast Path**: Already-loaded version managers skip wrapper logic
- **Minimal Overhead**: Benchmarked at ~1ms per command after loading

## Getting Help

- **Issues**: For bugs and feature requests, [open an issue](https://github.com/LuuchoRocha/lazy-wrappers/issues)
- **Discussions**: For questions and general discussion, use [GitHub Discussions](https://github.com/LuuchoRocha/lazy-wrappers/discussions)

## Code of Conduct

Be respectful and constructive in all interactions. We're all here to make lazy-wrappers better!
