---
name: mossy-js
description: JavaScript language-specific skill. Handles JS file analysis, refactoring, and code generation.
user-invocable: false
allowed-tools: read_file,write_file,search_replace,grep,bash,ask_user_question,task
---

# mossy-js

JavaScript language-specific skill for mossy. Provides JS-aware analysis and code generation.

## Purpose
Aid in planning and executing code changes for JavaScript projects.

## Input

$ARGUMENTS

Accepts:
- File path: `src/module.js` - Analyze or modify specific JS file
- Directory: `src/` - Analyze all JS files in directory
- Pattern: `--pattern "*.js"` - Match JS files by glob
- `--module <name>` - Analyze specific module
- `--list` - List JS-specific features
- `--check <feature>` - Run specific JS check

## Flow

1. **Resolve targets**
   - Detect .js, .mjs, .cjs extensions
   - Find package.json for project context
   - Identify dependencies

2. **Analyze**
   - Parse file structure (imports, exports, classes, functions)
   - Detect patterns (promises, async/await, callbacks, event emitters)
   - Identify pitfalls (callback hell, this binding, prototype pollution)

3. **Execute**
   - Apply JS-specific refactorings
   - Generate idiomatic JS code
   - Update package.json as needed

4. **Verify**
   - Lint with ESLint if available
   - Verify module resolution
   - Check for common anti-patterns

## Language-Specific Features

### File Extensions
`.js`, `.mjs` (ES Module), `.cjs` (CommonJS)

### Module Systems
- CommonJS: require/module.exports
- ES Modules: import/export
- UMD: Universal Module Definition
- AMD: Asynchronous Module Definition

### Common Patterns
- Promises (then/catch/finally)
- async/await
- Callbacks
- Event Emitters
- Modules (Revealing Module, IIFE)
- Prototypal inheritance
- Classes (ES6+)
- Arrow functions
- Template literals
- Destructuring
- Spread/Rest operators
- Default parameters
- Generators
- Iterators

### Pitfalls
- Callback hell (pyramid of doom)
- Unhandled promise rejections
- this binding issues
- Prototype pollution
- Memory leaks (event listeners, closures)
- == vs === confusion
- var hoisting
- Implicit type coercion
- Floating point precision
- Date handling issues

### Naming Conventions
- Variables: camelCase
- Constants: UPPER_SNAKE_CASE
- Functions: camelCase
- Classes: PascalCase
- Methods: camelCase
- Properties: camelCase or snake_case
- Private members: _prefix or #private (ES2022+)

### Node.js Features
- require() and module.exports
- __dirname and __filename
- process object
- Buffer
- Stream (Readable, Writable, Duplex, Transform)
- EventEmitter
- child_process
- fs (file system)
- path
- util

### Browser Features
- DOM manipulation
- fetch API
- Web APIs (localStorage, sessionStorage, IndexedDB)
- Service Workers
- Web Workers
- Custom Elements

## Commands for Users

- `/mossy:js src/module.js` - Analyze JS file
- `/mossy:js src/` - Analyze JS directory
- `/mossy:js --check promises` - Check promise usage
- `/mossy:js --refactor` - Refactor JS code
- `/mossy:js --async` - Convert callbacks to async/await

## Error Recording

This skill records errors to `.flow/issues/` following the [Issue Recording Guide](../mossy-scripts/ISSUE_RECORDING.md).

### Error Types Recorded

| Error Type | Trigger | Example |
|------------|---------|---------|
| tool-error | Vibe tool calls fail during analysis | read_file on .js file, grep for patterns fails |
| validation-error | JavaScript specific validation fails | Invalid file extension, missing package.json |
| logic-error | Internal analysis logic fails | AST parsing error, module resolution failure |
| resource-error | Required resources missing | package.json not found, Node.js not installed |
| configuration-error | Environment misconfiguration | ESLint not installed, incompatible Node.js version |

### Integration

```bash
# At skill start, call required utilities
../mossy-scripts/ensure-flow-dir.sh >/dev/null 2>&1 || true

# When a tool fails during analysis
if ! read_file path="$js_file" 2>/dev/null; then
    ../mossy-scripts/record-issue.sh --skill "mossy-js" --error-type "tool-error" \
        --tool "read_file" --target "$js_file" \
        --error "read_file failed: file not found or permission denied" \
        --context "Phase: analysis, Reading JavaScript file for analysis" || true
fi

# When file extension is invalid
if [[ ! "$file_ext" =~ \.(js|mjs|cjs)$ ]]; then
    ../mossy-scripts/record-issue.sh --skill "mossy-js" --error-type "validation-error" \
        --tool "N/A" --target "$js_file" \
        --error "Invalid JavaScript file extension: $file_ext" \
        --context "Phase: target resolution, Validating file type" || true
fi
```

**Note:** Use `|| true` to prevent recording failures from breaking skill execution.

## GUARDRAILS

- Prefer ES Modules over CommonJS for new code
- Always handle promise rejections
- Use === instead of ==
- Avoid var (use const/let)
- Avoid callback hell
- Use ESLint if .eslintrc exists
- Respect Prettier configuration if present
- Warn about synchronous operations in Node.js
- Document function parameters and return types (JSDoc)
- Questions via ask_user_question: header max 11 characters
