---
name: mossy-vbnet
description: VB.NET language-specific skill for .NET analysis, refactoring, and code generation.
axis: 1
argument-hint: "<file|directory> [--pattern <glob>|--project <path>|--check <feature>|--list]"
---

# IMPORTANT: Invoke skill `mossy-vbnet`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

- `/mossy:vbnet src/Module.vb` - Analyze VB.NET file
- `/mossy:vbnet src/` - Analyze VB.NET directory
- `/mossy:vbnet --pattern "*.vb"` - Analyze VB.NET files by pattern
- `/mossy:vbnet --project MyApp.vbproj` - Analyze specific project
- `/mossy:vbnet --check events` - Check event handling
- `/mossy:vbnet --list` - List VB.NET-specific features
- `/mossy:vbnet --refactor` - Refactor VB.NET code

## Supported Features

| Feature | Description |
|---------|-------------|
| File Analysis | Parse namespaces, classes, modules, interfaces |
| Pattern Detection | Event handling, LINQ, COM interop |
| Pitfall Detection | Case sensitivity, late binding, Option Strict Off |
| Refactoring | Add Option Strict, proper event handling |
| Project Awareness | .vbproj, .sln |

## File Extensions
`.vb`
