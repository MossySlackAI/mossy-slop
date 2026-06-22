---
name: mossy-scan
description: Deep scan of the repository. Creates or updates AGENTS.md or CLAUDE.md files.
argument-hint: "[directory]"
---

# IMPORTANT: Invoke skill `mossy-scan`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

```
- `/mossy:scan`         # same as stable
- `/mossy:scan stable`  # change as little as possible, only things that are wrong now
- `/mossy:scan update`  # allow larger changes
- `/mossy:scan rescan`  # completely overwrite previous AGENTS.md/CLAUDE.md files
```

## What it does

Scans the repository top-to-bottom and bottom-to-top. Updates or creates AGENTS.md/CLAUDE.md files in all directories.