---
layout: default
title: generate_wrappers
---

# generate_wrappers

> Source: `scripts/generate_wrappers`

Reads `wrappers.conf` and generates a wrapper shell script for every listed binary. Each wrapper, when invoked, lazy-loads the appropriate version manager and then `exec`s the real binary.

## Key design decisions

### Heredoc with quoted delimiter

```bash
cat > "$wrapper_path" << 'WRAPPER_EOF'
...template with __BINARY__ placeholders...
WRAPPER_EOF
```

The single-quoted `'WRAPPER_EOF'` **prevents all variable expansion** inside the heredoc. This is critical because the template contains `$PATH`, `$@`, `"${...}"`, etc. that must appear literally in the output script—not expanded during generation.

### Placeholder replacement via sed

```bash
sed -e "s|__BINARY__|$binary_name|g" \
    -e "s|__NODE_WRAPPERS__|$NODE_WRAPPERS_DIR|g" \
    -e "s|__SCRIPTS__|$SCRIPT_DIR|g" \
    "$wrapper_path" > "$wrapper_path.tmp" && mv "$wrapper_path.tmp" "$wrapper_path"
```

- Uses `|` as the sed delimiter (not `/`) to avoid conflicts with file paths.
- Writes to a `.tmp` file then `mv`s it back — this is the cross-platform alternative to `sed -i`, which behaves differently on macOS vs Linux.
- Three placeholders are replaced:

| Placeholder | Replaced with | Purpose |
|-------------|--------------|---------|
| `__BINARY__` | The binary name (e.g., `node`) | Error messages, `command -v` checks, recursion guard, `exec` |
| `__NODE_WRAPPERS__` / `__RUBY_WRAPPERS__` | Absolute path to wrapper directory | Removing the directory from PATH |
| `__SCRIPTS__` | Absolute path to scripts directory | Sourcing `nvmload` / `rbenvload` |

### Static wrapper exclusion

```bash
STATIC_WRAPPERS=("nvm" "rbenv")
```

`nvm` and `rbenv` themselves need special handling:
- `nvm` is a shell **function**, not a binary — you cannot `exec` it.
- `rbenv` needs `rbenv init` which sets up shims and completions.

These have hand-crafted wrappers in the repo. The generator skips them to avoid overwriting. See [Static wrappers](static-wrappers) for details.

## Generated wrapper template

Here is the nvm template with placeholders replaced for `node`:

```bash
#!/bin/bash
# Lazy wrapper for node

# Prevent infinite recursion
if [[ -n "${__LAZY_WRAPPERS_LOADING_node:-}" ]]; then
    echo "Error: wrapper recursion detected for node" >&2
    exit 1
fi
export __LAZY_WRAPPERS_LOADING_node=1

# Remove ALL occurrences of wrapper directory from PATH
WRAPPER_DIR="/home/user/.lazy-wrappers/scripts/bin/node_wrappers"
PATH=":$PATH:"
while [[ "$PATH" == *":$WRAPPER_DIR:"* ]]; do
    PATH="${PATH//:$WRAPPER_DIR:/:}"
done
PATH="${PATH#:}"
PATH="${PATH%:}"
export PATH

# Load nvm if binary not found in PATH
if ! command -v node &>/dev/null; then
    . "/home/user/.lazy-wrappers/scripts/nvmload" 2>/dev/null || true
fi

# Find and exec the real binary
if command -v node &>/dev/null; then
    exec node "$@"
else
    echo "Error: node not found. Is node installed?" >&2
    exit 1
fi
```

The rbenv template is identical in structure; only the directory and loader differ.

## PATH removal logic — line by line

This is the trickiest part of the wrapper:

```bash
WRAPPER_DIR="/home/user/.lazy-wrappers/scripts/bin/node_wrappers"
PATH=":$PATH:"                                    # (1)
while [[ "$PATH" == *":$WRAPPER_DIR:"* ]]; do     # (2)
    PATH="${PATH//:$WRAPPER_DIR:/:}"               # (3)
done
PATH="${PATH#:}"                                   # (4)
PATH="${PATH%:}"                                   # (5)
export PATH
```

1. **Pad PATH with colons.** Every entry is now surrounded by `:`, making pattern matching uniform. Without this, the first and last entries lack surrounding colons.
2. **While loop.** Handles the case where the wrapper directory appears multiple times (e.g., RC file sourced twice).
3. **Bash parameter substitution** `${PATH//:$DIR:/:}` replaces `:dir:` with `:`, removing one occurrence per iteration.
4. **Strip leading colon** added in step 1.
5. **Strip trailing colon** added in step 1.

A single substitution is not enough because the entry might appear multiple times. The while loop guarantees all occurrences are removed.

## Recursion guard

```bash
if [[ -n "${__LAZY_WRAPPERS_LOADING_node:-}" ]]; then
    echo "Error: wrapper recursion detected for node" >&2
    exit 1
fi
export __LAZY_WRAPPERS_LOADING_node=1
```

Prevents infinite loops if PATH removal fails, the wrapper calls itself, or the loader triggers the same binary. The env var name is binary-specific (`__LAZY_WRAPPERS_LOADING_node`) to avoid collisions.

## wrappers.conf format

```
# Comments start with #
binary_name:loader
```

- **binary\_name** — the command to wrap (e.g., `node`, `prettier`)
- **loader** — `nvm` or `rbenv`
- Parsed with `IFS=:` in a `while read` loop
- Whitespace is trimmed with `xargs`
- Duplicate entries are allowed (the file is overwritten, so last write wins)

### Note on duplicates

The current `wrappers.conf` has a few duplicates (`prettier`, `rubocop`, `eslint`). These are harmless but could be cleaned up.

## Error handling

- Counts generated wrappers and errors separately.
- Exits with error if no wrappers were generated at all.
- Warns on unknown loader types.
- Validates that binary names are not empty.
- Reports failures to set executable permissions.
