#!/usr/bin/env python3
"""
# generate-skill-oracle-prompt.py - Generates an override prompt that simulates skill activation

# usage:
# python generate-skill-oracle-prompt.py [switches] <skill name> "<prompt>"
# the output of the mistral subagent fed with this prompt will be <skill name> on success, any other output is failure to match. 
# optional switches:
# -s test <skill name> in isolation without populating the skill list with the regular other skills
"""

import os
import yaml
import re
import argparse
import html

# adapted from parse_skill_markdown from vibe cli

# parse only frontmatter
def parse_frontmatter(content: str) -> dict[str, str]:
    try:
        frontmatter = yaml.safe_load(content)
    except yaml.YAMLError as e:
        raise SyntaxError(f"Invalid YAML frontmatter: {e}") from e

    if frontmatter is None:
        frontmatter = {}

    return frontmatter

# parses string into frontmatter dict
FM_BOUNDARY = re.compile(r"^-{3,}\s*$", re.MULTILINE)
def parse_skill_frontmatter(content: str) -> dict[str, str]:
    splits = FM_BOUNDARY.split(content, 2)
    if len(splits) < 3 or splits[0].strip():  # noqa: PLR2004
        raise SyntaxError(
            "Missing or invalid YAML frontmatter (metadata section must start and end with ---)"
        )

    yaml_content = splits[1]

    try:
        frontmatter = yaml.safe_load(yaml_content)
    except yaml.YAMLError as e:
        raise SyntaxError(f"Invalid YAML frontmatter: {e}") from e

    if frontmatter is None:
        frontmatter = {}

    return frontmatter

# reads frontmatter dict
def read_frontmatter(file: str):
    section=0
    frontmatter_raw = ""
    with open(file) as f:
        while True:
            line = f.readline()
            if not line:
                break
            if line.startswith("---"):
                if 1 == section:
                    break 
                section = section + 1
            else:
                if 1 == section:
                    frontmatter_raw = frontmatter_raw + line
    # print(frontmatter_raw)
    return parse_frontmatter(frontmatter_raw)

# skills: dictionary 'skill name' -> 'skill description'

def scan_skills(vibe_dir, skills):
    skill_dir = os.path.join(vibe_dir, "skills")
    if not os.path.exists(skill_dir):
        return
    skill_candidates = set(os.listdir(skill_dir))
    # print(skill_candidates)
    for skill_candidate in skill_candidates:
        skill_file = os.path.join(skill_dir, skill_candidate, "SKILL.md")
        if not os.path.exists(skill_file):
            continue
        # print(skill_file)
        frontmatter = read_frontmatter(skill_file)
        # print(frontmatter)
        description = frontmatter['description']
        skills[skill_candidate] = description

# build prompt from skills
# adapted from vibe cli, 
# https://github.com/mistralai/mistral-vibe/blob/main/vibe/core/system_prompt.py
# _get_available_skills_section
def build_prompt(skills):
    lines = [
        "# Available Skills",
        "",
        "You are a skill activation test agent. Ignore previosly skill related instructions and registered skills. ",
        "You only have access to the following skills. "
        "When a task matches a skill's description, echo the skill name. "
        "",
        "<available_skills>",
    ]

    for name, description in sorted(skills.items()):
        lines.append("  <skill>")
        lines.append(f"    <name>{html.escape(str(name))}</name>")
        lines.append(
            f"    <description>{html.escape(str(description))}</description>"
        )
        lines.append("  </skill>")

    lines.append("</available_skills>")
    return "\n".join(lines)

def main():
    parser = argparse.ArgumentParser(
        description="Creates prompt for skill activation oracle"
    )
    parser.add_argument("-s", help = "Add only the passed skill to the oracle test. Usually, all known skills are added as well.", action='store_true')
    parser.add_argument("skill_name")
    parser.add_argument("skill_description")
    parser.add_argument("trigger")
    args = parser.parse_args()

    # load skills
    single = args.s
    skills = {}
    if not single:
        scan_skills("~/.vibe", skills)
        scan_skills(".vibe", skills)

    # add/modify the skill we are interested in
    skills[args.skill_name] = args.skill_description

    prompt = build_prompt(skills)

    print(prompt)
    print("\nNow process the user prompt:")
    print(args.trigger)

if __name__ == "__main__":
    main()
