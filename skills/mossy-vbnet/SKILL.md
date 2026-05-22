---
name: mossy-vbnet
description: VB.NET language-specific skill. Handles VB.NET file analysis, refactoring, and code generation.
user-invocable: false
allowed-tools: read_file,write_file,search_replace,grep,bash,ask_user_question,task
---

# mossy-vbnet

VB.NET language-specific skill for mossy. Provides VB.NET-aware analysis and code generation.

## Purpose
Aid in planning and executing code changes for VB.NET projects with .NET ecosystem awareness.

## Input

$ARGUMENTS

Accepts:
- File path: `src/Module.vb` - Analyze or modify specific VB.NET file
- Directory: `src/` - Analyze all VB.NET files in directory
- Pattern: `--pattern "*.vb"` - Match VB.NET files by glob
- `--project <path>` - Analyze specific .vbproj
- `--list` - List VB.NET-specific features
- `--check <feature>` - Run specific VB.NET check

## Flow

1. **Resolve targets**
   - Detect .vb extensions
   - Find .vbproj, .sln files for project context
   - Identify NuGet packages

2. **Analyze**
   - Parse file structure (namespaces, classes, modules, interfaces)
   - Detect patterns (event handling, COM interop, LINQ)
   - Identify pitfalls (case sensitivity, late binding)

3. **Execute**
   - Apply VB.NET-specific refactorings
   - Generate idiomatic VB.NET code
   - Update .vbproj files as needed

4. **Verify**
   - Check compilation with dotnet build
   - Verify naming conventions

## Language-Specific Features

### File Extensions
`.vb`

### Project Files
`.vbproj`, `.sln`, `.vbhtml` (Razor)

### Common Patterns
- Event handling (Handles clause, AddHandler/RemoveHandler)
- Delegates (Declare, AddressOf)
- Modules (shared methods and variables)
- Properties (Get/Set, Auto-Implemented)
- LINQ (same operators as C#)
- Async/Await
- XML literals
- Late binding (Option Strict Off)
- My namespace (application model)
- COM interop (MarshalAs, ComClass)

### Pitfalls
- Case insensitivity issues
- Late binding performance overhead
- Option Strict Off leading to runtime errors
- Missing event handler removal (memory leaks)
- Improper COM object release
- Thread safety issues (STA thread requirements)
- Improper exception handling
- Public fields (should be properties)

### Naming Conventions
- Classes: PascalCase
- Interfaces: IPascalCase
- Methods: PascalCase
- Properties: PascalCase
- Variables: camelCase or _camelCase
- Constants: UPPER_SNAKE_CASE or PascalCase
- Events: EventName (PascalCase)
- Delegates: DelegateName (PascalCase)

### VB.NET Features
- Collections: List(Of T), Dictionary(Of TKey, TValue)
- LINQ: same as C#
- Async: same as C#
- My namespace: My.Application, My.Computer, My.Settings, My.User
- XML: XML literals, axis properties
- Exception handling: Try/Catch/Finally, Catch When

## Commands for Users

- `/mossy:vbnet src/Module.vb` - Analyze VB.NET file
- `/mossy:vbnet src/` - Analyze VB.NET directory
- `/mossy:vbnet --project MyApp.vbproj` - Analyze project
- `/mossy:vbnet --check events` - Check event handling
- `/mossy:vbnet --refactor` - Refactor VB.NET code

## Guardrails

- Always use Option Strict On
- Always use Option Explicit On
- Handle events properly (add/remove)
- Use Try/Catch for error handling
- Document public APIs with XML comments
- Warn about late binding
- Respect VB.NET case sensitivity settings
- Use My namespace appropriately
