#!/bin/sh
for c in "$TERMINAL" kitty foot alacritty ghostty wezterm konsole xterm; do
    [ -n "$c" ] || continue
    command -v "$c" >/dev/null 2>&1 || continue
    if [ $# -eq 0 ]; then exec "$c"; fi
    case "$c" in
        kitty|foot) exec "$c" "$@" ;;
        wezterm)    exec "$c" start -- "$@" ;;
        *)          exec "$c" -e "$@" ;;
    esac
done
