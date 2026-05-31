---
name: mossy-scan
description: Deep scan of the repository. Creates or updates AGENTS.md files.
user-invocable: false
allowed-tools: read_file,write_file,grep,bash,ask_user_question,task
---

# mossy-scan

Deep scan of the repository to create or update AGENTS.md files.

## Instructions

For each directory in this repository, each subdirectory, each sub-subdirectory (all recursive levels), perform these steps using the a subagent (suggestion: 'exlplore'):

### In the subagent:

  * Read the AGENT.md files from the top of the repository down to the directory in question, should they exist
  * Read the AGENT.md files from all direct subdirectories, should they exist
  * Read the AGENT.md from the current directory, should it exist
  * Do an analysis of the content of the current directory, informed by what the reads taught you, but minding that they may be inaccurate
  * Read all the AGENT.md files again
  * Output of the subagent should be the proposed (updated) contents of the AGENTS.md file in the current directory.
    * For subdirectories: Output should be brief, not more than 1000 words, and not repeat any information present in the higher level files.
    * For the top level directory: Output should be brief, but comprehensive. Aim for 2000 words or less.

### In the main agent:

  * Update the local AGENTS.md with that output. Skip trivial wording changes.
  * Perform the entire set of operations twice. Once top-down, starting with the top directory fist, processing subdirectories later. Once bottom-up, processing each subdirectory before its parent.

  * For the top AGENTS.md file: Make sure it contains a note about the recusive
  AGENTS.md files, and instruct agents to read all relevant AGENT.md files before planning or making changes. Relevant would be the one in the affected directory and all parent directories inside the repository.

### Guardrails

  * Only AGENTS.md is to be written to.
  * Do not read or write outside of the current repository; neither by following symbolic links nor by ascending the directory tree.

### Guidelines

  * During analysis, you may skip large files or implementation files (.c, .cpp, ...) as you see fit
  * Avoid explicit line references to source files, they can become outdated. Prefer just function and class names.