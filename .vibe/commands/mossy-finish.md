---
name: mossy-finish
description: Execute full workflow (plan, work, review) on a spec
argument-hint: "<spec-id>"
---

# IMPORTANT: Invoke skill `mossy-finish`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

- `/mossy:finish fn-23` - Execute full workflow on spec fn-23
- `/mossy:finish --help` - Show usage information

## Description

This command invokes the mossy-finish skill which automatically executes the complete mossy workflow:
1. mossy-plan - Creates execution plan from spec
2. mossy-work - Executes all tasks in the plan
3. mossy-review - Reviews changes before commit

The workflow respects the mossy-config settings in the spec file for:
- commit-policy (manual, auto-per-change, auto-per-spec, batch)
- new-branch-per-spec (true/false)
- auto-push (true/false)
- co-authored-by

## Examples

```
# Execute full workflow on a spec
/mossy:finish fn-23

# Execute with short spec ID
/mossy:finish fn-23-create-mossy-finish-skill
```
