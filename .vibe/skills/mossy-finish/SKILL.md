---
name: mossy-finish
description: "Execute complete mossy workflow: plan, work, and review stages for specifications"
user-invocable: false
allowed-tools: read_file,write_file,search_replace,grep,bash,ask_user_question,skill,task
---

# mossy-finish

Automatically execute the complete mossy workflow (plan → work → review) on a given spec.

The focus is the code; code is the single source of truth, it should be able to speak for itself. Inline comments provide the documentation.

The human retains full control and responsibility. They can verify the quality of individual steps during or after processing.

## Input

$ARGUMENTS

Accepts:
- Spec ID: `fn-23` or `fn-23-create-mossy-finish-skill` (full or short form)

## Flow

1. **Parse Input**
   - Trim whitespace from $ARGUMENTS
   - If empty or whitespace-only, output error: "Spec ID required. Usage: /mossy:finish <spec-id>"
   - Validate spec ID format using regex: `^fn-\d+(-[a-z0-9-]+)?$`
   - If format invalid, output error: "Invalid spec ID format. Expected: fn-N or fn-N-slug"
   - Check if spec file exists at `.flow/specs/<spec-id>.md` or `.flow/specs/<spec-id>.md`
   - If spec file not found, output error: "Spec not found: <spec-id>"
   - Store validated spec_id for subsequent steps

2. **Read Configuration**
   - Use `read_file` to read spec file from `.flow/specs/<spec-id>.md`

3. **Branch Management**
   - Call `load-mossy-config.sh NEW_BRANCH_PER_SPEC <spec-id>` to get the branch policyare on a branch with name <spec-id>.
   - If new-branch-per-spec=true:
     - Get current branch using `git branch --show-current`
     - If current branch is not <spec-id>, execute: `git checkout <spec-id> 2>/dev/null || git checkout -b <spec-id>`
     - Verify checkout succeeded
   - If new-branch-per-spec=false:
     - Continue on current branch (no action needed)

4. **Execute Workflow**
   - **Plan Phase**: Invoke mossy-plan skill with spec_id as argument
     - Use: `/mossy:plan <spec-id>` or invoke mossy-plan skill directly
     - Wait for all tasks to be created
     - Verify plan creation succeeded by checking `.flow/tasks/<spec-id>.*` files exist
   - **Work Phase**: Invoke mossy-work skill with spec_id as argument
     - Use: `/mossy:work <spec-id>` or invoke mossy-work skill directly
     - This will execute all ready tasks for the spec in order
     - Wait for all tasks to complete (status: done)
     - Verify by checking all task statuses with `flowctl.sh show <spec-id>`
   - **Review Phase**: Invoke mossy-review skill with spec_id as argument
     - Use: `/mossy:review <spec-id>` or invoke mossy-review skill directly
     - Wait for review completion
     - Verify review report is generated

5. **Commit and Push**
   - **Commit Policy Check**: Respect commit-policy from config, read with `load-mossy-config.sh COMMIT_POLICY <spec-id>`
     - manual: Do not commit (user must explicitly request)
     - auto-per-change: Auto-commit changes
     - auto-per-spec: Auto-commit when spec is complete
     - batch: Defer commit
   - Construct commit message with co-authored-by from config, 
   - Read auto-push policy with `load-mossy-config.sh AUTO_PUSH <spec-id>`. If it is 'true': push after commit
   - **Auto-Commit Execution** (if enabled):
     - Get list of changed files with `git status --porcelain`
     - If no changes, skip commit (nothing to commit)
     - Construct commit message: "mossy-finish: complete workflow for <spec-id>"
     - Add co-authored-by trailer from config: "Co-authored-by: <value>", get value from read with `load-mossy-config.sh CO_AUTHORED_BY <spec-id>`
     - Execute: `git add .` and `git commit -m "<message>"`
     - Verify commit succeeded
   - **Auto-Push Execution** (if auto-push=true and commit succeeded):
     - Execute: `git push`
     - Verify push succeeded

6. **Error Handling**
   - **Error Detection**:
     - Wrap each major step (1-5) with error checking
     - Check return codes and tool execution results
     - Catch exceptions from tool calls
   - **Error Recording**:
     - Source the record-issue.sh script: `source .vibe/skills/mossy-scripts/record-issue.sh`
     - Call `record_issue "mossy-finish" "<error-type>" "<tool>" "<target>" "<error-msg>" "<context>"`
     - Error types: tool-error, validation-error, logic-error, resource-error, configuration-error
     - Always use `|| true` to prevent recording failures from breaking execution
   - **Error Reporting**:
     - Output clear error message to user
     - Include: error type, step number, error details, and suggested action
     - Format: "ERROR [mossy-finish:step-N]: <message>. See .flow/issues/ for details."
   - **Stop on Error**:
     - Exit immediately after first error (fail-fast principle)
     - Do not attempt to continue with subsequent steps
     - Return non-zero exit code

## Commands

- `/mossy:finish fn-23` - Execute full workflow on spec fn-23
- `/mossy:finish --help` - Show usage information

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../mossy-scripts/ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail | read_file on non-existent spec file |
| validation-error | Input format invalid | Invalid spec ID format |
| logic-error | Internal logic fails | Workflow execution failure |
| resource-error | Required resources missing | .flow/specs/ directory not found |
| configuration-error | Environment misconfiguration | flowctl.sh not found |

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## GUARDRAILS

- **CRITICAL: NO actual work outside workflow orchestration. ONLY orchestrate mossy-plan, mossy-work, mossy-review**
- **IMPORTANT**: Always read local AGENTS.md in the subdirectories you are working in.
- **DO NOT call flowctl.py** - use flowctl.sh
- Never modify files outside `.flow/` without explicit need
- Never commit to git without user confirmation OR commit-policy != manual
- All modifications tracked in workflow execution
- You MUST use the `ask_user_question` tool for every question that requires user judgment.
- When committing work done here, even later, sign off with coauthor given by `load-mossy-config.sh CO_AUTHORED_BY <spec-id>`
