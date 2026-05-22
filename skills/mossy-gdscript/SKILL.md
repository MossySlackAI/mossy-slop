---
name: mossy-gdscript
description: GDScript language-specific skill. Handles GDScript file analysis, refactoring, and code generation for Godot Engine.
user-invocable: false
allowed-tools: read_file,write_file,search_replace,grep,bash,ask_user_question,task
---

# mossy-gdscript

GDScript language-specific skill for mossy. Provides Godot Engine-aware analysis and code generation.

## Purpose
Aid in planning and executing code changes for GDScript projects in Godot Engine.

## Input

$ARGUMENTS

Accepts:
- File path: `scripts/player.gd` - Analyze or modify specific GDScript file
- Directory: `scripts/` - Analyze all GDScript files in directory
- Pattern: `--pattern "*.gd"` - Match GDScript files by glob
- `--scene <path>` - Analyze scripts in specific scene
- `--list` - List GDScript-specific features
- `--check <feature>` - Run specific GDScript check

## Flow

1. **Resolve targets**
   - Detect .gd extensions
   - Find project.godot for project context
   - Identify Godot version

2. **Analyze**
   - Parse file structure (extends, signals, exported variables, functions)
   - Detect patterns (scene tree navigation, signal connections)
   - Identify Godot-specific API usage

3. **Execute**
   - Apply GDScript-specific refactorings
   - Generate idiomatic GDScript code
   - Update scene files as needed

4. **Verify**
   - Check syntax with Godot editor
   - Verify signal connections
   - Check node references

## Language-Specific Features

### File Extensions
`.gd`

### Project Files
`project.godot`, `.godot` (import configurations)

### Godot Concepts
- Nodes (Node2D, Node3D, Control, etc.)
- Scenes (.tscn, .scn)
- Resources (.res, .tres)
- Scene tree
- Signals (custom events)
- Groups
- Export variables (@export)
- Node paths
- Singleton (autoload)

### Common Patterns
- _ready() - Called when node enters scene tree
- _process(delta) - Called every frame
- _physics_process(delta) - Called every physics frame
- _input(event) - Called for input events
- Signals: connect, emit_signal
- Node references: get_node(), $Syntax
- Type hints: var x: int
- Constants: const, enum
- setget methods
- @onready var
- @export var
- @warning_ignore

### Pitfalls
- Node not in scene tree (is_inside_tree())
- Signal connections without disconnect
- Memory leaks from circular references
- Process vs Physics process confusion
- Node path changes after scene instantiation
- Missing @onready for node references
- Incorrect signal parameter types
- Thread safety issues (Godot 4+)

### Naming Conventions
- Variables: snake_case
- Functions: snake_case
- Constants: UPPER_SNAKE_CASE
- Classes: PascalCase (GDScript 2.0+)
- Signals: signal_name (snake_case)
- Node references: descriptive names
- Exported variables: descriptive names

### Godot API
- Vector2, Vector3, Vector4
- Rect2
- Color
- Transform2D, Transform3D
- Basis
- Quat
- Array, Dictionary
- PoolIntArray, PoolRealArray, PoolStringArray, PoolVector2Array, etc.
- Node class hierarchy
- Resource class hierarchy

## Commands for Users

- `/mossy:gdscript scripts/player.gd` - Analyze GDScript file
- `/mossy:gdscript scripts/` - Analyze GDScript directory
- `/mossy:gdscript --scene player.tscn` - Analyze scene scripts
- `/mossy:gdscript --check signals` - Check signal usage
- `/mossy:gdscript --refactor` - Refactor GDScript code
- `/mossy:gdscript --export` - Check exported variables

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during analysis | read_file on .gd file, grep for patterns fails |
| validation-error | GDScript specific validation fails | Invalid file extension, missing project.godot |
| logic-error | Internal analysis logic fails | Scene tree parsing error, node resolution failure |
| resource-error | Required resources missing | project.godot not found, Godot editor not available |
| configuration-error | Environment misconfiguration | Godot version mismatch, missing export plugins |

### Integration

```bash
# At skill start, source the recording utility
source scripts/record-issue.sh 2>/dev/null || true

# When a tool fails during analysis
if ! read_file path="$gd_file" 2>/dev/null; then
    record_issue "mossy-gdscript" "tool-error" "read_file" "$gd_file" \
        "read_file failed: file not found or permission denied" \
        "Phase: analysis, Reading GDScript file for analysis" || true
fi

# When file extension is invalid
if [[ "$file_ext" != ".gd" ]]; then
    record_issue "mossy-gdscript" "validation-error" "N/A" "$gd_file" \
        "Invalid GDScript file extension: $file_ext" \
        "Phase: target resolution, Validating file type" || true
fi
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## Guardrails

- Always use @onready for node references that need to be ready
- Always check is_inside_tree() before accessing scene tree
- Use signals instead of direct function calls for decoupling
- Document exported variables
- Use type hints for better editor support
- Warn about process/physics_process in wrong context
- Warn about node references without @onready
- Respect Godot version differences
