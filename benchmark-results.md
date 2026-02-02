
# 🚀 lazy-wrappers Benchmark Results

![Generated](https://img.shields.io/badge/Generated-2026--2--2-blue)

## System Information

| Property | Value |
|----------|-------|
| Shell | `/usr/bin/bash` |
| Iterations | 1000 per test |
| Date | 2026-02-02 18:01:53 |

## ⏱️ Part 1: Shell Startup Time

> How long does it take to open a new terminal?

| Configuration | Avg | Min | Max |
|:--------------|----:|----:|----:|
| ⚪ Baseline (no managers) | 6ms | 5ms | 8ms |
| 🔴 Traditional nvm | 245ms | 237ms | 254ms |
| 🟠 Traditional rbenv | 67ms | 63ms | 101ms |
| 🟢 **lazy-wrappers** | **9ms** | 9ms | 13ms |

🟢 **vs nvm:** -236ms (96% faster)
🟢 **vs rbenv:** -58ms (86% faster)

## ⚡ Part 2: First-Command Overhead

*One-time cost when wrapper triggers version manager load. Subsequent commands bypass wrappers entirely — **zero overhead**.*

| Binary | Wrapper | Direct | Overhead |
|:-------|--------:|-------:|---------:|
| `node` | 8ms | 7ms | 🟢 +1ms |
| `npm` | 65ms | 64ms | 🟢 +1ms |
| `npx` | 66ms | 65ms | 🟢 +1ms |
| `ruby` | 50ms | 49ms | 🟢 +1ms |
| `gem` | 121ms | 120ms | 🟢 +1ms |
| `bundle` | 139ms | 138ms | 🟢 +1ms |

## 📊 Part 3: Break-Even Analysis

| Metric | Value |
|:-------|------:|
| 🟢 Shell startup savings | **236ms** |
| 🟡 First-command overhead | 1ms *(one-time)* |
| 🟢 Subsequent commands | **0ms** |

**✅ Verdict:** lazy-wrappers is beneficial for virtually all workflows. After the first command, wrappers are removed from PATH and all subsequent commands run at full native speed.

## 📋 Summary

### 🟢 Pros

- ⚡ Shell starts **~236ms faster**
- 💤 Version managers load only when needed
- 🪟 Multiple terminals don't each pay startup cost

### 🟡 Cons

- First command in session triggers version manager load
- ~1ms one-time overhead on that first command

### 🎯 Best For

- Opening many terminal sessions
- Quick shell commands before using node/ruby
- Development with moderate node/ruby usage

---

*Run `./benchmark.sh` to regenerate these results on your system.*

