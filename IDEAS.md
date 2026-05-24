# Ideas

For humans. AI can take a peek, but these are not yet actionable items until explicitly activated.

## New

### Customize co-author in commit messages.

### Customize committing. No commits, after every step, once at the end.

### Python progress monitor

Window with a checklist for each specification, list items are the tasks, get checked when done. Unplanned specifications and completed specifications are collapsed on the left hand side, unplanned ones on top, completed ones on the bottom. In progress ones are on the right. It should be possible to delete specifications, which also deletes the associated tasks. Completions of tasks should trigger notifications. It should be possible to collapse the program to the system tray and still see what is going on.

### Specifications: Guard against race conditions

Specifications should have a clear marker that shows when they are ready for planning, the plan and workaholic skills should only pick them up when they are ready.

### A 'complete all work and commit' skill mossy-workaholic.

If there are open specifications:
If there are neither open specifications nor work items:
 - do nothing

If there are open specifications:
 - Ask whether a new branch should be created for each specification
 - Ask about commit preferences
 - complete all open work items
 - for each open specification:
    * if requested, create a new branch based on the current one
    * invoke mossy-plan on the specification
    * complete all open work items
 - give report of completed work, end

If there are open work items:
 - ask about commit prefrences
 - complete all open work items
 - give report of completed work, end

To complete all open work items:
 - if the user wanted to commit after each step: complete each work item with the mossy-work skill, commit
 - otherwise: complete all open work items with the mossy-work skill, commit if that is wanted
 - invoke mossy-review skill
 - if it was requested, git push

To ask about commit preferences:
 - Ask user whether they want to commit after each step or at the end or not at all, respect that choice
 - Ask whether commits should be pushed when all work items for a feature are complete

## Completed

### Erorrs

On all skills, present and future, make it so that errors in tool use and other problems that cost time and tokens to resolve are recorded in individual files in .flow/issues/. Each issue should be its own file, containing, if applicable, the tool invocation, error log, problem description and what lead to it. The information should be sufficient to fix the underlying problem in this repository.

### Interview

Our inspiration source in ./flow-next has an 'interview' skill, that is similar to our 'plan', but makes some pre-planing and asks questions where clarification is needed. It has a buisiness and technical mode, we only want the technical mode to avoid overhead. Plan and implement it here.

