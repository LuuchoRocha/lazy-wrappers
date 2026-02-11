
# 🚀 lazy-wrappers Benchmark Results

![Generated](https://img.shields.io/badge/Generated-2026--2--10-blue)

## System Information

| Property | Value |
|----------|-------|
| Shell | `/usr/bin/zsh` |
| Iterations | 100 per test |
| Date | 2026-02-10 23:27:00 |

## ⏱️ Part 1: Shell Startup Time

> How long does it take to open a new terminal?

| Configuration | Avg | Min | Max |
|:--------------|----:|----:|----:|
| ⚪ Baseline (no managers) | 32ms | 28ms | 386ms |
| 🔴 Traditional nvm | 559ms | 551ms | 571ms |
| 🟠 Traditional rbenv | 87ms | 86ms | 96ms |
| 🟢 **lazy-wrappers** | **39ms** | 39ms | 42ms |

🟢 **vs nvm:** -520ms (93% faster)
🟢 **vs rbenv:** -48ms (55% faster)

## ⚡ Part 2: First-Command Overhead

*One-time cost when wrapper triggers version manager load. Subsequent commands bypass wrappers entirely — **zero overhead**.*

| Binary | Wrapper | Direct | Overhead |
|:-------|--------:|-------:|---------:|
| `node` | 7ms | 6ms | 🟢 +1ms |
| `npm` | 65ms | 64ms | 🟢 +1ms |
| `npx` | 66ms | 64ms | 🟡 +2ms |
| `ruby` | 48ms | 47ms | 🟢 +1ms |
| `gem` | 122ms | 121ms | 🟢 +1ms |
| `bundle` | 140ms | 138ms | 🟡 +2ms |

## 📊 Part 3: Break-Even Analysis

| Metric | Value |
|:-------|------:|
| 🟢 Shell startup savings | **520ms** |
| 🟡 First-command overhead | 1ms *(one-time)* |
| 🟢 Subsequent commands | **0ms** |

**✅ Verdict:** lazy-wrappers is beneficial for virtually all workflows. After the first command, wrappers are removed from PATH and all subsequent commands run at full native speed.

## 📋 Summary

### 🟢 Pros

- ⚡ Shell starts **~520ms faster**
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

*Run `lw-benchmark` to regenerate these results on your system.*

