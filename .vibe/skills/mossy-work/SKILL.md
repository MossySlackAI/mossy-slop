---
name: mossy-work
description: "Execute plan tasks: claim from ready queue, perform implementation, mark complete with evidence"
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

0. **Prepare**
   - Call `load-mossy-config.sh NEW_BRANCH_PER_SPEC <spec-id>` to get the branch policy. If that gives 'false', do nothing. If it gives 'true', make sure we are on a branch with name <spec-id>.

1. **Resolve target**
   - If task ID: execute that task
   - If spec ID: find ready tasks for that spec, execute in order
   - If `--next`: find first ready task across all specs
   - If `--list`: show ready tasks and exit
   - If `--show <id>`: display task details and exit

2. **Claim task**
   - Use `flowctl.sh start <task-id>`
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
   - Check each acceptance criterion (checkbox format)
   - Run tests if specified
   - Collect evidence: file diffs, test output, screenshots

6. **Mark complete**
   - Write summary with changes and evidence
   - Use `flowctl.sh done <task-id> --summary-file <path>` or fallback
   - Update task status to done
   - **Commit behavior**: Respect commit-policy from config, read with `load-mossy-config.sh COMMIT_POLICY <spec-id>`
     - manual: Do not commit (user must explicitly request)
     - auto-per-change: Auto-commit changes
     - auto-per-spec: Auto-commit when spec is complete
     - batch: Defer commit
   - Construct commit message with co-authored-by from config, read with `load-mossy-config.sh CO_AUTHORED_BY <spec-id>`
   - Read auto-push policy with `load-mossy-config.sh AUTO_PUSH <spec-id>`. If it is 'true': push after commit
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
**Acceptance:** <checkbox criteria>
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
- [ ] Criterion 1: <status> - <evidence/notes>
- [ ] Criterion 2: <status> - <evidence/notes>

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

## Integration with flowctl.sh

All `.flow/` state operations MUST use `flowctl.sh`:

```bash
# Claim task
flowctl.sh start <task-id>

# Mark complete
flowctl.sh done <task-id> --summary-file .flow/work/<task-id>/summary.md

# List ready tasks
flowctl.sh ready --json

# Show task
flowctl.sh show <task-id>
```

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](mossy-scripts/ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during task execution | read_file on non-existent source file, search_replace pattern not found |
| validation-error | Task/spec metadata invalid | Missing task_id, invalid spec format, acceptance criteria missing |
| logic-error | Internal execution logic fails | Circular dependency in task execution, workspace corruption |
| resource-error | Required resources missing | .flow/work/ directory creation fails, flowctl not found |
| configuration-error | Environment misconfiguration | Missing required environment variables, incompatible tool versions |

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## GUARDRAILS

- **IMPORTANT**: Always read local AGENTS.md in the subdirectories you are working in.
- **DO NOT call flowctl.py** - use flowctl.sh
- Never modify files outside workspace without explicit task instruction
- Never commit to git without user confirmation **OR** commit-policy != manual
- All modifications tracked in summary with diffs
- Questions collected and asked in bulk at end (unless blocking)
- Blocking questions asked immediately
- Task workspace preserved until user confirms completion
- Evidence directory always created, even if empty
