# mossy-work workflow

Phase-by-phase execution for task implementation.

## Phase 1: Input Parsing

```
Input: $ARGUMENTS

Parse order:
1. Check for flags: --list, --show, --next, --continue
2. If no flags, treat as ID (task or spec)
3. Validate ID format: task = <spec>.<number>, spec = fn-<number>
```

**Actions:**
- `--list`: Call `mossy-flowctl ready` or fallback, display table, exit
- `--show <id>`: Call `mossy-flowctl show <id>`, display details, exit
- `--next`: Call `mossy-flowctl ready`, take first, continue to Phase 2
- `--continue <task-id>`: Load existing workspace, skip to Phase 4
- `<task-id>`: Validate format, continue to Phase 2
- `<spec-id>`: Find ready tasks for spec via `mossy-flowctl ready --spec <id>`, execute each in order

## Phase 2: Task Claim

```
For each task to execute:
```

**Actions:**
1. Check task exists: `mossy-flowctl show <task-id>`
2. Verify task is ready (status = todo, not blocked)
3. Check dependencies: all `depends_on` tasks must be done
4. Claim task: `mossy-flowctl start <task-id>`
5. Load task metadata:
   - spec_id
   - description
   - acceptance criteria (R-IDs)
   - depends_on
   - priority

**Fallback (no flowctl):**
1. Read `.flow/tasks/<task-id>.json`
2. Verify status is "todo" and no blocked_reason
3. Update file: status = "in_progress", claimed_at = now, assignee = "mossy-work"
4. Load metadata from file

**Output:** Task context object with all metadata

## Phase 3: Workspace Setup

```
Workspace: .flow/work/<task-id>/
```

**Actions:**
1. Create directory structure:
   ```bash
   mkdir -p .flow/work/<task-id>/evidence/{diffs,tests,screenshots}
   ```
2. Write context.md:
   ```markdown
   # Task <task-id> Context

   **Claimed:** <timestamp>
   **Assignee:** mossy-work

   ## Metadata
   - Spec: <spec_id>
   - Description: <description>
   - Acceptance: <R-IDs>
   - Depends on: <depends_on>
   - Priority: <priority>
   ```
3. Initialize summary.md with header (see SKILL.md for format)
4. Initialize empty questions.log

## Phase 4: Analysis (Read-Only)

**Guardrail: NO file modifications in this phase**

**Actions:**
1. Parse task description for:
   - File paths mentioned
   - Action verbs (create, modify, delete, update, add, remove, refactor)
   - Domain-specific terms (class, function, method, endpoint, table)
2. For each relevant file path:
   - Check if exists: `bash: test -f <path>`
   - If exists: read full content
   - If not: note as "to be created"
3. Build mental model:
   - Current state of codebase
   - Required changes
   - Dependencies between changes
4. Document findings in summary.md under "## Analysis"

**Questions handling:**
- Log question to questions.log
- Log question in summary.md under "## Questions"
- Continue processing (non-blocking)

**Blocking questions:**
- Ask immediately via ask_user_question
- Pause execution until answer received
- Log answer in summary.md

## Phase 5: Planning

**Actions:**
1. Define change units (atomic modifications):
   - Each unit = one file modification or creation
   - Group related changes that must happen together
2. Order change units by dependency:
   - Infrastructure first (config, schemas, base classes)
   - Core logic second
   - UI/API last
   - Tests alongside implementation
3. For each unit, define:
   - Target file
   - Type of change (create, modify, delete)
   - Specific modifications
   - Verification method
4. Write plan to summary.md under "## Implementation Plan"

**Template:**
```markdown
## Implementation Plan

| # | File | Change | Verification |
|---|------|--------|--------------|
| 1 | <file> | <description> | <method> |
| 2 | <file> | <description> | <method> |
```

## Phase 6: Implementation

**Actions:**
1. For each change unit in order:
   a. Backup original file (if modifying): cp <file> <file>.backup
   b. Apply change:
      - Create: write_file
      - Modify: search_replace or write_file with overwrite
      - Delete: bash rm
   c. Verify change immediately:
      - Syntax check if applicable
      - Read file back to confirm
      - Run relevant tests if available
   d. Capture evidence:
      - Diff: `git diff <file>` > evidence/diffs/<file>.diff
      - Or manual diff comparison
   e. Update summary.md under "## Changes"
