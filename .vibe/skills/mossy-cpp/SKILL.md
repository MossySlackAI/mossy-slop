---
name: mossy-cpp
description: C++ language-specific skill. Handles C++ file analysis, refactoring, and code generation with language awareness.
user-invocable: false
allowed-tools: read_file,write_file,search_replace,grep,bash,ask_user_question,task
---

# mossy-cpp

C++ language-specific skill for mossy. Provides C++-aware analysis, refactoring, and code generation.

## Purpose
Aid in planning and executing code changes for C++ projects with language-specific awareness.

## Input

$ARGUMENTS

Accepts:
- File path: `src/module.cpp` - Analyze or modify specific C++ file
- Directory: `src/` - Analyze all C++ files in directory
- Pattern: `--pattern "*.cpp"` - Match C++ files by glob
- `--list` - List C++-specific features
- `--check <feature>` - Run specific C++ check

## Flow

1. **Resolve targets**
   - Detect .cpp, .h, .hpp, .cc, .cxx, .hxx extensions
   - Find CMakeLists.txt, Makefile for project context
   - Identify include directories

2. **Analyze**
   - Parse file structure (includes, namespaces, classes, functions)
   - Detect patterns (RAII, smart pointers, STA/MT safety)
   - Identify pitfalls (raw pointers, manual memory management)

3. **Execute**
   - Apply C++-specific refactorings
   - Generate idiomatic C++ code
   - Update build files as needed

4. **Verify**
   - Check compilation with clang++/g++
   - Run static analysis (clang-tidy if available)
   - Verify naming conventions

## Language-Specific Features

### File Extensions
`.cpp`, `.h`, `.hpp`, `.cc`, `.cxx`, `.hxx`, `.ipp`

### Build Systems
CMake, Make, Bazel, Ninja, Meson

### Common Patterns
- RAII (Resource Acquisition Is Initialization)
- Smart pointers (unique_ptr, shared_ptr, weak_ptr)
- Move semantics
- Const correctness
- Exception safety (basic, strong, nothrow)
- PImpl idiom
- CRTP (Curiously Recurring Template Pattern)
- Type traits
- SFINAE
- Concepts (C++20+)

### Pitfalls
- Raw pointer ownership ambiguity
- Manual memory management
- Missing virtual destructors
- Slicing
- Dangling references/pointers
- Thread safety issues
- Undefined behavior (signed overflow, null dereference)
- ODR violations
- Include guards missing
- Cyclic dependencies

### Naming Conventions
- Classes: PascalCase
- Functions: snake_case or camelCase
- Variables: snake_case
- Constants: UPPER_SNAKE_CASE
- Private members: m_ prefix or trailing underscore
- Template parameters: single uppercase letter (T, U, V)

### Standard Library
- Containers: vector, map, unordered_map, set, unordered_set
- Algorithms: std::sort, std::find, std::transform
- Smart pointers: unique_ptr, shared_ptr, weak_ptr
- Filesystem (C++17+)
- Threading: std::thread, std::mutex, std::atomic

## Commands for Users

- `/mossy:cpp src/module.cpp` - Analyze C++ file
- `/mossy:cpp src/` - Analyze C++ directory
- `/mossy:cpp --pattern "*.hpp"` - Analyze header files
- `/mossy:cpp --check raii` - Check RAII compliance
- `/mossy:cpp --refactor` - Refactor C++ code

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during analysis | read_file on header/source file, grep for patterns fails |
| validation-error | C++ specific validation fails | Invalid file extension, unsupported build system |
| logic-error | Internal analysis logic fails | AST parsing error, symbol resolution failure |
| resource-error | Required resources missing | CMakeLists.txt not found, include directories missing |
| configuration-error | Environment misconfiguration | Compiler not installed, clang-tidy not available |

### Integration

```bash
# At skill start, call required utilities
../mossy-scripts/ensure-flow-dir.sh >/dev/null 2>&1 || true

# When a tool fails during analysis
if ! read_file path="$cpp_file" 2>/dev/null; then
    ../mossy-scripts/record-issue.sh --skill "mossy-cpp" --error-type "tool-error" \
        --tool "read_file" --target "$cpp_file" \
        --error "read_file failed: file not found or permission denied" \
        --context "Phase: analysis, Reading C++ file for analysis" || true
fi

# When file extension is invalid
if [[ ! "$file_ext" =~ \.(cpp|h|hpp|cc|cxx|hxx|ipp)$ ]]; then
    ../mossy-scripts/record-issue.sh --skill "mossy-cpp" --error-type "validation-error" \
        --tool "N/A" --target "$cpp_file" \
        --error "Invalid C++ file extension: $file_ext" \
        --context "Phase: target resolution, Validating file type" || true
fi
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## Guardrails

- Never modify include order without reason
- Always prefer standard library over custom implementations
- Respect const correctness
- Use smart pointers over raw pointers for ownership
- Always provide move operations when move semantics make sense
- Document template parameters
- Use clang-format if .clang-format exists
- Warn about non-standard extensions
- Questions via ask_user_question: header max 11 characters
