---
name: mossy-slop:refactor
description: Language-aware code refactoring. Extract methods, rename symbols, restructure code across C++, C#, VB.NET, JavaScript, TypeScript, GDScript, and Python.
axis: 1
argument-hint: "<file> <operation> [args] [--i|--dry|--list|--show <path>|--rename <old> <new>]"
---

# IMPORTANT: Invoke skill `mossy-refactor`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

- `/mossy:refactor src/utils.py extract_method process 10:20 validate` - Extract lines 10-20 from process() to new validate() method
- `/mossy:refactor src/ --rename OldClass NewClass` - Rename class in directory
- `/mossy:refactor --rename globalFunction betterName` - Rename symbol globally in project
- `/mossy:refactor --extract-interface MyService` - Extract interface from class
- `/mossy:refactor Models/User.cs encapsulate_field _email` - Create property from field
- `/mossy:refactor --i` - Interactive refactoring session
- `/mossy:refactor --dry src/file.py extract 5:15` - Preview changes without applying
- `/mossy:refactor --list` - List available refactoring operations
- `/mossy:refactor --show src/module.ts` - Show refactoring candidates for file

## Operations

| Command | Description |
|---------|-------------|
| `extract_method <file> <method> <range> <new_name>` | Extract code block to new method |
| `extract_function <file> <range> <new_name>` | Extract code block to new function |
| `--rename <old> <new>` | Rename symbol globally |
| `--rename <old> <new> <dir>` | Rename symbol in directory |
| `--extract-interface <class>` | Extract interface from class |
| `--encapsulate <file> <field>` | Create getter/setter for field |
| `--inline <file> <method>` | Inline method call |
| `--move <symbol> <new_path>` | Move class/file to new location |
| `--pull-up <class> <method> <parent>` | Pull method up to parent |
| `--push-down <class> <method> <child>` | Push method down to child |

## Range Format

- `10:20` - Lines 10 through 20
- `15` - Single line 15
- `8:12` - Lines 8 through 12

## Language Support

C++, C#, VB.NET, JavaScript, TypeScript, GDScript, Python.

## Examples

```
# Extract method from Python file
/mossy:refactor app/main.py extract_method DataProcessor.run 25:45 _validate

# Rename a TypeScript class across project
/mossy:refactor --rename UserManager AccountManager

# Rename C# class in specific directory
/mossy:refactor src/Services/ --rename UserService IUserService

# Extract interface from C++ class
/mossy:refactor include/ --extract-interface Database Connection

# Encapsulate private field in C#
/mossy:refactor Models/Person.cs encapsulate_field _age

# Dry run to preview changes
/mossy:refactor --dry src/utils.ts extract_function 10:20 helper

# Interactive mode - scan and suggest refactorings
/mossy:refactor --i

# Show what can be refactored in a file
/mossy:refactor --show src/engine.cpp

# List all available refactoring operations
/mossy:refactor --list
```

## Workflow

1. **Parse**: Identify operation, target, and parameters
2. **Detect**: Determine language from file extension
3. **Analyze**: Parse code, identify symbols and scope
4. **Validate**: Check preconditions and dependencies
5. **Preview**: Show diff of proposed changes (unless --dry)
6. **Confirm**: Ask user to confirm before applying
7. **Apply**: Make changes with search_replace
8. **Verify**: Syntax check and optionally run tests

## Modes

| Flag | Description |
|------|-------------|
| `--i`, `--interactive` | Interactive session with suggestions |
| `--dry`, `--dry-run` | Preview changes without applying |
| `--list`, `--l` | List available operations |
| `--show <path>` | Show candidates for file |
| `--force` | Skip confirmation (use with caution) |
| `--quiet` | Minimal output |

## Integration

Works with:
- `flowctl.sh` for spec/task-based refactoring
- Git for tracking changes
- Language-specific syntax validation

## Output

- Modified files with refactoring applied
- Summary of changes in `.flow/refactors/<id>/summary.md`
- Diff preview for all modified files
- Validation results (syntax, lint)
