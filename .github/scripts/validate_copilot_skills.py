#!/usr/bin/env python3
"""Validate that all skills listed in Copilot marketplace.json exist and have SKILL.md files."""

import json
import os
import sys


def main():
    try:
        with open('.github/plugin/marketplace.json') as f:
            data = json.load(f)
    except FileNotFoundError:
        print("Error: .github/plugin/marketplace.json not found")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in marketplace.json: {e}")
        sys.exit(1)

    skills = []
    for plugin in data.get('plugins', []):
        for skill in plugin.get('skills', []):
            skills.append(skill)

    if not skills:
        print("No skills found in marketplace.json")
        sys.exit(0)

    # Validate each skill path
    all_valid = True
    for skill in skills:
        # Normalize path: remove leading ./ but preserve .vibe
        if skill.startswith('./'):
            path = skill[2:]  # Remove './' prefix
        else:
            path = skill
        
        # The skill path points to a directory containing SKILL.md
        skill_dir = path
        skill_file = os.path.join(path, 'SKILL.md')

        # Check directory exists
        if not os.path.isdir(skill_dir):
            print(f"Error: Directory does not exist: {skill_dir}")
            all_valid = False
            continue

        # Check SKILL.md exists
        if not os.path.isfile(skill_file):
            print(f"Error: SKILL.md does not exist: {skill_file}")
            all_valid = False
            continue

    if all_valid:
        print('\n'.join(skills))
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()
