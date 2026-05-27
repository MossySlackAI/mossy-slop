---
name: mossy-review
description: Review changes before commit. Analyzes code modifications against acceptance criteria and produces structured review reports.
axis: 1
argument-hint: "<task-id|spec-id> [--diff|--staged|--all|--file <path>|--list|--show <id>|--check|--quick|--security]"
---

# IMPORTANT: Invoke skill `mossy-review`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

- `/mossy:review fn-1.1` - Review changes for specific task
- `/mossy:review fn-1` - Review all changes for spec
- `/mossy:review --diff` - Review unstaged git changes
- `/mossy:review --staged` - Review staged git changes
- `/mossy:review --all` - Review all uncommitted changes
- `/mossy:review --file src/main.py` - Review specific file
- `/mossy:review --list` - List pending reviews
- `/mossy:review --show fn-1.1` - Show existing review report
- `/mossy:review --check` - Quick style/lint check
- `/mossy:review --quick` - Quick review (basic checks only)
- `/mossy:review --security` - Security-focused review

## Examples

```
# After completing a task, review before commit
/mossy:work fn-1.1
/mossy:review fn-1.1

# Review all changes for a spec
/mossy:review fn-1

# Review current unstaged changes
/mossy:review --diff

# Quick lint check
/mossy:review --check

# Security audit of staged changes
/mossy:review --staged --security

# See what needs review
/mossy:review --list

# View previous review report
/mossy:review --show fn-1.1
```

## Review Process

1. **Target Resolution**: Identifies what to review (task, spec, git changes, or file)
2. **Change Collection**: Gathers all modified, created, and deleted files
3. **Context Loading**: Loads acceptance criteria and relevant metadata
4. **Analysis**: Performs multi-category checks (quality, correctness, testing, security, etc.)
5. **Acceptance Verification**: Checks each R-ID against the changes
6. **Report Generation**: Produces structured markdown report
7. **User Decision**: Presents findings and awaits user action

## Output

A structured review report containing:
- Summary statistics (files changed, lines added/removed, issues found)
- Acceptance criteria verification status
- Categorized issues (Critical, Major, Minor, Style)
- Per-file analysis
- Recommendations
- Questions for human review

## Integration

Works with:
- `mossy-flowctl` for spec/task metadata
- Git for change detection
- Language-specific linters when available

## Modes

| Mode | Flag | Focus | Speed |
|------|------|-------|-------|
| Full | (default) | All checks | Slow |
| Quick | `--quick` | Basic checks | Fast |
| Style | `--check` | Linting only | Fast |
| Security | `--security` | Security only | Medium |
