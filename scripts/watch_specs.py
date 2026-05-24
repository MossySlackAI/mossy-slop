#!/usr/bin/env python3
"""
Watch for file changes in .flow/specs directory.

Waits until any change is detected (file created, modified, or deleted),
then waits an additional second to ensure stability before exiting.

Usage: python scripts/watch_specs.py
"""

import os
import time

SPECS_DIR = ".flow/specs"


def get_dir_state(path):
    """Return a tuple of (modification time, set of filenames) for a directory."""
    mtime = os.path.getmtime(path)
    files = set(os.listdir(path))
    return (mtime, files)


def main():
    # Ensure directory exists
    os.makedirs(SPECS_DIR, exist_ok=True)

    print(f"Watching {SPECS_DIR} for changes...")

    last_state = get_dir_state(SPECS_DIR)

    while True:
        time.sleep(1)  # Check every second
        try:
            current_state = get_dir_state(SPECS_DIR)
            if current_state != last_state:
                print("Change detected in .flow/specs")
                time.sleep(1)  # Additional second to be safe
                print("Stable. Proceeding...")
                return
            last_state = current_state
        except FileNotFoundError:
            # Directory was deleted, recreate and continue
            os.makedirs(SPECS_DIR, exist_ok=True)
            last_state = get_dir_state(SPECS_DIR)


if __name__ == "__main__":
    main()
