# Benchmarking lazy-wrappers

This tool includes a comprehensive benchmark to measure both the benefits and trade-offs of using lazy-wrappers on your specific system.

## Running the benchmark

```bash
./benchmark.sh [iterations]
```

Default is 10 iterations per test. Use more for better accuracy:

```bash
./benchmark.sh 20
```

## What it measures

### Part 1: Shell Startup Time

Compares how long it takes to open a new terminal with different configurations:

- **Baseline**: No version managers loaded
- **Traditional nvm**: Loading nvm in your shell config (the slow way)
- **Traditional rbenv**: Loading rbenv in your shell config
- **lazy-wrappers**: Our approach — version managers load on-demand

Typical results show **86-96% faster** shell startup compared to traditional loading.

### Part 2: First-Command Overhead

The first time you run a wrapped command (like `node`), the wrapper loads the version manager and then executes the real binary. This section measures that one-time overhead.

**Important:** After the first command, a shell hook removes the wrappers from your PATH entirely. All subsequent commands in that session run at full native speed with **zero overhead**.

### Part 3: Summary

Since wrappers are removed from PATH after the first command, there's no break-even calculation needed. You get the full startup savings with only a one-time overhead on the first command.

**Result:** lazy-wrappers is beneficial for virtually all workflows.

## Example output

```
┌──────────────────────────────────────────────────────────────────┐
│  PART 1: Shell Startup Time                                       │
└──────────────────────────────────────────────────────────────────┘

  Configuration                         Avg      Min      Max
  ──────────────────────────────── ──────── ──────── ────────
  Baseline (no managers)                5ms      5ms      7ms
  Traditional nvm                     215ms    210ms    220ms
  Traditional rbenv                    60ms     58ms     64ms
  lazy-wrappers                         8ms      8ms     10ms

  ✓ vs nvm:   -207ms (96% faster)
  ✓ vs rbenv: -52ms (86% faster)

┌──────────────────────────────────────────────────────────────────┐
│  PART 2: First-Command Overhead                                   │
└──────────────────────────────────────────────────────────────────┘

  Binary          Wrapper     Direct   Overhead        Pct
  ──────────── ────────── ────────── ────────── ──────────
  node                7ms        6ms       +1ms      +16%
  npm                65ms       63ms       +2ms       +3%
  npx                65ms       63ms       +2ms       +3%
  ruby               46ms       44ms       +2ms       +4%
  gem               117ms      116ms       +1ms       +0%
  bundle            136ms      134ms       +2ms       +1%

┌──────────────────────────────────────────────────────────────────┐
│  PART 3: Break-Even Analysis                                      │
└──────────────────────────────────────────────────────────────────┘

  Shell startup savings:      207ms
  First-command overhead:     1ms (one-time, then wrappers removed)
  Subsequent commands:        0ms overhead (direct binary execution)

  Verdict:
  ✓ lazy-wrappers is beneficial for virtually all workflows
```

## The trade-offs

**Pros:**
- Shell starts ~207ms faster (or more with slow nvm setups)
- Multiple terminal windows don't each pay the startup cost
- Version managers only load when you actually need them
- **Zero overhead after first command** — wrappers are removed from PATH

**Cons:**
- First command in a session triggers the version manager load (one-time cost)
- ~1ms one-time overhead on that first command

## Who benefits most?

- Developers who open lots of terminal sessions
- Anyone annoyed by slow shell startup
- People who often run quick commands without needing node/ruby

## Who might not benefit?

- Users who always need node/ruby immediately on shell start (though even then, you only pay the load cost once)
- Extremely simple shell setups where startup is already fast

## Results file

The benchmark saves machine-readable results to `benchmark-results.txt`:

```
shell=/bin/bash
iterations=100
baseline_ms=5
nvm_ms=215
rbenv_ms=60
lazy_wrappers_ms=8
startup_savings_ms=207
first_command_overhead_ms=1
subsequent_command_overhead_ms=0
```

Use this for tracking performance over time or comparing across machines.
