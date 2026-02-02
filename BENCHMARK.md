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

## The trade-offs

**Pros:**
- Shell starts ~236ms faster (or more with slow nvm setups)
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
iterations=1000
baseline_ms=6
nvm_ms=245
rbenv_ms=67
lazy_wrappers_ms=9
startup_savings_ms=236
first_command_overhead_ms=1
subsequent_command_overhead_ms=0
```

Use this for tracking performance over time or comparing across machines.
