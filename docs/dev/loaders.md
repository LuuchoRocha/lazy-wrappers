---
layout: default
title: Loaders
---

# nvmload and rbenvload

> Sources: `scripts/nvmload`, `scripts/rbenvload`

These scripts are the actual version manager initializers. They:

1. Auto-install the version manager (clone from GitHub) if it is not present.
2. Initialize / source the manager.
3. Set up shell completions.
4. Mark the manager as loaded (env var + flag file).

They are called from two contexts:

- **From generated wrappers** — when a wrapped binary is invoked for the first time.
- **From static wrappers** — when `nvm` or `rbenv` themselves are called.

## Common patterns

### Early exit guard

```bash
if [[ -n "$NVM_ALREADY_LOADED" ]]; then
    return 0 2>/dev/null || exit 0
fi
```

The `return || exit` pattern handles both execution contexts:

- `return 0` works when the script is **sourced** (`. nvmload`).
- `exit 0` works when the script is **executed** (`./nvmload`).
- `2>/dev/null` suppresses the "return: can only return from a function" error when executed directly.

### Flag file creation

```bash
if [[ -n "${_LW_FLAGS_DIR:-}" ]]; then
    touch "$_LW_FLAGS_DIR/nvm_loaded" 2>/dev/null || true
fi
```

This is the IPC mechanism to communicate with `shell-hook`. The `|| true` ensures the script does not fail if the flags directory does not exist (e.g., when running outside the lazy-wrappers context).

---

## nvmload

### Flow

```
nvmload
  ├── NVM_ALREADY_LOADED set? → return early
  ├── Set NVM_DIR (default: ~/.nvm)
  ├── git available? → error if not
  ├── ~/.nvm exists?
  │   ├── No → git clone nvm → checkout latest tag (or default branch)
  │   └── Yes → skip
  ├── Source nvm.sh
  ├── Load bash_completion (zsh: autoload bashcompinit first)
  ├── Set NVM_ALREADY_LOADED=1
  └── Touch flag file
```

### Auto-install logic

```bash
if [[ ! -d "$NVM_DIR" ]]; then
    git clone --quiet https://github.com/nvm-sh/nvm.git "$NVM_DIR"

    latest_tag=$(cd "$NVM_DIR" && git describe --abbrev=0 --tags 2>/dev/null || echo "")
    if [[ -n "$latest_tag" ]]; then
        (cd "$NVM_DIR" && git checkout --quiet "$latest_tag")
    else
        (cd "$NVM_DIR" && git checkout --quiet main 2>/dev/null \
            || git checkout --quiet master 2>/dev/null)
    fi
fi
```

Key details:

- Uses `git describe --abbrev=0 --tags` to find the latest tag (e.g., `v0.40.1`).
- Falls back to `main` or `master` if no tags exist.
- `--quiet` suppresses git output.
- Git operations run in subshells `(cd ...)` to avoid changing the working directory.

### zsh completion compatibility

```bash
if [[ -n "${ZSH_VERSION:-}" ]] && ! type complete >/dev/null 2>&1; then
    autoload -Uz bashcompinit 2>/dev/null || true
    bashcompinit 2>/dev/null || true
fi
```

nvm's completion script uses bash's `complete` builtin. zsh does not have this by default, so `bashcompinit` is loaded to provide bash-compatible completion.

---

## rbenvload

### Flow

```
rbenvload
  ├── RBENV_ALREADY_LOADED set? → return early
  ├── Set RBENV_DIR (default: ~/.rbenv)
  ├── git available? → error if not
  ├── ~/.rbenv exists?
  │   ├── No → git clone rbenv → mkdir plugins/ → git clone ruby-build
  │   └── Yes → skip
  ├── rbenv init (shell-aware)
  │   ├── zsh  → eval "$(rbenv init - zsh)"
  │   ├── bash → eval "$(rbenv init - bash)"
  │   └── other → eval "$(rbenv init - bash)"
  ├── zsh completion setup (fpath, _rbenv, compdef)
  ├── Set RBENV_ALREADY_LOADED=1
  └── Touch flag file
```

### Auto-install logic

```bash
if [[ ! -d "$RBENV_DIR" ]]; then
    git clone --quiet https://github.com/rbenv/rbenv.git "$RBENV_DIR"
    mkdir -p "$RBENV_DIR/plugins"
    if [[ ! -d "$RBENV_DIR/plugins/ruby-build" ]]; then
        git clone --quiet https://github.com/rbenv/ruby-build.git \
            "$RBENV_DIR/plugins/ruby-build"
    fi
fi
```

Unlike nvm, rbenv also needs the **ruby-build** plugin to be useful (it provides `rbenv install`). The loader clones both.

### Shell-aware initialization

```bash
if [[ -n "${ZSH_VERSION:-}" ]]; then
    eval "$("$RBENV_DIR/bin/rbenv" init - zsh)"
elif [[ -n "${BASH_VERSION:-}" ]]; then
    eval "$("$RBENV_DIR/bin/rbenv" init - bash)"
else
    eval "$("$RBENV_DIR/bin/rbenv" init - bash)"
fi
```

`rbenv init -` generates shell-specific initialization code. Passing the shell name controls the output format—important because zsh and bash have different completion systems.

### zsh completion — fpath management

```bash
if [[ -d "$RBENV_DIR/completions" ]]; then
    # Check if already in fpath
    __lazy_wrappers_has_rbenv_completion_path=0
    for __path in "${fpath[@]}"; do
        [[ "$__path" == "$RBENV_DIR/completions" ]] && \
            __lazy_wrappers_has_rbenv_completion_path=1 && break
    done
    # Prepend if missing
    if [[ "$__lazy_wrappers_has_rbenv_completion_path" -eq 0 ]]; then
        fpath=("$RBENV_DIR/completions" "${fpath[@]}")
    fi
    autoload -Uz _rbenv 2>/dev/null || true
    type compdef >/dev/null 2>&1 && compdef _rbenv rbenv 2>/dev/null || true
    unset __lazy_wrappers_has_rbenv_completion_path __path
fi
```

This prevents `fpath` from growing if the loader runs multiple times. Temporary variables are cleaned up with `unset`.

---

## Error handling comparison

| Scenario                      | nvmload                     | rbenvload                |
| ----------------------------- | --------------------------- | ------------------------ |
| Already loaded                | `return 0` early            | `return 0` early         |
| git not available             | Error + `return 1`          | Error + `return 1`       |
| Clone fails                   | Error + `return 1`          | Error + `return 1`       |
| Tag checkout fails            | Warning, use default branch | N/A (no tag checkout)    |
| ruby-build clone fails        | N/A                         | Warning only (non-fatal) |
| nvm.sh / rbenv binary missing | Error + `return 1`          | Error + `return 1`       |
| Flag file write fails         | Silent (non-critical)       | Silent (non-critical)    |

## Environment variables

| Variable               | Set by                | Used by               | Purpose                        |
| ---------------------- | --------------------- | --------------------- | ------------------------------ |
| `NVM_DIR`              | User or nvmload       | nvmload, shell_hook   | nvm installation directory     |
| `NVM_ALREADY_LOADED`   | nvmload, shell_hook   | nvmload, shell_hook   | Prevents redundant loading     |
| `RBENV_DIR`            | User or rbenvload     | rbenvload, shell_hook | rbenv installation directory   |
| `RBENV_ALREADY_LOADED` | rbenvload, shell_hook | rbenvload, shell_hook | Prevents redundant loading     |
| `_LW_FLAGS_DIR`        | shell_hook            | nvmload, rbenvload    | Path to per-session flag files |
