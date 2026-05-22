---
name: mossy:ts
description: TypeScript language-specific skill for type-aware analysis, refactoring, and code generation.
axis: 1
argument-hint: "<file|directory> [--pattern <glob>|--strict|--check <feature>|--list]"
---

# IMPORTANT: Invoke skill `mossy-ts`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

- `/mossy:ts src/module.ts` - Analyze TS file
- `/mossy:ts src/` - Analyze TS directory
- `/mossy:ts --pattern "*.ts"` - Analyze TS files by pattern
- `/mossy:ts --strict` - Strict type checking
- `/mossy:ts --check generics` - Check generic usage
- `/mossy:ts --list` - List TS-specific features
- `/mossy:ts --refactor` - Refactor TS code
- `/mossy:ts --interfaces` - Extract interfaces from code

## Supported Features

| Feature | Description |
|---------|-------------|
| File Analysis | Parse imports, exports, interfaces, types, classes |
| Type System | Primitive types, generics, unions, intersections, utility types |
| Pattern Detection | Generic functions, decorators, type guards |
| Pitfall Detection | any type, implicit any, type assertions, null/undefined |
| Refactoring | Add type hints, extract interfaces, convert to strict mode |
| Project Awareness | tsconfig.json, compiler options |

## File Extensions
`.ts`, `.tsx` (TS + JSX), `.d.ts` (declaration)
