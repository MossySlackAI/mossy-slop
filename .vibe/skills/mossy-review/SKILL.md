---
name: mossy-review
description: Review changes before commit. Analyzes code modifications against acceptance criteria, checks for issues, and produces structured review reports.
user-invocable: false
allowed-tools: read_file,write_file,grep,bash,ask_user_question,task
---

# mossy-review

The focus is the code; code is the single source of truth, it should be able to speak for itself. Inline comments provide the documentation.

The human retains full control and responsibility. They can verify the quality of individual steps during or after processing.

## Review

Analyze code changes and produce structured review reports before commit.

## Input

$ARGUMENTS

Accepts:
- Task ID: `fn-1.1` - Review changes for specific task
- Spec ID: `fn-1` - Review all changes for spec
- `--diff` - Review unstaged git changes
- `--staged` - Review staged git changes
- `--all` - Review all uncommitted changes
- `--file <path>` - Review specific file
- `--list` - List pending reviews
- `--show <id>` - Show review report for task/spec
- `--check` - Quick lint/style check without full review

## Flow

1. **Resolve target**
   - If task ID: load task metadata, acceptance criteria, workspace
   - If spec ID: find all tasks for spec, load their changes
   - If `--diff`: get `git diff` output
   - If `--staged`: get `git diff --staged` output
   - If `--all`: get `git diff HEAD` output
   - If `--file <path>`: read and analyze specific file
   - If `--list`: show pending reviews and exit
   - If `--show <id>`: display existing review report and exit
   - If `--check`: run linting only

2. **Collect changes**
   - For task/spec: read from `.flow/work/<id>/` workspace
   - For git modes: capture diff output
   - For file mode: read file content
   - Build list of modified/created/deleted files

3. **Load context**
   - For task: load acceptance criteria (checkbox format) from task metadata
   - For spec: load all acceptance criteria from spec (checkbox format)
   - For git modes: infer context from commit message or user input
   - Load relevant files for understanding

4. **Analyze changes**
   - **Code Quality**: Check for anti-patterns, complexity, duplication
   - **Correctness**: Verify logic against requirements
   - **Testing**: Check if tests cover changes
   - **Style**: Lint check, formatting
   - **Security**: Look for common vulnerabilities
   - **Performance**: Check for obvious inefficiencies
   - **Documentation**: Check for missing/outdated comments

5. **Verify acceptance**
   - For each acceptance criterion: check if change satisfies criterion
   - Mark PASS/FAIL/UNCLEAR
   - Collect evidence for each check

6. **Generate report**
   - Structured markdown review report
   - Summary of findings
   - Detailed issues with locations
   - Recommendations

7. **Present to user**
   - Display report
   - Ask if changes should be committed, fixed, or abandoned
   - If issues found: suggest fixes

## Review Report Format

```markdown
# Review Report: <target>

**Type:** <task|spec|git|file>
**Target:** <id or path>
**Timestamp:** <datetime>
**Status:** <pass|fail|needs-work>

## Summary
- Files changed: <count>
- Lines added: <count>
- Lines removed: <count>
- Issues found: <count> (<critical>/<major>/<minor>)
- Acceptance criteria: <passed>/<total>

## Acceptance Check
- [ ] Criterion 1: PASS/FAIL/UNCLEAR - <notes>
- [ ] Criterion 2: PASS/FAIL/UNCLEAR - <notes>
...

## Issues Found

### Critical
- [ ] <issue> at <file>:<line> - <description>

### Major
- [ ] <issue> at <file>:<line> - <description>

### Minor
- [ ] <issue> at <file>:<line> - <description>

### Style
- [ ] <issue> at <file>:<line> - <description>

## Files Reviewed
- `<file>`: <summary of changes and findings>

## Recommendations
- <actionable suggestion>

## Questions
- <question for human review>
```

## Analysis Categories

### Code Quality Checks
- Function length (>50 lines flagged)
- File length (>500 lines flagged)
- Cyclomatic complexity (estimates via nesting)
- Duplicate code detection (exact match >10 lines)
- Unused imports/variables
- Dead code detection

### Correctness Checks
- Type safety issues
- Null/undefined handling
- Boundary conditions
- Error handling presence
- Input validation
- Return value correctness

### Testing Checks
- Tests exist for new functionality
- Tests cover edge cases
- Test assertions are meaningful
- Mock/stub usage appropriate

### Security Checks
- SQL injection vulnerabilities
- XSS vulnerabilities
- Hardcoded secrets
- Insecure deserialization
- Missing authentication/authorization
- Input sanitization
- Race conditions

### Performance Checks
- N+1 query patterns
- Unnecessary computations in loops
- Large data structure copies
- Blocking I/O in hot paths
- Missing caching opportunities

