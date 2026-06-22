# Mossy Slop

So some techbro bamboozled our bosses to go all in with his framework called flow-next. It gives passable results, admittedly, but burns tokens like there is no tomorrow. Which, you know... 

## Mission Statement

This is supposed to become a leaner alternative, compatible flow-next's state files, and compatible with Mistral.

The focus should be the code; the code is the single source of truth, it should be able to speak for itself. Inline comments should provide the documentation.

The human should retain full control and responsibility. They should be able to verify the quality of individual steps of the process if they want to, or later when everything is done.

It should be the user's choice whether individual steps are committed to git, and whether auto-generated plan metadata gets commited or not.

A reasonable effort should be made in the planing phase to discover open questions, but speed and token conservation are valued higher.

## License

MIT, see [LICENSE](LICENSE).

## Installation

See [INSTALL.md](INSTALL.md).

## So what is it anyway?

A collection of skills to aid in structured (`agentic`) work. You can invoke the skills directly with `/mossy:SKILLNAME ARGUMENTS` or use trigger phases. In each skill directory, you can find TRIGGERS.md which lists a couple of sample phrases that would trigger the skill.

## Main Workflow

```mermaid
flowchart LR
    subgraph SPEC[Spec]
        START((Start)) -->
        IDEA(/mossy:idea) -->
        INTERVIEW(/mossy:interview)
    end

    subgraph FINISH[ /mossy:finish]
        style FINISH padding:40px
        subgraph PADDING1[" "]
            subgraph CHANGES
                WORK(/mossy:work) -->
                REVIEW(/mossy:review)
            end
        end

        PLAN(/mossy:plan) -->
        WORK

        REVIEW -->
        COMMIT(commit, push, PR)
    end

    START --> INTERVIEW --> PLAN

    class CHANGES,SPEC,FINISH sub
    classDef sub fill:none
    class PADDING1 padding
    classDef padding opacity:0
```

### 0. Idea

If you want to start from the very beginning, use `/mossy:idea` to just record your idea in a spec file. The best way is to just call it without parameters and give it the instructions when prompted.

You can also give the idea text directly on the command line, and you can skip straight to step 1. But know that there is a higher risk that your AI will just barge ahead and do the work instead of following the workflow.

### 1. Interview

Refine the idea entered before, or a new idea, with `/mossy:interview`. This will 
check the idea, compare it with the reality of the project, and then ask a couple of questions to make sure the plans will be aligned with your intentions.

Natural language orders also work. Prefer to put the skill triggering instruction at the back, that gives it more weight, and avoid action words in the draft text. "I want the system ported to Raylib. Interview me."

#### 2. Planning

`/mossy:plan <spec-id>`

This splits the spec into managable work items.

#### 3. Implementation

Execute the tasks using the work skill:

`/mossy:work fn-N.1` or just `/mossy:work --next`

The work skill will:
- Read the task requirements
- Implement the changes
- Record progress

For multiple tasks, execute them in order:

```
/mossy:work fn-N.1
/mossy:work fn-N.2
/mossy:work fn-N.3
```

Or all one after the other without pause with `/mossy:work fn-N`. A simple `Make it so!` also works.

#### 4. Review

Before committing/pushing, review all changes:

```
/mossy:review fn-N
```

This will:
- Check that all acceptance criteria are met
- Verify code quality
- Ensure consistency with existing patterns

#### Steps 2 to 4 can be executed in one go using /mossy:finish

#### 5. Commit

When committing manually, commit changes with a clear message:

```bash
git add .
git commit -m "feat: Add mossy-rust skill for Rust language support"
```

Just prompting `commit` usually does the job for you. In .flow/mossy-config, you can
also change the general commit policy so that after every work item, we commit automatically.

## Additional Skills

### /mossy:scan

This skill does a deep scan of the repository and adds AGENTS.md files everwhere. This way, specific knowledge is constrained to the relevant subdirectories and the agents are not fed information that is useless for their current task.

Check [the command](.vibe/commands/mossy-scan.md#Usage) for usage instructions.

### Note for Mistral Vibe

Technically, Mistral Vibe does not support the `/mossy:<command>` syntax. It mostly works anyway, but you may receive better results with trigger phraces.

## Authorship

This readme file is entirely human written. It serves both as a guide to the AI writing the rest of the system, and information to human users.

The script flowctl.py is taken verbatim from flow-next for maximum compatibility, credit seems to go mostly to some AI, with instructions from Gordon Mickel and collaborators.

The rest of the system is mostly written by Mistral itself, with heavy tweaks by humans.