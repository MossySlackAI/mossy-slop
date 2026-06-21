#!/bin/bash

# generate-skill-oracle-prompt.sh - Generates an override prompt that simulates
# skill activation

# usage:
# generate-skill-oracle-prompt.sh [switches] <skill name> "<description>"
# the output of the mistral subagent fed with this prompt will be <skill name> on success for each skill in the trigger list, any other output is failure to match. 
# mandatory switches:
# `-p`: use positive triggers
# `-n`: use negative triggers
# optional switches:
# `-s`: test <skill name> in isolation without populating the skill list with the regular other skills

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python "$SCRIPT_DIR/generate-skill-oracle-prompt.py" "$@"

