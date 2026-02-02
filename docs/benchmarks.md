---
layout: page
title: Benchmarks
---

# Benchmarks

Two questions:

1. How much startup time do you save by not initializing `nvm`/`rbenv` every session?
2. What overhead do wrappers add on first use?

You can run the benchmark script on your own system:

```bash
git clone https://github.com/LuuchoRocha/lazy-wrappers.git
cd lazy-wrappers
./benchmark.sh
```

## Test hardware (sample run)

| Component | Specification |
|----------|---------------|
| CPU | AMD Ryzen 7 7730U (8 cores / 16 threads) |
| RAM | 32 GB DDR4 |
| Storage | WD Green SN350 1TB NVMe SSD |
| OS | Ubuntu 24.04 LTS |
| Shell | bash |

## Shell startup time (sample run)

| Configuration | Startup time |
|---------------|--------------|
| Baseline (no managers) | 5ms |
| lazy-wrappers | 8ms |
| Traditional rbenv | 60ms |
| Traditional nvm | 215ms |
| Traditional nvm + rbenv | ~275ms |

### Takeaway

`nvm` startup cost varies by system—anywhere from a few hundred milliseconds to well over a second.

The key: lazy-wrappers avoids paying that cost in sessions where Node/Ruby aren't used.

In this run, lazy-wrappers reduced startup time by **96%** compared to traditional `nvm` initialization.

## First-command overhead (sample run)

The first wrapped command checks state, loads the manager if needed, then runs the real binary.

| Binary | Via wrapper | Direct | Overhead |
|--------|-------------|--------|----------|
| node | 7ms | 6ms | +1ms |
| npm | 65ms | 63ms | +2ms |
| npx | 65ms | 63ms | +2ms |
| ruby | 46ms | 44ms | +2ms |
| gem | 117ms | 116ms | +1ms |
| bundle | 136ms | 134ms | +2ms |

Average first-command overhead in this run: about 1-2ms.

## Why there is no ongoing overhead

After the first manager load, a shell hook removes wrapper directories from your `PATH`. Subsequent commands execute the real binaries directly.

In practical terms:

- You save the “load managers at startup” cost on every new terminal.
- You pay a small one-time overhead when you first use Node/Ruby in that session.
- Everything after that runs normally.

## When this matters less

If you keep one long-lived terminal and always need Node/Ruby immediately, startup savings may not matter much. lazy-wrappers targets workflows with many shells, not all needing runtimes.
