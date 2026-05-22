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
| **Script Available** | `scripts/record-issue.sh` |

---

## Why Record Issues

1. **Token Conservation**: Prevents re-learning the same problems
2. **Time Savings**: Quick diagnosis of recurring issues
3. **Codebase Improvement**: Identifies systematic problems to fix
4. **User Transparency**: Users can see what went wrong and why
5. **Future-Proofing**: Documented issues inform future skill development

---

## When to Record an Issue

Record an issue **immediately** when encountering:

### 1. Tool Errors
When any Vibe tool call fails:
- `read_file`: File not found, permission denied, encoding issues
- `write_file`: Permission denied, disk full, path invalid
- `search_replace`: Pattern not found, file unchanged
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

### 4. Resource Errors
When external resources are unavailable:
- Required directories don't exist
- Network resources unavailable
- Git operations fail
- External tools not installed

### 5. Configuration Errors
When environment or configuration is wrong:
- Missing environment variables
- Incompatible tool versions
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

## Recording Methods

### Method 1: Using the Shared Script (Recommended)

For skills that can execute bash commands:

```bash
# Source the script and call the function
source scripts/record-issue.sh
record_issue "mossy-work" "tool-error" "read_file" "src/module.py" \
  "File not found: No such file or directory" \
  "Analysis phase: attempting to read file mentioned in task description"
```

Or call directly:

```bash
./scripts/record-issue.sh \
  --skill mossy-work \
  --error-type tool-error \
  --tool read_file \
  --target src/module.py \
  --error "File not found: No such file or directory" \
  --context "Analysis phase for task fn-1.1"
```

### Method 2: Direct File Creation

For skills using `write_file` tool directly:

```python
# In your skill's logic (pseudo-code)
try:
    result = read_file(path=target)
except Exception as e:
    issue_content = f"""# Issue: File read failed

**ID:** {generate_id()}
**Skill:** mossy-work
**Timestamp:** {iso_timestamp()}
**Error Type:** tool-error

## Tool Invocation

timestamp: {timestamp}
tool: read_file
target: {target}

## Error Log

{e}

## Problem Description

Failed to read file {target} during analysis phase.

## Context

Task: {task_id}
Phase: analysis
Previous action: parsing task description

## Reproduction Steps

1. Run mossy:work {task_id}
2. Task description mentions file {target}
3. File does not exist at expected path

## Impact

- Analysis phase cannot complete
- Task fn-{task_id} blocked

## Resolution Notes

TBD

## Related Issues

None
"""
    write_file(path=f".flow/issues/{issue_id}.md", content=issue_content)
```

### Method 3: Error Handling Wrapper

Create a wrapper function for tool calls:

```bash
# In your skill's bash execution
record_tool_error() {
    local tool="$1"
    local target="$2"
    local error="$3"
    local context="$4"
    
    # Call the recording script
    ./scripts/record-issue.sh \
        --skill "$(basename $0)" \
        --error-type "tool-error" \
        --tool "$tool" \
        --target "$target" \
        --error "$error" \
        --context "$context"
    
    # Optionally log to stderr as well
    echo "ERROR [$tool]: $error" >&2
}

# Usage
if ! read_file "$target"; then
    record_tool_error "read_file" "$target" "$?" "Reading source file"
    # Handle error or exit
fi
```

---

## Naming Convention

### File Name Format

```
<date>-<time>-<skill>-<error-type>-<sequence>.md
```

Components:
- **date**: `YYYYMMDD` format
- **time**: `HHMMSS` format  
- **skill**: Skill name (e.g., `mossy-work`, `mossy-plan`)
- **error-type**: One of:
  - `tool-error` - Tool invocation failed
  - `validation-error` - Input/output validation failed
  - `logic-error` - Internal logic error
  - `resource-error` - Resource unavailable
  - `config-error` - Configuration issue
- **sequence**: 3-digit zero-padded sequence number (000-999)

