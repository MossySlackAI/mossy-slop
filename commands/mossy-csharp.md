---
name: mossy:csharp
description: C# language-specific skill for .NET analysis, refactoring, and code generation.
axis: 1
argument-hint: "<file|directory> [--pattern <glob>|--project <path>|--check <feature>|--list]"
---

# IMPORTANT: Invoke skill `mossy-csharp`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

- `/mossy:csharp src/Module.cs` - Analyze C# file
- `/mossy:csharp src/` - Analyze C# directory
- `/mossy:csharp --pattern "*.cs"` - Analyze C# files by pattern
- `/mossy:csharp --project MyApp.csproj` - Analyze specific project
- `/mossy:csharp --check async` - Check async/await usage
- `/mossy:csharp --list` - List C#-specific features
- `/mossy:csharp --refactor` - Refactor C# code

## Supported Features

| Feature | Description |
|---------|-------------|
| File Analysis | Parse namespaces, classes, interfaces, structs, enums |
| Pattern Detection | async/await, LINQ, dependency injection |
| Pitfall Detection | Null references, IDisposable misuse, async void |
| Refactoring | Add nullable reference types, implement IDisposable |
| Project Awareness | .csproj, .sln, .props |

## File Extensions
`.cs`, `.csx`
