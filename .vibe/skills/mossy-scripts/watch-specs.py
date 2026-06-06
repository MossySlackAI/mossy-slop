#!/usr/bin/env python3
"""
Watch for file changes in .flow/specs directory.

Waits until any change is detected (file created, modified, or deleted),
then waits an additional second to ensure stability before exiting.

Usage: python scripts/watch_specs.py
"""

from datetime import datetime
import os
import time

def get_dir_state(path):
    """Return a tuple of (modification time, set of filenames) for a directory."""
    mtime = os.path.getmtime(path)
    files = set(os.listdir(path))
    for file in files:
        spec_mtime = os.path.getmtime(os.path.join(path, file))
        if spec_mtime > mtime:
            mtime = spec_mtime
    return (mtime, files)

def find_flow_dir(path):
    while len(path) > 1:
        flow_path = os.path.join(path, ".flow")
        if os.path.exists(flow_path):
            return flow_path

        git_path = os.path.join(path, ".git")
        if os.path.exists(git_path):
            return flow_path

        path = os.path.dirname(path)

def main():
    flow_path = find_flow_dir(os.path.abspath(os.path.curdir))
    specs_path = os.path.join(flow_path, "specs")

    # Ensure directory exists
    os.makedirs(specs_path, exist_ok=True)

    print(f"Watching {specs_path} for changes...")

    last_state = get_dir_state(specs_path)

    change_detected = False

    # check for verty recent change
    change_stamp = last_state[0]
    now_stamp = datetime.now().timestamp()
    time_to_60_seconds_since_last_change = change_stamp + 60 - now_stamp
    # print(change_stamp, now_stamp, time_to_60_seconds_since_last_change)
    if time_to_60_seconds_since_last_change > 0:
        # there was a very recent change, the caller might have missed it. Return immediately.
        change_detected = True
        print("Very recent change detected.")
        time.sleep(time_to_60_seconds_since_last_change)
        last_state = get_dir_state(specs_path)

    while True:
        time.sleep(10)  # Check every ten seconds
        try:
            current_state = get_dir_state(specs_path)
            if current_state != last_state:
                print("Change detected in .flow/specs")
                change_detected = True
            else:
                if change_detected:
                    print("Stable. Proceeding...")
                    return
                
            last_state = current_state
        except FileNotFoundError:
            # Directory was deleted, wait and return
            print("Deletion detected")
            time.sleep(10)
            return

if __name__ == "__main__":
    main()