Examples:
- `20240523-143022-mossy-work-tool-error-001.md`
- `20240523-150100-mossy-refactor-validation-error-002.md`
- `20240523-154530-mossy-analyze-logic-error-003.md`

### ID Generation

Use this bash function for consistent IDs:

```bash
generate_issue_id() {
    local skill="$1"
    local error_type="$2"
    local timestamp
    timestamp=$(date +"%Y%m%d-%H%M%S")
    
    # Count existing issues for this skill+type today
    local date_prefix="${timestamp%%-*}"
    local count
    count=$(find .flow/issues -name "${date_prefix}-*-${skill}-${error_type}-*.md" -type f 2>/dev/null | wc -l)
    
    # Zero-pad to 3 digits
    printf "%s-%s-%s-%s-%03d" "$timestamp" "$skill" "$error_type" "${timestamp##*-}" "$count"
}
```

---

## Severity Levels

| Level | When to Use | Example |
|-------|-------------|---------|
| **critical** | Skill cannot continue, data loss possible | File system error during write, permission denied on critical path |
| **high** | Skill cannot complete current operation, manual intervention needed | Task cannot be claimed, spec file corrupted |
| **medium** | Operation failed but skill can continue with degraded functionality | Non-critical file not found, optional feature unavailable |
| **low** | Minor issue, skill continues normally | Warning-level issues, non-fatal validation problems |

Default: `medium`

---

## Error Type Categories

| Type | Description | Example |
|------|-------------|---------|
| `tool-error` | Vibe tool call failed | read_file on non-existent file |
| `validation-error` | Input/output doesn't match schema | Invalid task ID format |
| `logic-error` | Skill's internal logic failed | Circular dependency detected |
| `resource-error` | External resource unavailable | Git not installed, directory missing |
| `config-error` | Configuration problem | Missing environment variable |

---

## Integration Checklist for Skill Authors

When creating or updating a skill:

- [ ] **Error Handling**: Wrap all tool calls in try-catch/if-then error handling
- [ ] **Recording**: Call `record_issue` or create issue file on any error
- [ ] **Context**: Include sufficient context to reproduce the issue
- [ ] **Documentation**: Add `## Error Recording` section to SKILL.md
- [ ] **Testing**: Verify error recording works by testing with invalid inputs

### Example SKILL.md Integration

```markdown
## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../ISSUE_RECORDING.md).

### Error Types Recorded

- `tool-error`: File operations fail during analysis
- `validation-error`: Spec format doesn't match expected schema
- `logic-error`: Dependency cycle detected in task graph

### Usage

```bash
# Record an error
source scripts/record-issue.sh
record_issue "mossy-plan" "validation-error" "N/A" "specs/fn-1.md" \
  "Invalid spec format: missing Goal section" \
  "Parsing spec file for planning"
```
```

---

## Best Practices

### 1. Record Early, Record Often
Record issues as soon as they're detected, before attempting workarounds.

### 2. Include Full Context
The context section should answer: "How would someone reproduce this?"

### 3. Preserve Error Messages
Always include the complete, unmodified error message.

### 4. Use Consistent Formatting
Follow the template structure for machine parseability.

### 5. Avoid Duplicates
Check for existing similar issues before recording new ones.

### 6. Link Related Issues
Reference related issue files to help with debugging.

---

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

#### mossy-flowctl
Records errors when wrapping flowctl:
```bash
# Resource error: flowctl not found
record_issue "mossy-flowctl" "resource-error" "N/A" "$FLOW_DIR/flowctl" \
    "flowctl not found or not executable" \
    "Phase: detection, Checking flowctl availability"

# Tool error: flowctl command failed
record_issue "mossy-flowctl" "tool-error" "bash" "flowctl start fn-1.1" \
    "flowctl command failed with exit code 1" \
    "Phase: flowctl wrapper, Executing flowctl start"
```

### Language-Specific Skills

