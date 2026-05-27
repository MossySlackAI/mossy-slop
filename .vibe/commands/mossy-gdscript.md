---
name: mossy-gdscript
description: GDScript language-specific skill for Godot Engine analysis, refactoring, and code generation.
axis: 1
argument-hint: "<file|directory> [--pattern <glob>|--scene <path>|--check <feature>|--list]"
---

# IMPORTANT: Invoke skill `mossy-gdscript`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

- `/mossy:gdscript scripts/player.gd` - Analyze GDScript file
- `/mossy:gdscript scripts/` - Analyze GDScript directory
- `/mossy:gdscript --pattern "*.gd"` - Analyze GDScript files by pattern
- `/mossy:gdscript --scene player.tscn` - Analyze scene scripts
- `/mossy:gdscript --check signals` - Check signal usage
- `/mossy:gdscript --list` - List GDScript-specific features
- `/mossy:gdscript --refactor` - Refactor GDScript code
- `/mossy:gdscript --export` - Check exported variables

## Supported Features

| Feature | Description |
|---------|-------------|
| File Analysis | Parse extends, signals, exported variables, functions |
| Pattern Detection | Scene tree navigation, signal connections, node references |
| Pitfall Detection | Node not in tree, missing @onready, signal connection leaks |
| Refactoring | Add @onready, use signals, type hints |
| Project Awareness | project.godot, Godot version, scene files |

## File Extensions
`.gd`
