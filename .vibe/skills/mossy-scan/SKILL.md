---
name: mossy-scan
description: Deep scan of the repository. Creates or updates AGENTS.md files.
user-invocable: false
allowed-tools: read_file,write_file,grep,bash,ask_user_question,task
---

# mossy-scan

Deep scan of the repository to create or update AGENTS.md files.

## Input

Full request: $ARGUMENTS

Accepts:
- **Update Mode**: `stable`, `update` or `rescan`
- **Empty**: Assume Update Mode `stable`

## Instructions

For each directory in this repository, each subdirectory, each sub-subdirectory (all recursive levels), perform these steps using the a subagent (suggestion: 'exlplore'):

### In the subagent:

  * Read the AGENTS.md and AGENTS_TOPDOWN.md files from the top of the repository down to the directory in question, should they exist
  * Read the AGENTS.md files from all direct subdirectories, should they exist
  * Read the AGENTS.md from the current directory, should it exist
  * Do an analysis of the content of the current directory, informed by what the reads taught you, but minding that they may be inaccurate
  * Output of the subagent should be the proposed (updated) contents of the AGENTS.md file in the current directory. It should follow the structure given by AGENTS_TEMPLATE.md.
    * For subdirectories: Output should be brief, not more than 1000 words, and not repeat any information present in the higher level files.
    * For the top level directory: Output should be brief, but comprehensive. Aim for 2000 words or less.

### In the main agent:

  * Perform the entire set of operations twice:
    1. Top-down, starting with the top directory fist, processing subdirectories later. Write the result into AGENTS_TOPDOWN.md.
    2. Bottom-up, processing each subdirectory before its parent.
      * If AGENTS.md does not exist yet in the current directory: Write the subagent output into it.
      * If AGENTS.md exists, act according to the Update Mode passed as argument:
        + `stable`: Update AGENTS.md GENTLY. Only remove or change things if they are now wrong.
        + `update`: Take over changes from the subagent that seem better than what is in AGENTS.md.
        + `rescan`: Replace AGENTS.md completely with subagent suggestion.
      * In all cases, delete AGENTS_TOPDOWN.md.

### Guidelines

  * During analysis, you may skip large files or implementation files (.c, .cpp, ...) as you see fit
  * Avoid explicit line references to source files, they can become outdated. Prefer just function and class names.

## GUARDRAILS

  * Only AGENTS.md is to be written to.
  * Do not read or write outside of the current repository; neither by following symbolic links nor by ascending the directory tree.
  * Do not make changes over git, no commits, to checkouts, no branches.
  * Skip hidden directories like .git, .flow, .vibe, .claude.
  * For git repositories, only scan files and directories that are in git.