#### mossy-cpp
```bash
record_issue "mossy-cpp" "tool-error" "read_file" "src/module.hpp" \
    "read_file failed: permission denied" \
    "Phase: analysis, Reading C++ header file"

record_issue "mossy-cpp" "validation-error" "N/A" "src/main.txt" \
    "Invalid C++ file extension: .txt" \
    "Phase: target resolution, Validating file type"
```

#### mossy-csharp
```bash
record_issue "mossy-csharp" "tool-error" "read_file" "Models/User.cs" \
    "read_file failed: file not found" \
    "Phase: analysis, Reading C# file"

record_issue "mossy-csharp" "resource-error" "N/A" "MyApp.csproj" \
    ".csproj not found in directory" \
    "Phase: context detection, Finding project files"
```

#### mossy-vbnet
```bash
record_issue "mossy-vbnet" "tool-error" "read_file" "Modules/Utils.vb" \
    "read_file failed: permission denied" \
    "Phase: analysis, Reading VB.NET file"

record_issue "mossy-vbnet" "validation-error" "N/A" "app.config" \
    "Invalid VB.NET file extension: .config" \
    "Phase: target resolution, Validating file type"
```

#### mossy-js
```bash
record_issue "mossy-js" "tool-error" "read_file" "src/app.js" \
    "read_file failed: file not found" \
    "Phase: analysis, Reading JavaScript file"

record_issue "mossy-js" "resource-error" "N/A" "package.json" \
    "package.json not found" \
    "Phase: context detection, Finding project context"
```

#### mossy-ts
```bash
record_issue "mossy-ts" "tool-error" "read_file" "src/types.ts" \
    "read_file failed: permission denied" \
    "Phase: analysis, Reading TypeScript file"

record_issue "mossy-ts" "resource-error" "N/A" "tsconfig.json" \
    "tsconfig.json not found" \
    "Phase: context detection, Finding TypeScript config"
```

#### mossy-gdscript
```bash
record_issue "mossy-gdscript" "tool-error" "read_file" "scripts/player.gd" \
    "read_file failed: file not found" \
    "Phase: analysis, Reading GDScript file"

record_issue "mossy-gdscript" "resource-error" "N/A" "project.godot" \
    "project.godot not found" \
    "Phase: context detection, Finding Godot project file"
```

#### mossy-py
```bash
record_issue "mossy-py" "tool-error" "read_file" "app/main.py" \
    "read_file failed: permission denied" \
    "Phase: analysis, Reading Python file"

record_issue "mossy-py" "resource-error" "N/A" "pyproject.toml" \
    "pyproject.toml not found" \
    "Phase: context detection, Finding Python project context"
```

---

## File Structure

```
.flow/
└── issues/
    ├── 20240523-143022-mossy-work-tool-error-001.md
    ├── 20240523-150100-mossy-refactor-validation-error-002.md
    ├── 20240523-154530-mossy-analyze-logic-error-003.md
    ├── ISSUE_TEMPLATE.md  # Template for manual issue creation
    └── README.md          # Auto-generated index of all issues

scripts/
└── record-issue.sh      # Shared recording utility

ISSUE_RECORDING.md       # This guide
```

---

## Example Issue Files

See `.flow/issues/ISSUE_TEMPLATE.md` for the complete template.

---

## Maintenance

### Cleaning Up Issues

Issues in `.flow/issues/` are NOT automatically cleaned up. They should be:

1. **Reviewed regularly** for patterns
2. **Fixed** at the root cause when possible
3. **Archived** by moving to `.flow/issues/archive/` when resolved
4. **Purged** only when they're no longer relevant (e.g., after major refactoring)

### Index Update

The `README.md` in `.flow/issues/` is auto-updated by `record-issue.sh` with new issue links.

---

## Support

For questions about issue recording:
- Check existing issues in `.flow/issues/`
- Refer to this guide
- Ask the user for clarification

---

*This guide is part of the mossy-skills project. See AGENTS.md for more information.*
