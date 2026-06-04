# Issue Recording Guide for Mossy Skill Authors

**All mossy skills MUST implement error recording** to `.flow/issues/` directory. This ensures problems are trackable, reproducible, and fixable.

---

## Quick Summary

| Requirement | Details |
|-------------|---------|
| **Directory** | `.flow/issues/` |
| **File Format** | Markdown with structured sections |
| **Naming** | `<timestamp>-<skill>-<error-type>-<sequence>.md` |
| **When to Record** | All tool errors, validation failures, logic errors, resource issues |
| **Script Available** | `../mossy-scripts/record-issue.sh` |

---

## When to Record an Issue

Record an issue **immediately** when encountering:

### 1. Tool Errors
When any Vibe tool call fails:
- `grep`: Pattern error, directory not found
- `bash`: Command not found, non-zero exit code
- `ask_user_question`: Invalid question format, no response
- `task`: Subagent creation failed, task not found

### 2. Validation Errors
When input doesn't meet expectations:
- Invalid task ID format
- Missing required arguments
- File path doesn't match expected pattern
- Spec format doesn't conform to schema

### 3. Logic Errors
When skill's internal logic encounters unexpected state:
- Unexpected file content (e.g., file exists but has wrong format)
- Circular dependencies detected
- Inconsistent state (e.g., task marked done but files unchanged)
- Edge cases not handled

### 5. Configuration Errors
When environment or configuration is wrong:
- Required scripts not found (e.g., flowctl.py missing)

---

## What NOT to Record

Do NOT record:
- User intentionally cancelled operations
- Expected behavior (e.g., "file not found" when checking for optional file)
- Transient network issues that auto-retry
- Issues already recorded in the same execution context

---

## Issue File Format

Each issue file MUST contain these sections:

```markdown
# Issue: <Brief Description>

**ID:** <unique-identifier>
**Skill:** <skill-name>
**Timestamp:** <ISO-8601>
**Severity:** <critical|high|medium|low>
**Status:** <open|resolved|duplicate>
**Error Type:** <tool-error|validation-error|logic-error|resource-error|configuration-error>

## Tool Invocation

<Details of the tool call that failed>

```
timestamp: <when>
tool: <tool-name>
target: <file/pattern/resource>
arguments: <args>
```

## Error Log

<Complete error output>

```
<exact error message>
```

## Problem Description

<What went wrong in human terms>

## Context

<What led to this - sufficient to reproduce>

## Reproduction Steps

1. <step 1>
2. <step 2>

## Impact

<What was affected>

## Resolution Notes

<TBD or how it was fixed>

## Related Issues

<links to other issues>
```

---

## Recording Using the Shared Script

```bash
# Source the script and call the function
../mossy-scripts/record-issue.sh "mossy-work" "tool-error" "read_file" "src/module.py" \
  "File not found: No such file or directory" \
  "Analysis phase: attempting to read file mentioned in task description"
```

## Severity Levels

| Level | When to Use | Example |
|-------|-------------|---------|
| **critical** | Skill cannot continue, data loss possible | File system error during write, permission denied on critical path |
| **high** | Skill cannot complete current operation, manual intervention needed | Task cannot be claimed, spec file corrupted |
| **medium** | Operation failed but skill can continue with degraded functionality | Non-critical file not found, optional feature unavailable |
| **low** | Minor issue, skill continues normally | Warning-level issues, non-fatal validation problems |

Default: `medium`

## Skill-Specific Examples

Each mossy skill records errors specific to its domain. Below are examples of error recording for each implemented skill.

### Core Skills

#### mossy-plan
Records errors during spec parsing and planning:
```bash
# Tool error: spec file not found
record_issue "mossy-plan" "tool-error" "read_file" "specs/fn-1.md" \
    "File not found: No such file or directory" \
    "Phase: parsing, Attempting to read spec file"

# Validation error: missing Goal section
record_issue "mossy-plan" "validation-error" "N/A" "specs/fn-1.md" \
    "Invalid spec format: missing Goal section" \
    "Phase: parsing, Validating spec structure"
```

#### mossy-work
Records errors during task execution:
```bash
# Tool error: source file not found
record_issue "mossy-work" "tool-error" "read_file" "src/module.py" \
    "File not found: No such file or directory" \
    "Phase: implementation, Task: fn-1.1, Reading source file"

# Validation error: invalid task ID
record_issue "mossy-work" "validation-error" "N/A" "fn-invalid" \
    "Invalid task ID format: expected fn-N.M pattern" \
    "Phase: input parsing, Validating task ID"
```

#### mossy-review
Records errors during code review:
```bash
# Tool error: file not found
record_issue "mossy-review" "tool-error" "read_file" "src/component.tsx" \
    "File not found: No such file or directory" \
    "Phase: analysis, Task: fn-2.1, Reading file for review"

# Validation error: unsupported file type
record_issue "mossy-review" "validation-error" "N/A" "src/data.json" \
    "Unsupported file type for review: .json" \
    "Phase: target resolution, Validating file type"
```

#### mossy-refactor
Records errors during refactoring operations:
```bash
# Tool error: target file not found
record_issue "mossy-refactor" "tool-error" "read_file" "src/utils.py" \
    "File not found: No such file or directory" \
    "Phase: analysis, Reading target file for refactoring"

# Validation error: unsupported operation
record_issue "mossy-refactor" "validation-error" "N/A" "extract_interface" \
    "Unsupported operation: extract_interface for JavaScript" \
    "Phase: validation, Checking operation support"
```

#### mossy-analyze
Records errors during static analysis:
```bash
# Tool error: directory not found
record_issue "mossy-analyze" "tool-error" "bash" "src/" \
    "Directory not found: No such file or directory" \
    "Phase: analysis, Searching for source files"

# Validation error: unsupported language
record_issue "mossy-analyze" "validation-error" "N/A" "src/config.yaml" \
    "Unsupported language for analysis: yaml" \
    "Phase: target resolution, Detecting language from extension"
```

#### flowctl.sh
Records errors when using flowctl.sh:
```bash
# Resource error: flowctl not found
record_issue "flowctl.sh" "resource-error" "N/A" "$FLOW_DIR/flowctl" \
    "flowctl not found or not executable" \
    "Phase: detection, Checking flowctl availability"

# Tool error: flowctl command failed
record_issue "flowctl.sh" "tool-error" "bash" "flowctl.sh start fn-1.1" \
    "flowctl command failed with exit code 1" \
    "Phase: flowctl execution, Executing flowctl.sh start"
```

## File Structure

```
.flow/
└── issues/
    ├── 20240523-143022-mossy-work-tool-error-001.md
    ├── 20240523-150100-mossy-refactor-validation-error-002.md
    ├── 20240523-154530-mossy-analyze-logic-error-003.md
    └── README.md          # Auto-generated index of all issues

.vibe/
└── skills/
    ├── mossy-scripts/
    │   ├── ISSUE_TEMPLATE.md  # Template for manual issue creation
    │   ├── record-issue.sh      # Shared recording utility
    │   └── ISSUE_RECORDING.md   # This guide
    └── mossy-*/
        └── SKILL.md           # Individual skills
```

---

## Example Issue Files

See `../mossy-scripts/ISSUE_TEMPLATE.md` for the complete template.

---

*This guide is part of the mossy-slop project. See AGENTS.md for more information.*
