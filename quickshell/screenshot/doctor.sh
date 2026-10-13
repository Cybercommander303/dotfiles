#!/usr/bin/env bash
# Inspects YOUR installed tools and decides how capture.sh should run.
# Note: the probe takes one 1x1-pixel screenshot, which briefly replaces your clipboard.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/nyx-capture"
mkdir -p "$CACHE"
chmod +x "$HERE/bin/slurp" 2>/dev/null

echo "== versions =="
(qs --version || quickshell --version) 2>&1 | head -n1
hyprctl version 2>&1 | head -n1
hyprshot --version 2>&1 | head -n1
for p in hyprshot grim slurp; do
    (pacman -Q $p || rpm -q $p || nix-store -q --deriver "$(command -v $p)") 2>/dev/null | head -n1
done

echo; echo "== tools =="
for t in qs hyprshot grim slurp wl-copy hyprctl xdg-open; do
    if command -v "$t" >/dev/null 2>&1; then echo "  ok       $t -> $(command -v $t)"; else echo "  MISSING  $t"; fi
done

HAS_SILENT=0
echo; echo "== hyprshot flags =="
help="$(hyprshot --help 2>&1)"
for f in "-m" "-o" "-f" "-s"; do
    if echo "$help" | grep -q -- "$f"; then echo "  found    $f"; else echo "  not seen $f"; fi
done
echo "$help" | grep -q -- "-s" && HAS_SILENT=1

echo; echo "== probe: does hyprshot use the slurp shim? =="
MODE=grim
if command -v hyprshot >/dev/null 2>&1; then
    tmp="$(mktemp -d)"
    printf '0,0 1x1\n' > "$tmp/geom"
    args=(-m region -o "$tmp" -f probe.png)
    [ "$HAS_SILENT" = 1 ] && args+=(-s)
    ( NYX_PROBE="$tmp/shim-used" NYX_GEOM_FILE="$tmp/geom" PATH="$HERE/bin:$PATH" \
        setsid hyprshot "${args[@]}" >"$tmp/out" 2>&1 & echo $! > "$tmp/pid" )
    for _ in $(seq 1 40); do sleep 0.1; [ -s "$tmp/probe.png" ] && break; done
    kill -- -"$(cat "$tmp/pid")" 2>/dev/null
    if [ -e "$tmp/shim-used" ] && [ -s "$tmp/probe.png" ]; then
        MODE=hyprshot
        echo "  yes: hyprshot called the shim and wrote a file -> using hyprshot"
    else
        echo "  no: hyprshot did not use the shim (or did not write a file) -> using grim fallback"
        echo "  hyprshot output:"; sed 's/^/    /' "$tmp/out"
        echo "  (if a slurp crosshair appeared, your hyprshot wrapper puts its own slurp first in PATH)"
    fi
    rm -rf "$tmp"
fi

printf 'MODE=%s\nHAS_SILENT=%s\n' "$MODE" "$HAS_SILENT" > "$CACHE/mode"
echo; echo "capture mode saved to $CACHE/mode: MODE=$MODE"
