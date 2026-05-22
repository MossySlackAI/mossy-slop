---
name: mossy:analyze
description: Static analysis across languages. Scans code for quality, security, style, and correctness issues.
axis: 1
argument-hint: "<file|directory> [--pattern <glob>|--check <name>|--language <lang>|--list|--quick|--security|--style|--full]"
---

# IMPORTANT: Invoke skill `mossy-analyze`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

- `/mossy:analyze src/main.py` - Analyze specific file
- `/mossy:analyze src/` - Analyze all files in directory
- `/mossy:analyze --pattern "*.py"` - Analyze files matching glob pattern
- `/mossy:analyze --list` - List all available checks
- `/mossy:analyze --check long-function` - Run only long-function check
- `/mossy:analyze --language python` - Analyze only Python files
- `/mossy:analyze --security` - Run security checks only
- `/mossy:analyze --style` - Run style/lint checks only
- `/mossy:analyze --quick` - Quick basic checks
- `/mossy:analyze --full` - Full analysis (default)

## Checks

| Category | Checks |
|----------|--------|
| Code Quality | long-function, long-file, deep-nesting, duplicate-code, unused-import |
| Security | hardcoded-secret, sql-injection, xss, insecure-deserialize |
| Correctness | null-check, error-handling, boundary-check, type-safety |
| Performance | n-plus-1, loop-efficiency, large-copy, blocking-io |
| Style | long-line, mixed-tabs, trailing-whitespace, naming-convention |

## Language Support

C++, C#, VB.NET, JavaScript, TypeScript, GDScript, Python.

## Examples

```
# Analyze a single file
/mossy:analyze app/models/user.py

# Analyze a directory recursively
/mossy:analyze src/

# Analyze all Python files
/mossy:analyze --pattern "**.py"

# Security audit
/mossy:analyze src/ --security

# Style checks only
/mossy:analyze --style src/

# Run specific check
/mossy:analyze --check long-function src/

# Quick analysis (basic checks)
/mossy:analyze --quick .

# List all available checks
/mossy:analyze --list
```

## Output

Structured analysis report with:
- Summary statistics
- Issues grouped by severity (CRITICAL, MAJOR, MINOR, STYLE)
- Issues grouped by file
- Checks performed
- Language breakdown

## Modes

| Mode | Flag | Checks | Speed |
|------|------|--------|-------|
| Full | `--full` (default) | All checks | Slow |
| Quick | `--quick` | Basic quality + style | Fast |
| Security | `--security` | Security checks only | Medium |
| Style | `--style` | Style checks only | Fast |

## Integration

Works with:
- Git for file discovery
- Language-specific parsers via grep patterns
- Existing lint tools when available
