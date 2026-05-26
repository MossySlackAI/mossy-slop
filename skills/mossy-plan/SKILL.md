---
name: mossy-plan
description: Create execution plan from spec. Breaks work into ordered tasks with clear acceptance criteria.
user-invocable: true
allowed-tools: read_file,write_file,grep,bash,ask_user_question
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
   - Source scripts: `ensure-flow-dir.sh`, `load-mossy-config.sh`, `record-issue.sh`
   - Call `ensure_flow_dir` to create directories
   - Call `load_mossy_config` to parse commit policy settings
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
   - Log questions immediately but continue processing; ask in bulk at end

3. **Break into tasks**
   - Each task implements 1+N requirements
   - Order by dependency (infrastructure first, UI last)
   - ID format: `<spec-id>.M` (fn-1.1, fn-1.2...)
   - Speed and token conservation > exhaustive question discovery

4. **Write artifacts**
   - Spec file: `.flow/specs/<id>.md` with R-IDs and Mossy-Config section
   - Task files: `.flow/tasks/<id>.M.md` per task
   - Summary: `.flow/specs/<id>-plan.md` with dependency graph
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
| tool-error | Vibe tool calls fail during spec parsing | read_file on non-existent spec file |
| validation-error | Spec format doesn't match expected schema | Missing Goal section, invalid task IDs |
| logic-error | Internal planning logic fails | Circular dependency detection, invalid task ordering |
| resource-error | Required resources missing | .flow/specs/ directory not found |
| configuration-error | Environment misconfiguration | flowctl.py missing but referenced |

### Integration

```bash
# At skill start, source required utilities
source ../mossy-scripts/ensure-flow-dir.sh 2>/dev/null || true
source ../mossy-scripts/load-mossy-config.sh 2>/dev/null || true
source ../mossy-scripts/record-issue.sh 2>/dev/null || true

# Setup and load config
ensure_flow_dir || true
load_mossy_config || true

# When a tool fails during spec parsing
if ! read_file path="$spec_path" 2>/dev/null; then
    record_issue "mossy-plan" "tool-error" "read_file" "$spec_path" \
        "read_file failed: file not found or permission denied" \
        "Phase: parsing, Attempting to read spec file $spec_path" || true
fi

# When spec format is invalid
if ! grep -q "## Goal" "$spec_path"; then
    record_issue "mossy-plan" "validation-error" "N/A" "$spec_path" \
        "Invalid spec format: missing Goal section" \
        "Phase: parsing, Validating spec structure" || true
fi
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## Guardrails

- Never use markdown TODOs
- Never use TodoWrite
- All state in `.flow/`
- Task IDs immutable once created
- R-IDs frozen at plan time
