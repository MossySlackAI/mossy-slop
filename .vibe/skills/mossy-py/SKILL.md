---
name: mossy-py
description: Python language-specific skill. Handles Python file analysis, refactoring, and code generation.
user-invocable: false
allowed-tools: read_file,write_file,search_replace,grep,bash,ask_user_question,task
---

# mossy-py

Python language-specific skill for mossy. Provides Python-aware analysis and code generation.

## Purpose
Aid in planning and executing code changes for Python projects.

## Input

$ARGUMENTS

Accepts:
- File path: `src/module.py` - Analyze or modify specific Python file
- Directory: `src/` - Analyze all Python files in directory
- Pattern: `--pattern "*.py"` - Match Python files by glob
- `--package <name>` - Analyze specific package
- `--list` - List Python-specific features
- `--check <feature>` - Run specific Python check

## Flow

1. **Resolve targets**
   - Detect .py, .pyw, .pyx (Cython), .pyi (stub) extensions
   - Find setup.py, pyproject.toml, setup.cfg for project context
   - Identify dependencies

2. **Analyze**
   - Parse file structure (imports, classes, functions, decorators)
   - Detect patterns (list comprehensions, generators, context managers)
   - Identify pitfalls (mutable defaults, late binding closures)

3. **Execute**
   - Apply Python-specific refactorings
   - Generate idiomatic Python code
   - Update dependency files as needed

4. **Verify**
   - Lint with flake8, pylint, or ruff if available
   - Type check with mypy if available
   - Verify PEP 8 compliance

## Language-Specific Features

### File Extensions
`.py`, `.pyw` (Windows), `.pyx` (Cython), `.pyi` (type stub)

### Project Files
`setup.py`, `pyproject.toml`, `setup.cfg`, `requirements.txt`, `poetry.lock`, `Pipfile`

### Common Patterns
- List comprehensions
- Dictionary comprehensions
- Generator expressions
- Generators (yield, yield from)
- Context managers (with statement)
- Decorators (@decorator)
- Properties (@property, @x.setter)
- Class methods (@classmethod)
- Static methods (@staticmethod)
- Abstract base classes (ABC, @abstractmethod)
- Type hints (Python 3.5+)
- Dataclasses (@dataclass)
- Named tuples
- Enum classes
- Async/await (Python 3.5+)
- Type hints (Python 3.5+)
- Pattern matching (Python 3.10+)

### Pitfalls
- Mutable default arguments
- Late binding closures
- Variable shadowing
- Circular imports
- GIL (Global Interpreter Lock) limitations
- Memory management (reference counting)
- Implicit type conversion
- Integer division (Python 2 vs 3)
- String encoding issues
- Pickle security issues

### Naming Conventions
- Variables: snake_case
- Functions: snake_case
- Classes: PascalCase or CapWords
- Methods: snake_case
- Constants: UPPER_SNAKE_CASE
- Modules: snake_case (file names)
- Packages: snake_case (directory names)
- Private members: _single_underscore (protected), __double_underscore (name mangling)
- Dunder methods: __method__
- Type variables: T, U, V (PEP 484)

### Standard Library
- Built-in types: list, dict, set, tuple, str, int, float, bool, bytes
- Collections: deque, defaultdict, Counter, OrderedDict, ChainMap
- Itertools: count, cycle, repeat, product, permutations, combinations
- Functools: partial, wraps, lru_cache, reduce, singledispatch
- Contextlib: contextmanager, ExitStack, suppress
- Datetime: datetime, date, time, timedelta, timezone
- Pathlib: Path
- Typing: List, Dict, Set, Tuple, Optional, Union, TypeVar, Generic
- Asyncio: coroutines, events, futures, streams
- Concurrent.futures: ThreadPoolExecutor, ProcessPoolExecutor

### Packaging
- pip
- setuptools
- wheel
- poetry
- pipenv
- hatch
- pdm

## Commands for Users

- `/mossy:py src/module.py` - Analyze Python file
- `/mossy:py src/` - Analyze Python directory
- `/mossy:py --check types` - Check type hints
- `/mossy:py --refactor` - Refactor Python code
- `/mossy:py --async` - Convert to async/await
- `/mossy:py --typing` - Add type hints

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../mossy-scripts/ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during analysis | read_file on .py file, grep for patterns fails |
| validation-error | Python specific validation fails | Invalid file extension, missing setup.py/pyproject.toml |
| logic-error | Internal analysis logic fails | Import resolution failure, symbol analysis error |
| resource-error | Required resources missing | Requirements file not found, Python interpreter not available |
| configuration-error | Environment misconfiguration | Missing linter (flake8/pylint/ruff), mypy not installed |

### Integration

```bash
# At skill start, call required utilities
../mossy-scripts/ensure-flow-dir.sh >/dev/null 2>&1 || true

# When a tool fails during analysis
if ! read_file path="$py_file" 2>/dev/null; then
    ../mossy-scripts/record-issue.sh --skill "mossy-py" --error-type "tool-error" \
        --tool "read_file" --target "$py_file" \
        --error "read_file failed: file not found or permission denied" \
        --context "Phase: analysis, Reading Python file for analysis" || true
fi

# When file extension is invalid
if [[ ! "$file_ext" =~ \.(py|pyw|pyx|pyi)$ ]]; then
    ../mossy-scripts/record-issue.sh --skill "mossy-py" --error-type "validation-error" \
        --tool "N/A" --target "$py_file" \
        --error "Invalid Python file extension: $file_ext" \
        --context "Phase: target resolution, Validating file type" || true
fi
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## Guardrails

- Follow PEP 8 style guide
- Use type hints for public APIs
- Use context managers for resource management
- Avoid mutable default arguments
- Prefer list comprehensions over loops for simple transformations
- Use pathlib over os.path for file operations
- Use f-strings for string formatting (Python 3.6+)
- Use dataclasses for data containers
- Use typing.Protocol for structural subtyping
- Warn about bare except clauses
- Warn about print() statements in production code
- Warn about TODO and FIXME comments
- Questions via ask_user_question: header max 11 characters
