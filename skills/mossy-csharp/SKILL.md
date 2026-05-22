---
name: mossy-csharp
description: C# language-specific skill. Handles C# file analysis, refactoring, and code generation with .NET awareness.
user-invocable: false
allowed-tools: read_file,write_file,search_replace,grep,bash,ask_user_question,task
---

# mossy-csharp

C# language-specific skill for mossy. Provides C#-aware analysis and code generation.

## Purpose
Aid in planning and executing code changes for C# projects with .NET ecosystem awareness.

## Input

$ARGUMENTS

Accepts:
- File path: `src/Module.cs` - Analyze or modify specific C# file
- Directory: `src/` - Analyze all C# files in directory
- Pattern: `--pattern "*.cs"` - Match C# files by glob
- `--project <path>` - Analyze specific .csproj
- `--list` - List C#-specific features
- `--check <feature>` - Run specific C# check

## Flow

1. **Resolve targets**
   - Detect .cs extensions
   - Find .csproj, .sln files for project context
   - Identify NuGet packages

2. **Analyze**
   - Parse file structure (namespaces, classes, interfaces, structs, enums)
   - Detect patterns (async/await, LINQ, dependency injection)
   - Identify pitfalls (null references, IDisposable misuse)

3. **Execute**
   - Apply C#-specific refactorings
   - Generate idiomatic C# code
   - Update .csproj files as needed

4. **Verify**
   - Check compilation with dotnet build
   - Run static analysis if available
   - Verify naming conventions

## Language-Specific Features

### File Extensions
`.cs`, `.csx`

### Project Files
`.csproj`, `.sln`, `.props`

### Common Patterns
- async/await
- LINQ (Language Integrated Query)
- Dependency Injection
- Properties (get/set, init, auto-implemented)
- Events and delegates
- Attribute-based programming
- Extension methods
- Anonymous types
- Tuple deconstruction
- Pattern matching (switch expressions, type patterns)
- Records (C# 9+)
- Nullable reference types (C# 8+)
- File-scoped namespaces (C# 10+)

### Pitfalls
- NullReferenceException (use nullable reference types)
- Missing IDisposable implementation
- Async void methods
- Blocking calls in async code
- Missing await
- Thread safety issues
- Improper equality comparison
- Missing XML documentation
- Public fields (use properties)
- Large objects on stack (stackalloc misuse)

### Naming Conventions
- Classes: PascalCase
- Interfaces: IPascalCase
- Methods: PascalCase
- Properties: PascalCase
- Fields: _camelCase (private), PascalCase (public static readonly)
- Parameters: camelCase
- Local variables: camelCase
- Constants: UPPER_SNAKE_CASE

### .NET Features
- Collections: List<T>, Dictionary<TKey, TValue>, HashSet<T>
- LINQ: Where, Select, Any, First, FirstOrDefault
- Async: Task, Task<T>, ValueTask, ValueTask<T>
- DI: IServiceCollection, IServiceProvider
- Serialization: System.Text.Json, Newtonsoft.Json
- Logging: ILogger<T>
- Configuration: IConfiguration

## Commands for Users

- `/mossy:csharp src/Module.cs` - Analyze C# file
- `/mossy:csharp src/` - Analyze C# directory
- `/mossy:csharp --project MyApp.csproj` - Analyze project
- `/mossy:csharp --check async` - Check async/await usage
- `/mossy:csharp --refactor` - Refactor C# code

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during analysis | read_file on .cs file, grep for patterns fails |
| validation-error | C# specific validation fails | Invalid file extension, unsupported project type, missing .csproj |
| logic-error | Internal analysis logic fails | Symbol resolution failure, type inference error |
| resource-error | Required resources missing | .csproj not found, NuGet packages missing |
| configuration-error | Environment misconfiguration | .NET SDK not installed, Roslyn analyzer not available |

### Integration

```bash
# At skill start, source the recording utility
source scripts/record-issue.sh 2>/dev/null || true

# When a tool fails during analysis
if ! read_file path="$cs_file" 2>/dev/null; then
    record_issue "mossy-csharp" "tool-error" "read_file" "$cs_file" \
        "read_file failed: file not found or permission denied" \
        "Phase: analysis, Reading C# file for analysis" || true
fi

# When file extension is invalid
if [[ "$file_ext" != ".cs" && "$file_ext" != ".csx" ]]; then
    record_issue "mossy-csharp" "validation-error" "N/A" "$cs_file" \
        "Invalid C# file extension: $file_ext" \
        "Phase: target resolution, Validating file type" || true
fi
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## Guardrails

- Always implement IDisposable for resources
- Use async/await for I/O operations
- Prefer ValueTask over Task for high-performance scenarios
- Use nullable reference types
- Document public APIs with XML comments
- Use dotnet format if available
- Warn about synchronous I/O in async methods
- Respect C# version in project file
