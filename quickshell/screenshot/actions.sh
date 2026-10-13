#!/usr/bin/env bash
# actions.sh copy|open|reveal <file>
f="$2"
case "$1" in
    copy) wl-copy --type image/png < "$f" ;;
    open) setsid -f xdg-open "$f" >/dev/null 2>&1 ;;
    reveal)
        if   command -v dolphin  >/dev/null 2>&1; then setsid -f dolphin --select "$f" >/dev/null 2>&1
        elif command -v nautilus >/dev/null 2>&1; then setsid -f nautilus --select "$f" >/dev/null 2>&1
        elif command -v thunar   >/dev/null 2>&1; then setsid -f thunar "$(dirname "$f")" >/dev/null 2>&1
        else setsid -f xdg-open "$(dirname "$f")" >/dev/null 2>&1
        fi ;;
esac
