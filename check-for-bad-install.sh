#!/usr/bin/env bash
#
# Detects whether an installed zellij binary still contains the old
# `ps -ao ppid,args` foreground-command discovery, which was replaced by the
# sysinfo-based implementation in c632605c ("perf: foreground pane-command
# discovery without scanning the whole process table").
#
# Usage: check-for-bad-install.sh [path-to-zellij]   (default: ~/.local/bin/zellij)
#
# Exit status: 0 = new code (good install), 1 = old ps code (bad install),
#              2 = could not check (binary or `strings` missing).

set -uo pipefail

readonly OLD_PS_MARKER='ppid,args'
readonly DEFAULT_BINARY="$HOME/.local/bin/zellij"

binary="${1:-$DEFAULT_BINARY}"

if ! command -v strings >/dev/null 2>&1; then
    echo "ERROR: 'strings' not found on PATH; cannot inspect the binary." >&2
    exit 2
fi

if [[ ! -f "$binary" ]]; then
    echo "ERROR: no zellij binary at $binary" >&2
    exit 2
fi

match_count=$(strings "$binary" | grep -c "$OLD_PS_MARKER")

if [[ "$match_count" -gt 0 ]]; then
    echo "BAD INSTALL: $binary is still using the OLD ps code."
    echo "  Found $match_count occurrence(s) of '$OLD_PS_MARKER' (the \`ps -ao ppid,args\` scan)."
    echo "  Rebuild and reinstall, then re-run this check."
    exit 1
fi

echo "OK: $binary is using the NEW ps code."
echo "  No '$OLD_PS_MARKER' string found; foreground commands come from sysinfo, not \`ps\`."
exit 0
