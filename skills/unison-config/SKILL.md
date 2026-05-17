---
name: unison-config
description: Use when configuring Unison file sync, creating or editing .prf profiles, setting up sync roots, or troubleshooting profile discovery — especially when the ~/.unison/ directory doesn't exist on macOS
---

# Unison Configuration

## Overview

Unison profiles are `.prf` files. Their location is **platform-dependent** — macOS uses a different path than Linux.

## Config File Location

| Platform | Path |
|----------|------|
| **macOS** | `~/Library/Application Support/Unison/*.prf` |
| **Linux** | `~/.unison/*.prf` |

**Always check the actual location first** — if `~/.unison/` doesn't exist on macOS, `~/Library/Application Support/Unison/` is the real path.

```bash
# macOS
ls ~/Library/Application\ Support/Unison/

# Linux
ls ~/.unison/
```

## Profile File Format

```ini
# Comment
root = /local/path
root = ssh://user@host//absolute/remote/path
```

**Rules:**
- `root` appears exactly twice — local first, then remote
- Remote roots require `ssh://` prefix with `//` before the absolute path
- Profile name = filename minus `.prf` (e.g., `backup.prf` → run with `unison backup`)

## Common Preferences

| Option | Effect |
|--------|--------|
| `auto = true` | Auto-accept non-conflicting changes |
| `batch = true` | Non-interactive; aborts on conflict |
| `times = true` | Sync file modification times |
| `ignore = Name .DS_Store` | Exclude macOS metadata |
| `ignore = Name ._.*` | Exclude Apple Double files |
| `ignore = Name *.swp` | Exclude vim swap files |
| `prefer = /path` | In conflict, keep this replica's version |
| `repeat = watch` | Watch for changes and sync continuously |

## Managing Profiles

```bash
# List all profiles
unison -i

# Run a profile
unison profilename

# Dry-run (no changes)
unison profilename -batch -ui text
```

## Troubleshooting

```bash
# Find where Unison actually looks for profiles
find ~/Library -name "*.prf" 2>/dev/null

# If UNISON env var is set, it overrides the default directory
echo $UNISON
```

`unison -i` lists all discovered profiles — if your new profile doesn't appear, it's in the wrong directory.

## Common Mistakes

- **Wrong config path on macOS**: Creating `~/.unison/` when Unison is actually reading from `~/Library/Application Support/Unison/`
- **Missing `ssh://` in remote root**: `root = user@host//path` → must be `root = ssh://user@host//path`
- **Single slash in remote path**: `ssh://host/path` → must be `ssh://host//path` (double slash before absolute path)
