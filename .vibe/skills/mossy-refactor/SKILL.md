---
name: mossy-refactor
description: "Language-aware code refactoring: extract functions, rename symbols, restructure code across languages"
user-invocable: false
allowed-tools: read_file,write_file,search_replace,grep,bash,ask_user_question,task
---

# mossy-refactor

This is a leaner alternative to flow-next, compatible with Mistral Vibe.

The focus is the code; code is the single source of truth, it should be able to speak for itself. Inline comments provide the documentation.

The human retains full control and responsibility. They can verify the quality of individual steps during or after processing.

It is the user's choice whether individual steps are committed to git, and whether auto-generated plan metadata gets committed or not.

When questions arise during processing, they are logged to human-readable output immediately but processing continues; open questions are asked in bulk at the end.

Speed and token conservation are valued higher than exhaustive question discovery.

## Refactor

Apply language-aware code refactoring transformations.

## Input

$ARGUMENTS

Accepts:
- File path + operation: `src/module.py extract_method ClassName.method 10:20 new_method`
- Directory + operation: `src/ --rename SymbolName NewSymbolName`
- Operation + pattern: `--extract-interface "class.*Implementor"`
- `--interactive` or `--i`: Interactive refactoring session
- `--dry-run` or `--dry`: Preview changes without applying
- `--list` or `--l`: List available refactorings
- `--show <path>`: Show refactoring candidates for file

## Operations

| Operation | Aliases | Description |
|-----------|---------|-------------|
| `extract` | `extract_method`, `extract_function` | Extract code block to new method/function |
| `rename` | `rename_symbol`, `r` | Rename variable, function, class, method |
| `inline` | `inline_function`, `inline_method` | Inline function/method call |
| `move` | `move_file`, `move_class` | Move file or class to new location |
| `pull_up` | `pull_up_method` | Pull method up to parent class |
| `push_down` | `push_down_method` | Push method down to child class |
| `extract_interface` | `extract_abstract` | Extract interface/abstract class from implementation |
| `encapsulate` | `encapsulate_field` | Encapsulate field with getter/setter |
| `replace_type` | `change_type` | Replace type usage throughout codebase |
| `reorder` | `reorder_params` | Reorder function/method parameters |
| `add_param` | `add_parameter` | Add parameter to function/method |
| `remove_param` | `remove_parameter` | Remove parameter from function/method |

## Flow

1. **Parse input**
   - Identify operation, target file(s), and parameters
   - Detect language from file extension
   - Validate operation is supported for language

2. **Analyze code**
   - Read target file(s)
   - Parse AST (using language-specific patterns)
   - Identify symbols, scope, dependencies
   - Find refactoring candidates

3. **Validate refactoring**
   - Check preconditions for operation
   - Identify affected files (for rename, move operations)
   - Detect potential conflicts
   - Estimate impact

4. **Preview changes** (if not --dry-run)
   - Show diff of proposed changes
   - List all files to be modified
   - Ask for confirmation before applying

5. **Apply changes**
   - Use search_replace for precise modifications
   - Update all affected files atomically
   - Preserve formatting and comments

6. **Verify**
   - Syntax check (language-specific)
   - Lint check if available
   - Run tests if specified

## Language Support

| Language | Extension | Extract | Rename | Inline | Move | Interface | Encapsulate |
|----------|-----------|---------|--------|--------|------|-----------|------------|
| C++ | .cpp, .hpp, .cc, .hh | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| C# | .cs | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| VB.NET | .vb | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| JavaScript | .js | ✓ | ✓ | ✓ | ✓ | - | ✓ |
| TypeScript | .ts | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| GDScript | .gd | ✓ | ✓ | ✓ | ✓ | - | ✓ |
| Python | .py | ✓ | ✓ | ✓ | ✓ | - | ✓ |

## C++ Refactoring

### Extract Method
```
Input: src/game.cpp extract_method Player::update 15:25 handleInput
```
- Extracts lines 15-25 from Player::update
- Creates new method Player::handleInput
- Updates original method with call to new method
- Respects const, noexcept, override specifiers

### Rename Symbol
```
Input: include/ --rename GameManager GameController
```
- Renames class in header and all includes
- Updates forward declarations
- Updates all call sites
- Handles namespaces

### Move Class
```
Input: src/ --move GameManager new_module/
```
- Moves class definition and implementation
- Updates all include paths
- Updates namespace if needed

## C# Refactoring

### Extract Interface
```
Input: src/Services/ --extract-interface IUserService UserService
```
- Creates IUserService interface
- Extracts public methods from UserService
- UserService implements IUserService
- Updates all call sites to use interface where appropriate

### Encapsulate Field
```
Input: Models/User.cs encapsulate_field _name
```
- Creates public property Name
- Replaces all direct field accesses with property
- Handles backing field naming conventions

## TypeScript Refactoring

### Extract Method
```
Input: src/utils.ts extract_method validateInput 5:12 validate
```
- Extracts lines 5-12 to new function validate
- Preserves type annotations
- Handles async/await

### Rename Symbol
```
Input: src/ --rename UserModel IUser
```
- Updates all imports and exports
- Handles type vs value distinction
- Respects module boundaries

## Python Refactoring