### Style Checks
- Consistent indentation
- Naming conventions
- Line length (<120 chars recommended)
- Trailing whitespace
- Mixed tabs/spaces
- Missing semicolons (if language requires)

## Review Modes

### Full Review
Default mode. Performs all checks and produces comprehensive report.

### Quick Review (`--quick`)
Skips deep analysis, focuses on:
- Syntax errors
- Obvious bugs
- Missing acceptance criteria

### Style Only (`--check`)
Only performs linting/style checks:
- Formatting
- Naming conventions
- Line length
- Basic syntax

### Security Focus (`--security`)
Prioritizes security checks:
- Vulnerability patterns
- Secret scanning
- Input validation
- Authentication/authorization

## Integration with flowctl.sh

For task/spec reviews, use flowctl.sh to load metadata:

```bash
# Get task details
../mossy-scripts/flowctl.sh show <task-id>

# Get spec details  
../mossy-scripts/flowctl.sh show <spec-id>

# List tasks for spec
../mossy-scripts/flowctl.sh tasks --spec <spec-id>
```

## Workspace Structure

Review reports stored in:
```
.flow/
├── reviews/
│   ├── <task-id>/
│   │   ├── report.md          # Full review report
│   │   ├── issues.json        # Machine-readable issues
│   │   └── evidence/          # Screenshots, logs
│   └── <spec-id>/
│       └── report.md
└── review-queue.json          # Pending reviews
```

## Git Integration

### Detecting Changes
```bash
# Unstaged changes
git diff --name-only

# Staged changes
git diff --staged --name-only

# All uncommitted changes
git diff HEAD --name-only

# Since last commit
git diff HEAD~1 --name-only
```

### Capturing Diffs
```bash
# Full diff
git diff > .flow/reviews/current/diff.patch

# Diff for specific file
git diff <file> > .flow/reviews/current/<file>.diff
```

## Commands for Users

- `/mossy:review fn-1.1` - Review changes for task
- `/mossy:review fn-1` - Review all changes for spec
- `/mossy:review --diff` - Review unstaged changes
- `/mossy:review --staged` - Review staged changes
- `/mossy:review --all` - Review all uncommitted changes
- `/mossy:review --file src/main.py` - Review specific file
- `/mossy:review --list` - List pending reviews
- `/mossy:review --show fn-1.1` - Show review report
- `/mossy:review --check` - Quick style/lint check
- `/mossy:review --quick` - Quick review (basic checks only)
- `/mossy:review --security` - Security-focused review

## Language-Specific Checks

### Python
- PEP 8 compliance
- Type hints usage
- async/await patterns
- Context manager usage
- Exception handling

### TypeScript/JavaScript
- Type safety
- Null/undefined checks
- Promise handling
- Event emitter patterns
- Module imports

### C#
- async/await patterns
- IDisposable usage
- Null reference checks
- LINQ usage
- Exception handling

### C++
- Memory management
- RAII patterns
- Const correctness
- Exception safety
- Standard library usage

### GDScript
- Signal usage
- Node references
- Scene tree structure
- Godot conventions

### VB.NET
- COM interop patterns
- Event handling
- Disposable patterns
- XML documentation

## Severity Levels

| Level | Description | Example |
|-------|-------------|---------|
| CRITICAL | Must fix before commit | Security vulnerability, data corruption |
| MAJOR | Should fix before commit | Missing error handling, wrong logic |
| MINOR | Nice to fix | Style issues, minor refactoring |
| STYLE | Formatting/lint | Line length, indentation |

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../mossy-scripts/ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during analysis | read_file on non-existent source file, grep pattern error |
| validation-error | Review target invalid | Invalid file path, unsupported file type, missing metadata |
| logic-error | Internal analysis logic fails | Inconsistent analysis results, validation loop |
| resource-error | Required resources missing | .flow/reviews/ directory creation fails, git not available |
| configuration-error | Environment misconfiguration | Linter not installed but configured, missing review backend |

#### Integration

```bash
# At skill start, call required utilities
../mossy-scripts/ensure-flow-dir.sh >/dev/null 2>&1 || true

# When a tool fails during analysis
if ! read_file path="$file_path" 2>/dev/null; then
    ../mossy-scripts/record-issue.sh --skill "mossy-review" --error-type "tool-error" \
        --tool "read_file" --target "$file_path" \
        --error "read_file failed: file not found or permission denied" \
        --context "Phase: analysis, Task: $task_id, Reading file for review" || true
fi

```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## Guardrails

- Never automatically commit code
- Never modify source files without explicit approval
- All findings documented in report
- User makes final decision on all issues
- Questions collected and asked in bulk at end (header max: 11 chars)
- Blocking issues (CRITICAL) reported immediately
- Review workspace preserved for user inspection
- Evidence always captured for findings
