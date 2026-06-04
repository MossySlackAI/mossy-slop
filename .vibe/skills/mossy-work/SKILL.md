---
name: mossy-work
description: Execute plan tasks. Claims tasks from ready queue, performs implementation, and marks complete with evidence.
user-invocable: false
allowed-tools: read_file,write_file,search_replace,grep,bash,ask_user_question,task
---

# mossy-work

This is a leaner alternative to flow-next, compatible with Mistral Vibe.

The focus is the code; code is the single source of truth, it should be able to speak for itself. Inline comments provide the documentation.

The human retains full control and responsibility. They can verify the quality of individual steps during or after processing.

It is the user's choice whether individual steps are committed to git, and whether auto-generated plan metadata gets committed or not.

When questions arise during processing, they are logged to human-readable output immediately but processing continues; open questions are asked in bulk at the end.

Speed and token conservation are valued higher than exhaustive question discovery.

## Execute

Claim and execute tasks from the ready queue.

## Input

$ARGUMENTS

Accepts:
- Task ID: `fn-1.1` - Execute specific task
- Spec ID: `fn-1` - Execute all ready tasks for spec
- `--next` - Execute next ready task across all specs
- `--list` - List ready tasks
- `--show <id>` - Show task details

## Flow

0. **Load config**
   - Call scripts: `ensure-flow-dir.sh`, `load-mossy-config.sh`, `record-issue.sh`
   - Call `../mossy-scripts/ensure-flow-dir.sh` to create directories
   - Call `../mossy-scripts/load-mossy-config.sh <config-item>` to parse commit policy settings (returns individual values)
   - Settings: commit-policy, new-branch-per-spec, auto-push, co-authored-by
   - R3 defaults applied automatically

1. **Resolve target**
   - If task ID: execute that task
   - If spec ID: find ready tasks for that spec, execute in order
   - If `--next`: find first ready task across all specs
   - If `--list`: show ready tasks and exit
   - If `--show <id>`: display task details and exit

2. **Claim task**
   - Use `mossy-flowctl start <task-id>` or fallback
   - Verify claim succeeded
   - Load task metadata: description, acceptance criteria, dependencies
   - **Read spec's Mossy-Config section and override global config**

3. **Prepare workspace**
   - Create working directory: `.flow/work/<task-id>/`
   - Write task context to `.flow/work/<task-id>/context.md`
   - Initialize summary file: `.flow/work/<task-id>/summary.md`

4. **Execute task**
   - Parse task description for file paths and actions
   - Use appropriate tools (search_replace, write_file, etc.)
   - Track changes in summary with evidence
   - Handle questions inline, collect for bulk ask at end

5. **Verify acceptance**
   - Check each acceptance criterion (R-IDs)
   - Run tests if specified
   - Collect evidence: file diffs, test output, screenshots

6. **Mark complete**
   - Write summary with changes and evidence
   - Use `mossy-flowctl done <task-id> --summary-file <path>` or fallback
   - Update task status to done
   - **Commit behavior**: Respect commit-policy from config
     - manual: Do not commit (user must explicitly request)
     - auto-per-change: Auto-commit changes
     - auto-per-spec: Auto-commit when spec is complete
     - batch: Defer commit
   - Construct commit message with co-authored-by from config
   - If new-branch-per-spec=true: create new branch before committing
   - If auto-push=true: push after commit
   - Clean up workspace (optional, user choice)

## Task Execution Phases

### Phase 1: Analysis (Read-Only)
- Read relevant files
- Understand current state
- Identify exact changes needed
- NO modifications in this phase

### Phase 2: Planning
- List files to modify/create
- Define change strategy
- Identify risks and mitigations
- Estimate effort (logged, not blocking)

### Phase 3: Implementation
- Apply changes incrementally
- Verify each change immediately
- Track all modifications in summary

### Phase 4: Verification
- Run acceptance checks
- Execute tests
- Capture evidence
- Iterate if incomplete

## Workspace Structure

```
.flow/
├── work/
│   └── <task-id>/
│       ├── context.md      # Task metadata + loaded context
│       ├── summary.md      # Execution summary (grows during work)
│       ├── evidence/
│       │   ├── diffs/
│       │   │   └── <file>.diff
│       │   ├── tests/
│       │   │   └── <test>.log
│       │   └── screenshots/
│       └── questions.log    # Collected questions for bulk ask
└── tasks/
    └── <task-id>.json      # Task state (updated by flowctl)
```

## Summary Format

