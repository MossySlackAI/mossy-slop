---
name: mossy-plan
description: Create execution plan from spec. Breaks work into ordered tasks with clear acceptance criteria.
user-invocable: false
allowed-tools: read_file,write_file,grep,bash,ask_user_question
---

# Plan

Create an execution plan from a spec. Code is the single source of truth — inline comments in code serve as documentation.

**User controls all git decisions**: Auto-generated plan metadata in `.flow/` is NOT committed by default. User explicitly chooses what to commit.

## Input

$ARGUMENTS

Accepts:
- Spec ID: `fn-1-add-auth` or legacy `fn-1`
- File path: `specs/add-auth.md` (creates spec first)
- Idea text: `Add OAuth2 support` (creates minimal spec + tasks)

## Flow

1. **Parse input**
   - If ID: read `.flow/specs/<id>.md`
   - If path: read file, extract title, create spec
   - If text: create minimal spec with goal = text

2. **Extract requirements**
   - Split spec into acceptance criteria (R-IDs)
   - Number them sequentially: R1, R2, R3...
   - Log questions immediately but continue processing; ask in bulk at end

3. **Break into tasks**
   - Each task implements 1+N requirements
   - Order by dependency (infrastructure first, UI last)
   - ID format: `<spec-id>.M` (fn-1.1, fn-1.2...)
   - Speed and token conservation > exhaustive question discovery

4. **Write artifacts**
   - Spec file: `.flow/specs/<id>.md` with R-IDs
   - Task files: `.flow/tasks/<id>.M.md` per task
   - Summary: `.flow/specs/<id>-plan.md` with dependency graph
   - **NOT committed to git by default** — user choice

## Spec Format

```markdown
# <Title>

## Goal
<1 sentence>

## Acceptance Criteria
- R1: <criterion>
- R2: <criterion>
...

## Tasks
- fn-<N>.1: <description>
- fn-<N>.2: <description>
...

## Dependencies
- fn-<N>.2 depends on fn-<N>.1
```

## Task Format

```markdown
---
task_id: fn-<N>.M
spec_id: fn-<N>
status: pending
description: <what to do>
acceptance: R1, R2
depends_on: fn-<N>.(M-1)
---

## Implementation Notes
- File paths to modify
- Key functions/classes to create
- Tests required
```

## Commands

After plan creation, user can:
- `/mossy:work <spec-id>` - Execute all tasks
- `/mossy:work <task-id>` - Execute single task
- `/mossy:plan --list` - List all specs
- `/mossy:plan --show <id>` - Show spec + tasks

## Guardrails

- Never use markdown TODOs
- Never use TodoWrite
- All state in `.flow/`
- Task IDs immutable once created
- R-IDs frozen at plan time