2. Track all file modifications
3. Collect any new questions

**Tools by change type:**
- Create new file: write_file
- Modify existing: search_replace (preferred) or read+write
- Delete file: bash rm
- Rename: bash mv
- Multi-file refactor: task delegation to mossy-refactor

## Phase 7: Verification

**Actions:**
1. For each acceptance criterion (R-ID):
   a. Parse criterion into verifiable statement
   b. Define test/verification method
   c. Execute verification:
      - Code review: read relevant files
      - Test execution: bash <test command>
      - Manual check: describe in summary
   d. Record result in summary.md under "## Acceptance Checks"
2. Run comprehensive tests if available:
   - Unit tests
   - Integration tests
   - Linting
   - Build verification
3. Capture all output in evidence/tests/

**Acceptance result format:**
```markdown
- R1: PASS - <brief evidence description>
- R2: PASS - <brief evidence description>
- R3: FAIL - <reason, with details in evidence>
```

## Phase 8: Completion

**If all acceptance criteria PASS:**

1. Finalize summary.md:
   - Fill in Completed timestamp
   - Ensure all sections populated
   - Review questions log
2. If questions.log has entries:
   a. Ask user in bulk via ask_user_question
   b. Wait for all answers
   c. Document answers in summary.md
   d. Re-verify if answers affect implementation
3. Mark task done:
   ```bash
   mossy-flowctl done <task-id> --summary-file .flow/work/<task-id>/summary.md
   ```
4. Cleanup (optional, ask user):
   - Remove workspace: rm -rf .flow/work/<task-id>
   - Or archive: mv .flow/work/<task-id> .flow/archive/<task-id>-

**Fallback:**
```bash
# Update task file
jq '.status = "done" | .updated_at = now' \
  .flow/tasks/<task-id>.json > /tmp/temp.json && \
mv /tmp/temp.json .flow/tasks/<task-id>.json
```

**If any acceptance criteria FAIL:**

1. Document failures in summary.md
2. Update task status to blocked or todo:
   ```bash
   mossy-flowctl reset <task-id>
   # Or update with blocked_reason
   ```
3. Report to user with specific failure details
4. Preserve workspace for manual intervention

## Phase 9: Multi-Task Execution

**When executing multiple tasks (spec ID input):**

1. Get list of ready tasks for spec
2. Sort by task number (natural sort)
3. For each task in order:
   a. Execute Phases 2-8 for that task
   b. If task fails:
      - Stop execution
      - Report failure
      - User can fix and retry with --continue
   c. If task succeeds:
      - Continue to next task
4. After all tasks: provide overall summary

## Error Handling

**Recoverable errors:**
- File not found during read: log, continue with creation
- Test failure: document, mark acceptance as FAIL
- Parse error in task description: ask clarifying question, continue

**Unrecoverable errors:**
- Task already claimed by another: abort with error
- Missing required metadata: abort with error
- Permission denied on file operation: abort with error

**Workflow on error:**
1. Log error details to summary.md
2. Update task status appropriately
3. Preserve workspace
4. Report to user with next steps

## State Recovery

**If interrupted (user cancellation, crash):**

1. On restart with --continue <task-id>:
   - Load existing workspace
   - Check claimed status
   - Resume from last known good phase
2. Workspace contains:
   - summary.md with progress notes
   - evidence/ with partial results
   - questions.log with unanswered questions
3. User can:
   - Continue: re-run with --continue
   - Abandon: `mossy-flowctl reset <task-id>`, delete workspace
   - Manual fix: edit files directly, then mark done

## Tool Usage Guidelines

**read_file:**
- Use for understanding code before modification
- Read entire file first, then modify
- Use offset/limit for large files

**write_file:**
- Create new files
- Overwrite only when replacing entire file
- Always read first if file exists

**search_replace:**
- Preferred for modifying existing files
- Use exact text from read_file
- Verify with read_file after modification

**grep:**
- Find usage patterns before refactoring
- Locate function/class definitions
- Check for dependencies

**bash:**
- File operations (cp, mv, rm)
- Git operations (diff, status)
- Test execution
- Never use for code modifications

**ask_user_question:**
- Blocking questions only
- Bulk non-blocking questions at end
- Clear, specific questions
- Provide context in question text

**task:**
- Delegate complex refactoring to mossy-refactor
- Delegate analysis to mossy-analyze
- Pass full context to subagent
