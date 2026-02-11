---
layout: default
title: Dev Docs
---

# Developer documentation

Internal technical documentation for contributors and maintainers of lazy-wrappers.

These pages explain the internals—how the system is assembled, what each script does, and why certain decisions were made. If you're looking for usage instructions, see [How it works](../how-it-works) instead.

## Contents

| Document | Description |
|----------|-------------|
| [Architecture](architecture) | System design, component relationships, data flow |
| [Lifecycle](lifecycle) | End-to-end walkthrough from install to steady-state |
| [generate_wrappers](generate-wrappers) | Wrapper generation: templates, placeholders, edge cases |
| [shell_hook](shell-hook) | Post-command hook: IPC via flag files, PATH cleanup, parent shell reloading |
| [Loaders (nvmload & rbenvload)](loaders) | Lazy loaders: auto-install, initialization, completion, cross-shell compat |
| [Static wrappers (nvm & rbenv)](static-wrappers) | Hand-crafted wrappers and why they differ from generated ones |
| [Gotchas](gotchas) | Common pitfalls, tricky behaviors, and debugging tips |
