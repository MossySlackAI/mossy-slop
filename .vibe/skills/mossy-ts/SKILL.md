---
name: mossy-ts
description: TypeScript language-specific skill. Handles TS file analysis, refactoring, and code generation with type awareness.
user-invocable: false
allowed-tools: read_file,write_file,search_replace,grep,bash,ask_user_question,task
---

# mossy-ts

TypeScript language-specific skill for mossy. Provides type-aware analysis and code generation.

## Purpose
Aid in planning and executing code changes for TypeScript projects with strong type system awareness.

## Input

$ARGUMENTS

Accepts:
- File path: `src/module.ts` - Analyze or modify specific TS file
- Directory: `src/` - Analyze all TS files in directory
- Pattern: `--pattern "*.ts"` - Match TS files by glob
- `--strict` - Enable strict mode checks
- `--list` - List TS-specific features
- `--check <feature>` - Run specific TS check

## Flow

1. **Resolve targets**
   - Detect .ts, .tsx extensions
   - Find tsconfig.json for project context
   - Identify compiler options

2. **Analyze**
   - Parse file structure (imports, exports, interfaces, types, classes)
   - Detect patterns (generics, decorators, type guards)
   - Identify type issues (any, unknown, never, void)

3. **Execute**
   - Apply TS-specific refactorings
   - Generate type-safe code
   - Update tsconfig.json as needed

4. **Verify**
   - Type check with tsc
   - Lint with ESLint if available
   - Verify type coverage

## Language-Specific Features

### File Extensions
`.ts`, `.tsx` (TS + JSX), `.d.ts` (declaration)

### Type System
- Primitive types: string, number, boolean, null, undefined, symbol, bigint
- Object types: object, {}, {prop: type}
- Array types: type[], Array<type>
- Tuple types: [type1, type2]
- Union types: type1 | type2
- Intersection types: type1 & type2
- Literal types: "value", 1, true
- Type aliases: type Name = type
- Interfaces: interface Name {}
- Classes: class Name implements Interface
- Generics: <T>, <T extends Constraint>
- Mapped types: { [K in keyof T]: U }
- Conditional types: T extends U ? X : Y
- Utility types: Partial, Pick, Omit, Record, etc.
- Enums: enum, const enum
- Type assertions: as Type
- Type predicates: value is Type
- Type guards: typeof, instanceof

### Common Patterns
- Generic functions and classes
- Decorators (@decorator)
- Mixins
- Abstract classes
- Type guards
- Discriminated unions
- Branded types
- Nominal types
- Mapped types
- Conditional types
- Infer keyword
- keyof and typeof operators

### Pitfalls
- Any type usage (type safety loss)
- Implicit any
- Type assertions (as) hiding issues
- Missing null/undefined checks
- Incorrect generic constraints
- Circular dependencies
- Module resolution issues
- tsconfig.json misconfiguration
- Missing type exports

### Naming Conventions
- Same as JavaScript conventions
- Type parameters: T, U, V, K, V (single uppercase)
- Interfaces: IPascalCase or PascalCase
- Types: PascalCase
- Generic types: TypeName<T>

### Compiler Features
- Strict mode (strict: true)
- noImplicitAny
- strictNullChecks
- strictFunctionTypes
- strictPropertyInitialization
- noImplicitThis
- alwaysStrict
- exactOptionalPropertyTypes
- noUncheckedIndexedAccess

## Commands for Users

- `/mossy:ts src/module.ts` - Analyze TS file
- `/mossy:ts src/` - Analyze TS directory
- `/mossy:ts --strict` - Strict type checking
- `/mossy:ts --check generics` - Check generic usage
- `/mossy:ts --refactor` - Refactor TS code
- `/mossy:ts --interfaces` - Extract interfaces from code

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during analysis | read_file on .ts file, grep for patterns fails |
| validation-error | TypeScript specific validation fails | Invalid file extension, missing tsconfig.json |
| logic-error | Internal analysis logic fails | Type inference error, symbol resolution failure |
| resource-error | Required resources missing | tsconfig.json not found, TypeScript compiler not installed |
| configuration-error | Environment misconfiguration | tsc not available, incompatible TypeScript version |

### Integration

```bash
# At skill start, call required utilities
../mossy-scripts/ensure-flow-dir.sh >/dev/null 2>&1 || true

# When a tool fails during analysis
if ! read_file path="$ts_file" 2>/dev/null; then
    ../mossy-scripts/record-issue.sh --skill "mossy-ts" --error-type "tool-error" \
        --tool "read_file" --target "$ts_file" \
        --error "read_file failed: file not found or permission denied" \
        --context "Phase: analysis, Reading TypeScript file for analysis" || true
fi

# When file extension is invalid
if [[ ! "$file_ext" =~ \.(ts|tsx|d\.ts)$ ]]; then
    ../mossy-scripts/record-issue.sh --skill "mossy-ts" --error-type "validation-error" \
        --tool "N/A" --target "$ts_file" \
        --error "Invalid TypeScript file extension: $file_ext" \
        --context "Phase: target resolution, Validating file type" || true
fi
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## Guardrails

- Prefer interfaces over type aliases for object shapes
- Use strict mode
- Avoid any type
- Use unknown instead of any for dynamic values
- Always handle null/undefined (strictNullChecks)
- Use type guards for runtime type checking
- Document generic type parameters
- Use Prettier if available
- Respect ESLint rules if .eslintrc exists
- Warn about implicit any
- Questions via ask_user_question: header max 11 characters