```markdown
# Task <task-id> Summary

**Spec:** <spec-id>
**Description:** <description>
**Acceptance:** <R-IDs>
**Started:** <timestamp>
**Completed:** <timestamp>

## Changes

### Modified Files
- `<file>`: <brief description of change>

### New Files
- `<file>`: <purpose>

### Deleted Files
- `<file>`: <reason>

## Acceptance Checks
- R1: <status> - <evidence/notes>
- R2: <status> - <evidence/notes>

## Tests Run
```
<test output>
```

## Evidence
- Diffs: `.flow/work/<task-id>/evidence/diffs/`
- Test logs: `.flow/work/<task-id>/evidence/tests/`

## Questions
<list of questions that arose during execution>

## Blockers
<list of blockers if task not completed>
```

## Commands for Users

After task execution:
- `/mossy:work <task-id>` - Re-execute task
- `/mossy:work <spec-id>` - Execute all ready tasks for spec
- `/mossy:work --next` - Execute next ready task
- `/mossy:work --list` - List ready tasks
- `/mossy:work --show <id>` - Show task details
- `/mossy:work --continue <task-id>` - Resume partially completed task

## Integration with mossy-flowctl

All `.flow/` state operations MUST use `mossy-flowctl`:

```bash
# Claim task
mossy-flowctl start <task-id>

# Mark complete
mossy-flowctl done <task-id> --summary-file .flow/work/<task-id>/summary.md

# List ready tasks
mossy-flowctl ready --json

# Show task
mossy-flowctl show <task-id>
```

## Fallback Behavior

If flowctl not available:
- Task state tracked in `.flow/tasks/<id>.json` with `status`, `claimed_at` fields
- Ready tasks: those with `status: "todo"` and no `blocked_reason`
- Claim: set `status: "in_progress"`, `claimed_at: <timestamp>`, `assignee: "mossy-work"`
- Done: set `status: "done"`, `updated_at: <timestamp>`
- No dependency validation in fallback mode

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during task execution | read_file on non-existent source file, search_replace pattern not found |
| validation-error | Task/spec metadata invalid | Missing task_id, invalid spec format, acceptance criteria missing |
| logic-error | Internal execution logic fails | Circular dependency in task execution, workspace corruption |
| resource-error | Required resources missing | .flow/work/ directory creation fails, flowctl not found |
| configuration-error | Environment misconfiguration | Missing required environment variables, incompatible tool versions |

### Integration

```bash
# At skill start, call required utilities
../mossy-scripts/ensure-flow-dir.sh >/dev/null 2>&1 || true
COMMIT_POLICY=$(/../mossy-scripts/load-mossy-config.sh COMMIT_POLICY 2>/dev/null) || true
NEW_BRANCH_PER_SPEC=$(/../mossy-scripts/load-mossy-config.sh NEW_BRANCH_PER_SPEC 2>/dev/null) || true
AUTO_PUSH=$(/../mossy-scripts/load-mossy-config.sh AUTO_PUSH 2>/dev/null) || true
CO_AUTHORED_BY=$(/../mossy-scripts/load-mossy-config.sh CO_AUTHORED_BY 2>/dev/null) || true

# When a tool fails during task execution
if ! read_file path="$target_file" 2>/dev/null; then
    ../mossy-scripts/record-issue.sh --skill "mossy-work" --error-type "tool-error" \
        --tool "read_file" --target "$target_file" \
        --error "read_file failed: file not found or permission denied" \
        --context "Phase: implementation, Task: $task_id, Reading source file for modification" || true
fi

# When search_replace fails
if ! search_replace file_path="$file" content="$changes" 2>/dev/null; then
    ../mossy-scripts/record-issue.sh --skill "mossy-work" --error-type "tool-error" \
        --tool "search_replace" --target "$file" \
        --error "search_replace failed: pattern not found or file unchanged" \
        --context "Phase: implementation, Task: $task_id, Applying changes to $file" || true
fi

# When task metadata is invalid
if [ -z "$task_id" ] || ! [[ "$task_id" =~ ^fn-[0-9]+\.[0-9]+$ ]]; then
    ../mossy-scripts/record-issue.sh --skill "mossy-work" --error-type "validation-error" \
        --tool "N/A" --target "$input" \
        --error "Invalid task ID format: expected fn-N.M pattern" \
        --context "Phase: input parsing, Validating task ID $input" || true
fi
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## Guardrails

- **IMPORTANT**: Always read local AGENTS.md in the subdirectories you are working in.
- Never modify files outside workspace without explicit task instruction
- Never commit to git without user confirmation **OR** commit-policy != manual
- All modifications tracked in summary with diffs
- Questions collected and asked in bulk at end (unless blocking)
- Blocking questions asked immediately
- Task workspace preserved until user confirms completion
- Evidence directory always created, even if empty
