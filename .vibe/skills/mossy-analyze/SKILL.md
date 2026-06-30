---
name: mossy-slop:analyze
description: "Analyze code across languages for security vulnerabilities, quality issues, and style violations"
user-invocable: false
allowed-tools: read_file,grep,bash,ask_user_question,task
---

# mossy-analyze

This is a leaner alternative to flow-next, compatible with Mistral Vibe.

The focus is the code; code is the single source of truth, it should be able to speak for itself. Inline comments provide the documentation.

The human retains full control and responsibility. They can verify the quality of individual steps during or after processing.

It is the user's choice whether individual steps are committed to git, and whether auto-generated plan metadata gets committed or not.

When questions arise during processing, they are logged to human-readable output immediately but processing continues; open questions are asked in bulk at the end.

Speed and token conservation are valued higher than exhaustive question discovery.

## Analyze

Static analysis across C++, C#, VB.NET, JavaScript, TypeScript, GDScript, and Python.

## Input

$ARGUMENTS

Accepts:
- File path: `src/module.py` - Analyze specific file
- Directory: `src/` - Analyze all files in directory
- Pattern: `--pattern "*.py"` - Analyze files matching glob
- `--list` - List available checks
- `--check <check-name>` - Run specific check only
- `--language <lang>` - Only analyze files of specific language
- `--quick` - Quick analysis (basic checks only)
- `--security` - Security-focused analysis
- `--style` - Style/lint checks only
- `--full` - Full analysis (default)

## Flow

1. **Resolve targets**
   - If file: analyze single file
   - If directory: find all source files recursively
   - If pattern: glob match for files
   - Detect language from file extension

2. **Select checks**
   - If `--check <name>`: run only that check
   - If `--security`: run security checks only
   - If `--style`: run style checks only
   - If `--quick`: run basic subset of checks
   - If `--full` or default: run all checks

3. **Analyze**
   - Read each file
   - Run selected checks per language
   - Collect issues with severity, location, description

4. **Report**
   - Group issues by severity (CRITICAL, MAJOR, MINOR, STYLE)
   - Group issues by file
   - Generate summary statistics
   - Output report

5. **Exit**
   - Never modify files
   - User decides what to do with findings

## Checks by Category

### Code Quality
- Function length (>50 lines)
- File length (>500 lines)
- Cyclomatic complexity (nesting depth >4)
- Duplicate code (exact match >10 lines)
- Unused imports/variables
- Dead code (unreachable)

### Security
- Hardcoded secrets (API keys, passwords)
- SQL injection patterns
- XSS patterns
- Insecure deserialization
- Missing input validation
- Missing auth/authz

### Correctness
- Null/undefined handling
- Boundary condition checks
- Error handling presence
- Return value usage
- Type safety issues

### Performance
- N+1 query patterns
- Loop inefficiencies
- Large data copies
- Blocking I/O in hot paths
- Missing caching

### Style
- Line length (>120 chars)
- Consistent indentation
- Naming conventions
- Trailing whitespace
- Mixed tabs/spaces

## Language-Specific Checks

### C++
- Memory management (raw pointers vs smart pointers)
- RAII compliance
- Const correctness
- Exception safety
- Standard library usage
- Include guards
- Class size (excessive)

### C#
- async/await patterns
- IDisposable usage
- Null reference checks
- LINQ usage
- Exception handling
- Public field exposure

### VB.NET
- COM interop patterns
- Event handling
- Disposable patterns
- XML documentation
- Case sensitivity

### JavaScript
- Promise handling
- async/await patterns
- Event emitter usage
- Module imports
- Type checking (pre-TypeScript)

### TypeScript
- Type safety
- Null/undefined checks
- Generic usage
- Decorator usage
- Module resolution

### GDScript
- Signal usage
- Node references
- Scene tree structure
- Godot conventions
- Ready() usage

### Python
- PEP 8 compliance
- Type hints usage
- async/await patterns
- Context manager usage
- Exception handling
- Import organization