### Extract Method
```
Input: app/main.py extract_method ProcessData.process 8:18 _validate
```
- Extracts block to new method _validate
- Handles self parameter
- Preserves decorators

### Rename Symbol
```
Input: --rename old_function_name new_function_name
```
- Updates function definition
- Updates all call sites
- Handles imports

## Interactive Mode

When invoked with `--interactive` or `--i`:

1. Scan current directory for refactoring opportunities
2. Present categorized list:
   - Long methods (>50 lines)
   - Duplicate code blocks
   - Large files (>500 lines)
   - Poorly named symbols (snake_case in Python, camelCase in JS)
   - Unused parameters
   - God classes (too many methods)

3. User selects category or specific item
4. Preview refactoring
5. Apply or skip
6. Continue until user exits

## Dry Run Mode

With `--dry-run` or `--dry`:
- Analyze and validate refactoring
- Show complete diff of all changes
- Report files to be modified
- Report estimated impact
- Do NOT apply any changes

## file:line Format

Target format for extract operations:
- `file:line` - single line
- `file:start:end` - line range
- `file:line:col` - specific column on line
- `file:start:col:end:col` - character range

## AST Patterns

Language-specific patterns for identifying refactoring targets:

### C++
- Class detection: `class\s+(\w+)`
- Method detection: `(\w+)\s*\([^)]*\)\s*(const\s*)?(noexcept\s*)?()`
- Namespace detection: `namespace\s+(\w+)`

### C#
- Class detection: `class\s+(\w+)`
- Interface detection: `interface\s+(\w+)`
- Property detection: `(\w+)\s+(\w+)\s*\{`

### TypeScript
- Function detection: `(async\s+)?(\w+)\s*\([^)]*\)`
- Class detection: `class\s+(\w+)`
- Interface detection: `interface\s+(\w+)`

### Python
- Function detection: `def\s+(\w+)\s*\(`
- Class detection: `class\s+(\w+)`
- Method detection: `def\s+(\w+)\s*\([^)]*self`

## Validation Rules

Before applying any refactoring:

1. **Syntax Preservation**: Changes must result in valid syntax
2. **Semantics Preservation**: Behavior must remain identical
3. **Scope Awareness**: Respect variable scope and visibility
4. **Dependency Check**: Ensure all dependencies are updated
5. **Test Compatibility**: Changes should not break existing tests
6. **Formatting**: Preserve existing code style

## Error Handling

- Syntax errors in target code: Report and abort
- File not found: Report and abort
- Unsupported operation for language: Report alternatives
- Conflicting changes: Report and ask user to resolve
- Partial application: Roll back all changes

## Integration with flowctl.sh

For spec/task-based refactoring:
```bash
# Get task acceptance criteria
flowctl.sh show <task-id>

# Mark refactoring task complete
flowctl.sh done <task-id> --summary-file .flow/refactors/<id>/summary.md
```

## Workspace Structure

```
.flow/
└── refactors/
    └── <refactor-id>/
        ├── analysis.json      # AST analysis results
        ├── candidates.json    # Refactoring candidates
        ├── preview.diff       # Preview of changes
        ├── summary.md         # Refactoring summary
        └── evidence/          # Test output, logs
```

## Summary Format

```markdown
# Refactor Summary: <operation> <target>

**Language:** <language>
**Files Modified:** <count>
**Lines Changed:** <added>/<removed>
**Timestamp:** <datetime>
**Status:** <applied|dry-run|failed>

## Operation
- **Type:** <operation>
- **Target:** <symbol/file>
- **Parameters:** <params>

## Changes Applied
- `<file>`: <description of change>

## Validation
- Syntax check: PASS/FAIL
- Lint check: PASS/FAIL/NA
- Tests: PASS/FAIL/NA

## Issues Encountered
- <issue>: <description>

## Questions
- <question for user>
```

## Commands for Users

- `/mossy:refactor src/utils.py extract_method process_data 10:20 validate` - Extract method
- `/mossy:refactor --rename OldName NewName` - Rename symbol globally
- `/mossy:refactor src/ --rename ClassName NewName` - Rename in directory
- `/mossy:refactor --extract-interface MyClass` - Extract interface
- `/mossy:refactor --i` - Interactive refactoring session
- `/mossy:refactor --dry src/file.py extract 5:15` - Dry run extraction
- `/mossy:refactor --list` - List available refactorings
- `/mossy:refactor --show src/file.py` - Show refactoring candidates

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](mossy-scripts/ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during refactoring | read_file on target, search_replace pattern not found, write_file permission denied |
| validation-error | Refactoring preconditions not met | Unsupported operation for language, invalid target format |
| logic-error | Internal refactoring logic fails | AST parsing error, scope resolution failure |
| resource-error | Required resources missing | .flow/refactors/ directory creation fails, required build tools missing |
| configuration-error | Environment misconfiguration | Missing language runtime, incompatible tool versions |

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## GUARDRAILS

- Never modify files without explicit operation
- Never apply changes in dry-run mode
- Always preview changes before applying (unless --force)
- Always validate syntax after refactoring
- Preserve all comments and formatting
- User must confirm before applying changes
- Questions collected and asked in bulk at end (header max: 11 chars)
- Blocking issues reported immediately
- Workspace preserved for user inspection
- Roll back on any failure
- **DO NOT call flowctl.py** - use flowctl.sh
