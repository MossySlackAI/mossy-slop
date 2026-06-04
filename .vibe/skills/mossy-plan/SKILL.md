---
name: mossy-plan
description: Create execution plan from spec. Breaks work into ordered tasks with clear acceptance criteria.
user-invocable: false
allowed-tools: read_file,grep,bash,ask_user_question
---

# mossy-plan

This is a leaner alternative to flow-next, compatible with Mistral Vibe.

The focus is the code; code is the single source of truth, it should be able to speak for itself. Inline comments provide the documentation.

The human retains full control and responsibility. They can verify the quality of individual steps during or after processing.

It is the user's choice whether individual steps are committed to git, and whether auto-generated plan metadata gets committed or not.

When questions arise during processing, they are logged to human-readable output immediately but processing continues; open questions are asked in bulk at the end.

Speed and token conservation are valued higher than exhaustive question discovery.

## Plan

Create an execution plan from a spec.

## Input

$ARGUMENTS

Accepts:
- Spec ID: `fn-1-add-auth` or legacy `fn-1`
- File path: `specs/add-auth.md` (creates spec first)
- Idea text: `Add OAuth2 support` (creates minimal spec + tasks)

## Flow

0. **Load config**
   - Call scripts: `ensure-flow-dir.sh`, `load-mossy-config.sh`, `record-issue.sh`
   - Use `mossy-flowctl` for all `.flow/` file operations
   - Call `../mossy-scripts/ensure-flow-dir.sh` to create directories
   - Call `../mossy-scripts/load-mossy-config.sh <config-item>` to parse commit policy settings (returns individual values)
   - Settings: commit-policy, new-branch-per-spec, auto-push, co-authored-by
   - R3 defaults applied automatically

1. **Parse input**
   - If ID: read `.flow/specs/<id>.md`
   - If path: read file, extract title, create spec
   - If text: create minimal spec with goal = text

2. **Extract requirements and config**
   - Split spec into acceptance criteria (R-IDs)
   - Number them sequentially: R1, R2, R3...
   - **Read Mossy-Config section from spec if present, override global config**
   - Log questions immediately but continue processing; ask in bulk at end (header max: 11 chars)

3. **Break into tasks**
   - Each task implements 1+N requirements
   - Order by dependency (infrastructure first, UI last)
   - ID format: `<spec-id>.M` (fn-1.1, fn-1.2...)
   - Speed and token conservation > exhaustive question discovery

4. **Write artifacts**
   - Spec file: Use `echo "$content" | mossy-flowctl write "specs/<id>.md"` for `.flow/specs/<id>.md` with R-IDs and Mossy-Config section
   - Task files: Use `echo "$content" | mossy-flowctl write "tasks/<id>.M.md"` for `.flow/tasks/<id>.M.md` per task
   - Summary: Use `echo "$content" | mossy-flowctl write "specs/<id>-plan.md"` for `.flow/specs/<id>-plan.md` with dependency graph
   - **Commit behavior**: Respect commit-policy from config (default: manual, no auto-commit)

## Spec Format

```markdown
# <Title>

## Goal
<1 sentence>

## Acceptance Criteria
- R1: <criterion>
- R2: <criterion>
...

## Tasks
- fn-<N>.1: <description>
- fn-<N>.2: <description>
...

## Dependencies
- fn-<N>.2 depends on fn-<N>.1
```

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

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during spec parsing | mossy-flowctl write on non-writable .flow/ |
| validation-error | Spec format doesn't match expected schema | Missing Goal section, invalid task IDs |
| logic-error | Internal planning logic fails | Circular dependency detection, invalid task ordering |
| resource-error | Required resources missing | .flow/specs/ directory not found |
| configuration-error | Environment misconfiguration | flowctl.py missing but referenced |

### Integration

```bash
# At skill start, call required utilities
../mossy-scripts/ensure-flow-dir.sh >/dev/null 2>&1 || true
COMMIT_POLICY=$(/../mossy-scripts/load-mossy-config.sh COMMIT_POLICY 2>/dev/null) || true
NEW_BRANCH_PER_SPEC=$(/../mossy-scripts/load-mossy-config.sh NEW_BRANCH_PER_SPEC 2>/dev/null) || true
AUTO_PUSH=$(/../mossy-scripts/load-mossy-config.sh AUTO_PUSH 2>/dev/null) || true
CO_AUTHORED_BY=$(/../mossy-scripts/load-mossy-config.sh CO_AUTHORED_BY 2>/dev/null) || true

# When a tool fails during spec parsing
if ! read_file path="$spec_path" 2>/dev/null; then
    ../mossy-scripts/record-issue.sh --skill "mossy-plan" --error-type "tool-error" \
        --tool "read_file" --target "$spec_path" \
        --error "read_file failed: file not found or permission denied" \
        --context "Phase: parsing, Attempting to read spec file $spec_path" || true
fi

# When mossy-flowctl write fails during artifact writing
if ! echo "$content" | mossy-flowctl write "$flow_path" 2>/dev/null; then
    ../mossy-scripts/record-issue.sh --skill "mossy-plan" --error-type "tool-error" \
        --tool "mossy-flowctl write" --target "$flow_path" \
        --error "mossy-flowctl write failed: permission denied or path invalid" \
        --context "Phase: writing, Attempting to write to $flow_path" || true
fi

# When spec format is invalid
if ! grep -q "## Goal" "$spec_path"; then
    ../mossy-scripts/record-issue.sh --skill "mossy-plan" --error-type "validation-error" \
        --tool "N/A" --target "$spec_path" \
        --error "Invalid spec format: missing Goal section" \
        --context "Phase: parsing, Validating spec structure" || true
fi
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## Guardrails

- **IMPORTANT**: Always read local AGENTS.md in the subdirectories you are investigating.
- Never use markdown TODOs
- Never use TodoWrite
- All state in `.flow/`
- Task IDs immutable once created
- R-IDs frozen at plan time