## Output Format

```markdown
# Analysis Report: <target>

**Target:** <file|directory|pattern>
**Files Analyzed:** <count>
**Timestamp:** <datetime>
**Checks Run:** <list>

## Summary
- Issues Found: <count>
- CRITICAL: <count>
- MAJOR: <count>
- MINOR: <count>
- STYLE: <count>

## Issues by Severity

### CRITICAL
- <file>:<line>: <description> (<check-name>)

### MAJOR
- <file>:<line>: <description> (<check-name>)

### MINOR
- <file>:<line>: <description> (<check-name>)

### STYLE
- <file>:<line>: <description> (<check-name>)

## Issues by File
- <file>: <count> issues (<severity breakdown>)

## Checks Performed
- <check-name>: <count> findings

## Language Breakdown
- <language>: <files> files, <issues> issues
```

## Available Checks

Run `--list` to see all available checks with descriptions.

| Check | Category | Languages | Description |
|-------|----------|-----------|-------------|
| long-function | Quality | All | Functions >50 lines |
| long-file | Quality | All | Files >500 lines |
| deep-nesting | Quality | All | Nesting >4 levels |
| duplicate-code | Quality | All | Exact code duplication |
| unused-import | Quality | All | Unused import statements |
| hardcoded-secret | Security | All | API keys, passwords in code |
| sql-injection | Security | All | SQL string concatenation |
| xss | Security | JS/TS | InnerHTML assignment |
| null-check | Correctness | All | Missing null/undefined handling |
| error-handling | Correctness | All | Missing error handling |
| long-line | Style | All | Lines >120 characters |
| mixed-tabs | Style | All | Mixed tabs and spaces |
| trailing-whitespace | Style | All | Trailing whitespace |

## Workspace Structure

Analysis reports stored in:
```
.flow/
└── analysis/
    └── <timestamp>-<target>/
        ├── report.md          # Human-readable report
        ├── issues.json        # Machine-readable issues
        └── by-file/
            └── <file>.md      # Per-file details
```

## Git Integration

Can analyze git changes:
```bash
# Analyze unstaged changes
git diff --name-only | xargs mossy-analyze

# Analyze staged changes  
git diff --staged --name-only | xargs mossy-analyze

# Analyze specific commit
git show <commit> --name-only | xargs mossy-analyze
```

## Commands for Users

- `/mossy-slop:analyze src/main.py` - Analyze file
- `/mossy-slop:analyze src/` - Analyze directory
- `/mossy-slop:analyze --pattern "*.py"` - Analyze by pattern
- `/mossy-slop:analyze --list` - List available checks
- `/mossy-slop:analyze --check long-function` - Run specific check
- `/mossy-slop:analyze --language python` - Analyze only Python files
- `/mossy-slop:analyze --security` - Security-focused analysis
- `/mossy-slop:analyze --style` - Style checks only
- `/mossy-slop:analyze --quick` - Quick basic checks
- `/mossy-slop:analyze --full` - Full analysis (default)

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](mossy-scripts/ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during analysis | read_file on source file, grep pattern error, bash command fails |
| validation-error | Analysis input invalid | Invalid file path, unsupported language, missing required parameters |
| logic-error | Internal analysis logic fails | Check implementation error, result processing failure |
| resource-error | Required resources missing | .flow/analysis/ directory creation fails, source directory not found |
| configuration-error | Environment misconfiguration | Missing analysis tools, incompatible configurations |

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## GUARDRAILS

- Never modify source files
- Never auto-fix issues (user decision only)
- All findings documented in report
- User makes final decision on all issues
- Questions collected and asked in bulk at end (header max: 11 chars)
- CRITICAL issues reported immediately
- Workspace preserved for user inspection
- Evidence always captured for findings
- Use `flowctl.sh`
- You MUST use the `ask_user_question` tool for every question that requires user judgment.
