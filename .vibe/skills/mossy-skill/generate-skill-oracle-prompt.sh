#!/bin/bash

# generate-skill-oracle-prompt.sh - Generates an override prompt that simulates
# skill activation

# usage:
# generate-skill-oracle-prompt.sh [switches] <skill name> "<prompt>"
# the output of the mistral subagent fed with this prompt will be <skill name> on success, any other output is failure to match. 
# optional switches:
# -s test <skill name> in isolation without populating the skill list with the regular other skills

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python "$SCRIPT_DIR/generate-skill-oracle-prompt.py" "$@"

