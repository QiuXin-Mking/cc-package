---
name: markdown-file-links
description: Convert plain-text file references in markdown documents into clickable relative-path links with line-number anchors. Use when the user mentions "make file references clickable", "convert to links", "jump to code from markdown", or after writing architecture docs that reference source files.
---

# Markdown File Links

## Overview

Convert plain-text source file references in markdown documents into clickable links that jump directly to the right line in the source file.

**Core principle:** Find the actual file → compute relative path → link with `#L<start-line>` anchor.

**Announce at start:** "I'm using the markdown-file-links skill to make file references clickable."

## Anchor Rule

Use **single-line anchors only** (`#L169`), never range anchors (`#L169-L323`).

**Why:** `#L169-L323` does not work in most editors. Only `#L169` reliably jumps.

## Step 1: Identify the Target

Confirm which markdown file to process. If not specified, ask.

```bash
# The markdown file to convert
TARGET="path/to/doc.md"
```

## Step 2: Extract All File References

Scan the markdown for these patterns:

| Pattern | Example | Captures |
|---------|---------|----------|
| Inline with lines | `file.cc:549-556` | filename, start line |
| Inline with path | `src/rgw/rgw_main.cc:100` | path, start line |
| Inline bare | `rgw_process.cc` | filename only |
| Table file column | `| ... | \`src/path/file.h\` | 75-88 |` | path, line range |
| Inline code | `` `rgw_asio_frontend.cc:229-234` `` | filename, lines |

Gather all unique (filename, start_line) pairs. Skip any that are already markdown links (`[...](...)`).

## Step 3: Locate Each File

For each referenced file, find its actual path:

```bash
find . -name "<filename>" -not -path '*/\.*' -not -path '*/build/*' 2>/dev/null
```

If multiple matches exist, prefer:
1. Matches under `src/`
2. Matches that are actual source (`.cc`, `.h`, `.py`, `.go`, `.rs`, `.ts`, etc.)
3. Closest to the markdown file's directory

If a file can't be found, warn and skip it.

## Step 4: Compute Relative Paths

From the markdown file's directory, compute `realpath --relative-to`:

```bash
realpath --relative-to="$(dirname "<markdown-path>")" "<found-source-path>"
```

Example:
- Markdown: `docs/architecture.md`
- Source: `src/rgw/rgw_main.cc`
- Result: `../src/rgw/rgw_main.cc`

## Step 5: Build Links and Replace

### Inline references

```
BEFORE: 1. 初始化 (rgw_main.cc:549-556)
AFTER:  1. 初始化 ([rgw_main.cc:549-556](../src/rgw/rgw_main.cc#L549))
```

Display text keeps the original `file:range`; URL uses single-line anchor.

### Table references

Merge the file column into a link, keep the line-number column as display text:

```
BEFORE: | `RGWFrontend` | `src/rgw/rgw_frontend.h` | 75-88 | 职责描述 |
AFTER:  | `RGWFrontend` | [`src/rgw/rgw_frontend.h`](../src/rgw/rgw_frontend.h#L75) | 75-88 | 职责描述 |
```

### Bare file references (no line number)

```
BEFORE: | IO 过滤器定义 | `src/rgw/rgw_client_io_filters.h` | — |
AFTER:  | IO 过滤器定义 | [`src/rgw/rgw_client_io_filters.h`](../src/rgw/rgw_client_io_filters.h) | — |
```

No `#L` anchor when there's no line number.

### Already-linked references

Skip any reference that is already inside `[...](...)` markdown link syntax.

## Step 6: Verify

After all replacements, verify no broken patterns remain:

```bash
# Check no #L range anchors exist (should be 0)
grep -nE '#L[0-9]+-[0-9]+' "$TARGET"

# Check all referenced files exist
# For each link, extract the path and test -f
```

Report:
- Number of references converted
- Any files that couldn't be found
- Any references that were already links (skipped)

## Edge Cases

- **Same filename, different directories**: Use `find` and pick the best match. Warn if ambiguous.
- **File not found**: Skip, report at the end.
- **No line number**: Link to file only, no `#L` anchor.
- **Nested code blocks**: Only process references outside fenced code blocks (```).
- **Relative paths already in the markdown**: Still convert them to links if they aren't already.

## Quick Reference

| Input | Output |
|-------|--------|
| `file.cc:100-200` | `[file.cc:100-200](../src/pkg/file.cc#L100)` |
| `src/pkg/file.h:50` | `[src/pkg/file.h:50](../src/pkg/file.h#L50)` |
| `` `src/pkg/file.cc` `` in table | `` [`src/pkg/file.cc`](../src/pkg/file.cc) `` |
| `[file.cc:100](../src/file.cc#L100)` | Already linked — skip |

## Red Flags

**Never:**
- Use range anchors (`#L100-L200`) — they don't work
- Link to files that don't exist
- Modify references inside fenced code blocks
- Double-link already-linked references

**Always:**
- Use relative paths from the markdown file's location
- Use single-line anchors (`#L100`)
- Verify every link target exists
- Keep the original display text (e.g., `file.cc:100-200`) in the link text
