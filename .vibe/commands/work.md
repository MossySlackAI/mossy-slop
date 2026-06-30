---
name: mossy-slop:work
description: Execute plan tasks. Claim and execute tasks from the ready queue.
axis: 1
argument-hint: "<task-id|spec-id> [--list|--show <id>|--next|--continue <task-id>]"
---

# IMPORTANT: Invoke skill `mossy-work`

Pass $ARGUMENTS to the skill. The skill handles all logic.

## Usage

- `/mossy:work fn-1.1` - Execute specific task
- `/mossy:work fn-1` - Execute all ready tasks for spec
- `/mossy:work --next` - Execute next ready task across all specs
- `/mossy:work --list` - List ready tasks
- `/mossy:work --show fn-1.1` - Show task details
- `/mossy:work --continue fn-1.1` - Resume partially completed task

## Examples

```
# Create plan first
/mossy:plan "Add user authentication"

# Then execute all tasks for that spec
/mossy:work fn-1

# Or execute tasks one at a time
/mossy:work --next

# Check what's ready
/mossy:work --list

# See task details
/mossy:work --show fn-1.2
```
