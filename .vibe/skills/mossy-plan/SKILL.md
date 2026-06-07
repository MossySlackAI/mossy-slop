---
name: mossy-plan
description: Create execution plan from spec. Breaks work into ordered tasks with clear acceptance criteria.
user-invocable: false
allowed-tools: read_file,grep,bash,ask_user_question
---

# mossy-plan

The focus is the code; code is the single source of truth, it should be able to speak for itself. Inline comments provide the documentation.

The human retains full control and responsibility. They can verify the quality of individual steps during or after processing.

## Plan

Create an execution plan from a spec.

## Input

$ARGUMENTS

Accepts:
- Spec ID: `fn-1-add-auth` or legacy `fn-1`

## Flow

0. **Load config**
   - Use `flowctl.sh` for all `.flow/` file operations

1. **Parse input**
   - If ID: read `.flow/specs/<id>.md`

2. **Extract requirements and config**
   - Split spec into acceptance criteria (checkbox format: `- [ ] criterion`)
   - Number them sequentially for internal tracking: AC1, AC2, AC3...

3. **Break into tasks**
   - Each task implements 1+N requirements
   - Order by dependency (infrastructure first, UI last)
   - ID format: `<spec-id>.M` (fn-1.1, fn-1.2...)

4. **Write artifacts**
   - Task files: Use `flowctl.sh task create --spec <spec-id> --title <title>` to create task, then `flowctl.sh task set-spec --file - <task-id>` to set task content
   - **Dependency tracking**: Use `flowctl.sh task set-deps --deps <dep-list> <task-id>` to set task dependencies

## Spec Format

Specs use **flowctl canonical skeleton format** (call `flowctl.sh spec skeleton` to review it).

**Note**: Tasks are stored in flowctl task system, not in spec file.

## Task Format

```markdown
---
task_id: fn-<N>.M
spec_id: fn-<N>
status: pending
description: <what to do>
acceptance: R1, R2
depends_on: fn-<N>.(M-1)
---

## Implementation Notes
- File paths to modify
- Key functions/classes to create
- Tests required
```

## Commands

After plan creation, user can:
- `/mossy:work <spec-id>` - Execute all tasks
- `/mossy:work <task-id>` - Execute single task
- `/mossy:plan --list` - List all specs
- `/mossy:plan --show <id>` - Show spec + tasks

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](mossy-scripts/ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during artifact writing | flowctl.sh spec set-plan or task create/set-spec fails |
| validation-error | Spec format doesn't match expected schema | Missing Overview section, invalid task IDs |
| logic-error | Internal planning logic fails | Circular dependency detection, invalid task ordering |
| resource-error | Required resources missing | .flow/specs/ directory not found |
| configuration-error | Environment misconfiguration | flowctl.sh not found |

### Integration

```bash
# At skill start, call required utilities
ensure-flow-dir.sh >/dev/null 2>&1 || true

# When a tool fails during spec parsing
if ! read_file path="$spec_path" 2>/dev/null; then
    record-issue.sh --skill "mossy-plan" --error-type "tool-error" \
        --tool "read_file" --target "$spec_path" \
        --error "read_file failed: file not found or permission denied" \
        --context "Phase: parsing, Attempting to read spec file $spec_path" || true
fi
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## GUARDRAILS

- **CRITICAL: NO actual work. ONLY output: task files in `.flow/tasks/<id>.md`**
- **IMPORTANT**: Always read local AGENTS.md in the subdirectories you are investigating.
- **Do NOT create plans in ~/.vibe/plans **
