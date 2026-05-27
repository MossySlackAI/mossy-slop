---
name: mossy-flowctl
description: Internal wrapper for flowctl.py. Provides unified interface for other mossy skills to interact with .flow/ state. Do not invoke directly.
user-invocable: false
allowed-tools: read_file,bash
---

## Quick Reference

**File Writing**: Use `mossy-flowctl write <relative-path>` to write to `.flow/<relative-path>` via write-flow-file.sh

# mossy-flowctl

This is a leaner alternative to flow-next, compatible with Mistral Vibe.

The focus is the code; code is the single source of truth, it should be able to speak for itself. Inline comments provide the documentation.

The human retains full control and responsibility. They can verify the quality of individual steps during or after processing.

It is the user's choice whether individual steps are committed to git, and whether auto-generated plan metadata gets committed or not.

When questions arise during processing, they are logged to human-readable output immediately but processing continues; open questions are asked in bulk at the end.

Speed and token conservation are valued higher than exhaustive question discovery.

## flowctl Wrapper

**Internal skill. Other mossy skills must use this for all `.flow/` operations.**

This skill wraps `flowctl.py` from flow-next. If flowctl exists in `.flow/`, use it. Otherwise, provide minimal fallback.

All operations on `.flow/` metadata are user-initiated. Auto-generated files in `.flow/` are NOT committed without explicit user action.

## Detection

Use `ensure_flow_dir` to create `.flow/` directory, then check for flowctl:

```bash
FLOW_DIR=".flow"
FLOWCTL="$FLOW_DIR/flowctl"

# Ensure flow directory exists
source ../mossy-scripts/ensure-flow-dir.sh 2>/dev/null || true
ensure_flow_dir || true

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

## Additional Commands (mossy extensions)

### File Writing

| Command | Args | Purpose |
|---------|------|---------|
| `write` | `<relative-path>` | Write stdin to `.flow/<relative-path>` using write-flow-file.sh |

## Usage Patterns for mossy Skills

### 0. Setup write-flow-file

```bash
# Source write-flow-file.sh for file operations
source ../mossy-scripts/write-flow-file.sh 2>/dev/null || true
```

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

### 5. Write file to .flow/

```bash
echo "$content" | mossy-flowctl write "specs/<id>.md"
echo "$content" | mossy-flowctl write "tasks/<id>.M.md"
```

## Fallback Behavior

If flowctl not found:
- Spec/Task files: read/write directly in `.flow/specs/` and `.flow/tasks/` using write-flow-file.sh
- State: use simple JSON files with `id`, `status`, `title`, `description` fields
- No dependency tracking
- No validation

## Implementation: write command

```bash
# In mossy-flowctl, implement write command
handle_write() {
    local target_path="$1"
    # Use write-flow-file.sh to write stdin to .flow/<target_path>
    write_flow_file "$target_path"
    return $?
}
```

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

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during flowctl operations | bash command fails, flowctl executable not found |
| validation-error | flowctl command arguments invalid | Invalid command format, missing required parameters |
| logic-error | Internal flowctl logic fails | State inconsistency, invalid JSON parsing |
| resource-error | Required resources missing | .flow/ directory not found, flowctl.py not copied |
| configuration-error | Environment misconfiguration | FLOW_DIR not set, flowctl not executable |

### Integration

```bash
# At skill start, source required utilities
source ../mossy-scripts/ensure-flow-dir.sh 2>/dev/null || true
source ../mossy-scripts/record-issue.sh 2>/dev/null || true
source ../mossy-scripts/write-flow-file.sh 2>/dev/null || true

# Setup directories
ensure_flow_dir || true

# When flowctl command fails
FLOWCTL="$FLOW_DIR/flowctl"
if [[ -x "$FLOWCTL" ]]; then
    if ! "$FLOWCTL" <command> [args] 2>/dev/null; then
        record_issue "mossy-flowctl" "tool-error" "bash" "$FLOWCTL <command>" \
            "flowctl command failed with exit code $?" \
            "Phase: flowctl wrapper, Executing $FLOWCTL <command>" || true
    fi
else
    record_issue "mossy-flowctl" "resource-error" "N/A" "$FLOWCTL" \
        "flowctl not found or not executable" \
        "Phase: detection, Checking flowctl availability" || true
fi

# When write_flow_file fails
if ! echo "$content" | write_flow_file "$target_path" 2>/dev/null; then
    record_issue "mossy-flowctl" "tool-error" "write_flow_file" "$target_path" \
        "write_flow_file failed: permission denied or path invalid" \
        "Phase: writing, Attempting to write to .flow/$target_path" || true
fi
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## Commands for Other Skills

Other mossy skills should call this via bash:

```bash
# In any mossy skill, use:
mossy-flowctl <command> [args]

# For writing files to .flow/
echo "$spec_content" | mossy-flowctl write "specs/<id>.md"
echo "$task_content" | mossy-flowctl write "tasks/<id>.M.md"
```

This skill translates to either:
1. `$FLOW_DIR/flowctl <command> [args]` (if flowctl exists and supports the command)
2. Fallback implementation using write-flow-file.sh (if not)
