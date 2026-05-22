---
name: mossy:js
description: JavaScript language-specific skill for analysis, refactoring, and code generation.
axis: 1
argument-hint: "<file|directory> [--pattern <glob>|--module <name>|--check <feature>|--list]"
---

# IMPORTANT: Invoke skill `mossy-js`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

- `/mossy:js src/module.js` - Analyze JS file
- `/mossy:js src/` - Analyze JS directory
- `/mossy:js --pattern "*.js"` - Analyze JS files by pattern
- `/mossy:js --module express` - Analyze specific module
- `/mossy:js --check promises` - Check promise usage
- `/mossy:js --list` - List JS-specific features
- `/mossy:js --refactor` - Refactor JS code
- `/mossy:js --async` - Convert callbacks to async/await

## Supported Features

| Feature | Description |
|---------|-------------|
| File Analysis | Parse imports, exports, classes, functions |
| Pattern Detection | Promises, async/await, callbacks, event emitters |
| Pitfall Detection | Callback hell, this binding, prototype pollution |
| Refactoring | Convert to async/await, add type hints (JSDoc) |
| Module Awareness | CommonJS, ES Modules, UMD, AMD |

## File Extensions
`.js`, `.mjs` (ES Module), `.cjs` (CommonJS)
