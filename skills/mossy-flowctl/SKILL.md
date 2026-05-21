---
name: mossy-flowctl
description: Internal wrapper for flowctl.py. Provides unified interface for other mossy skills to interact with .flow/ state. Do not invoke directly.
user-invocable: false
allowed-tools: read_file,bash
---

# flowctl Wrapper

**Internal skill. Other mossy skills must use this for all .flow/ operations.**

This skill wraps `flowctl.py` from flow-next. If flowctl exists in `.flow/`, use it. Otherwise, provide minimal fallback.

## Detection

```bash
FLOW_DIR=".flow"
FLOWCTL="$FLOW_DIR/flowctl"

# Check for executable flowctl (flow-next copies it here)
if [[ -x "$FLOWCTL" && -f "$FLOWCTL" ]]; then
  FLOWCTL_FOUND=1
fi
```

## flowctl Commands Reference

All commands support `--json` for machine-readable output.

### Spec Management

| Command | Args | Purpose |
|---------|------|---------|
| `spec create` | `--title <t> [--id <id>]` | Create spec skeleton |
| `spec set-plan` | `<id> --file <path>` | Set plan from markdown |
| `spec set-title` | `<id> <title>` | Update spec title |
| `spec set-branch` | `<id> <branch>` | Set target branch |
| `spec close` | `<id>` | Mark spec complete |
| `specs` | | List all specs |

### Task Management

| Command | Args | Purpose |
|---------|------|---------|
| `task create` | `--spec <id> --title <t> [--acceptance <r-ids>]` | Create task |
| `task set-description` | `<id> <desc>` | Update description |
| `task set-acceptance` | `<id> <r-ids>` | Set acceptance criteria |
| `task set-deps` | `<id> <dep-ids>` | Set dependencies |
| `start` | `<task-id>` | Claim task for work |
| `done` | `<task-id> --summary-file <path> [--evidence-json <path>]` | Mark complete |
| `reset` | `<task-id>` | Reset task state |
| `tasks` | `[--spec <id>]` | List tasks |
| `ready` | `[--spec <id>]` | List ready tasks |

### State Queries

| Command | Args | Purpose |
|---------|------|---------|
| `list` | | List all specs + tasks |
| `show` | `<id>` | Show spec or task details |
| `status` | | Show .flow/ state |
| `detect` | | Check if .flow/ exists |

### Config

| Command | Args | Purpose |
|---------|------|---------|
| `config get` | `<key>` | Get config value |
| `config set` | `<key> <value>` | Set config value |
| `review-backend` | | Get configured review backend |

## Usage Patterns for mossy Skills

### 1. Check flowctl availability

```bash
if ! mossy-flowctl --detect; then
  # Fallback to direct file operations
fi
```

### 2. Create spec

```bash
mossy-flowctl spec create --title "Add OAuth2" --id fn-1
```

### 3. List ready tasks

```bash
mossy-flowctl ready --json
```

### 4. Mark task done

```bash
mossy-flowctl done fn-1.1 --summary-file /tmp/summary.md
```

## Fallback Behavior

If flowctl not found:
- Spec/Task files: read/write directly in `.flow/specs/` and `.flow/tasks/`
- State: use simple JSON files with `id`, `status`, `title`, `description` fields
- No dependency tracking
- No validation

## File Layout

When flowctl exists, it manages:
```
.flow/
├── .flow_version       # Sentinel for post-1.0 layout
├── config.json        # Configuration
├── meta.json          # Metadata
├── specs/             # Spec definitions (JSON + markdown)
│   └── fn-1.json
├── tasks/             # Task definitions
│   └── fn-1.1.json
└── flowctl            # Executable script
```

## Implementation Notes

- Always prefer flowctl when available
- Parse `--json` output with `jq` or Python json module
- Handle exit codes: 0 = success, 1 = error, 2 = not found
- Never write to flowctl or flowctl.py files
- flowctl.py source: `../flow-next/plugins/flow-next/scripts/flowctl.py` (MIT)

## Commands for Other Skills

Other mossy skills should call this via bash:

```bash
# In any mossy skill, use:
mossy-flowctl <command> [args]
```

This skill translates to either:
1. `$FLOW_DIR/flowctl <command> [args]` (if flowctl exists)
2. Fallback implementation (if not)
