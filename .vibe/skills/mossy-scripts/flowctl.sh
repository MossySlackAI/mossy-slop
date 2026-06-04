#!/bin/bash
# flowctl wrapper - invokes flowctl.py from the same directory

# fallback location: here.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# find the correct script to call. Prefer installed version by flow-next.
pushd . 1>/dev/null
    while test '/' != `pwd`; do
        if test -d .flow && test -x .flow/bin/flowctl.py; then           
            SCRIPT_DIR="$(cd .flow/bin/; pwd)"
            break
        fi
        cd ..
    done
popd 1>/dev/null

exec python3 "$SCRIPT_DIR/flowctl.py" "$@"
