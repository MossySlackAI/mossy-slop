---
name: mossy:py
description: Python language-specific skill for analysis, refactoring, and code generation.
axis: 1
argument-hint: "<file|directory> [--pattern <glob>|--package <name>|--check <feature>|--list]"
---

# IMPORTANT: Invoke skill `mossy-py`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

- `/mossy:py src/module.py` - Analyze Python file
- `/mossy:py src/` - Analyze Python directory
- `/mossy:py --pattern "*.py"` - Analyze Python files by pattern
- `/mossy:py --package mypackage` - Analyze specific package
- `/mossy:py --check types` - Check type hints
- `/mossy:py --list` - List Python-specific features
- `/mossy:py --refactor` - Refactor Python code
- `/mossy:py --async` - Convert to async/await
- `/mossy:py --typing` - Add type hints

## Supported Features

| Feature | Description |
|---------|-------------|
| File Analysis | Parse imports, classes, functions, decorators |
| Pattern Detection | List comprehensions, generators, context managers |
| Pitfall Detection | Mutable defaults, late binding closures, circular imports |
| Refactoring | Add type hints, convert to async, PEP 8 compliance |
| Project Awareness | setup.py, pyproject.toml, poetry, pipenv |

## File Extensions
`.py`, `.pyw` (Windows), `.pyx` (Cython), `.pyi` (type stub)
