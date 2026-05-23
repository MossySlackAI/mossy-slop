---
name: mossy-cpp
description: C++ language-specific skill for analysis, refactoring, and code generation.
axis: 1
argument-hint: "<file|directory> [--pattern <glob>|--check <feature>|--list]"
---

# IMPORTANT: Invoke skill `mossy-cpp`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

- `/mossy:cpp src/module.cpp` - Analyze C++ file
- `/mossy:cpp src/` - Analyze C++ directory
- `/mossy:cpp --pattern "*.hpp"` - Analyze header files
- `/mossy:cpp --check raii` - Check RAII compliance
- `/mossy:cpp --list` - List C++-specific features
- `/mossy:cpp --refactor` - Refactor C++ code

## Supported Features

| Feature | Description |
|---------|-------------|
| File Analysis | Parse includes, namespaces, classes, functions |
| Pattern Detection | RAII, smart pointers, const correctness |
| Pitfall Detection | Raw pointers, memory leaks, ODR violations |
| Refactoring | Convert to smart pointers, add const, modernize code |
| Build Awareness | CMake, Make, Bazel, Ninja, Meson |

## File Extensions
`.cpp`, `.h`, `.hpp`, `.cc`, `.cxx`, `.hxx`, `.ipp`
