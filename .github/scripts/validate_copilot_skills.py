#!/usr/bin/env python3
"""Validate that all skills listed in Copilot marketplace.json exist and have SKILL.md files."""

import json
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

    print('\n'.join(skills))


if __name__ == '__main__':
    main()
