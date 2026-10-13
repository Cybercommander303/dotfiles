#!/usr/bin/env bash
# capture.sh "<x,y wxh>" "<output file>"
# Called by the Quickshell overlay once the real selection is confirmed.
#  - MODE=hyprshot (set by doctor.sh): runs the real hyprshot with a `slurp` shim that
#    answers with our geometry, so hyprshot does the capture, saving and clipboard.
#  - otherwise: plain grim + wl-copy (same file name pattern, same folder).
# Everything is logged to ~/.cache/nyx-capture/last.log
set -u
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"   # qs started from exec-once may have a short PATH

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEOM="$1"
OUT="$2"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/nyx-capture"
mkdir -p "$CACHE"
LOG="$CACHE/last.log"
log() { echo "$*" | tee -a "$LOG" >&2; }

{
    echo "=== $(date) ==="
    echo "geometry : $GEOM"
    echo "output   : $OUT"
    echo "grim     : $(command -v grim || echo MISSING)"
    echo "hyprshot : $(command -v hyprshot || echo MISSING)"
    echo "wl-copy  : $(command -v wl-copy || echo MISSING)"
} > "$LOG"

MODE="grim"
HAS_SILENT=0
if [ -f "$CACHE/mode" ]; then . "$CACHE/mode"; else log "no doctor result found (run doctor.sh) -> using grim"; fi
log "mode     : $MODE"

if ! mkdir -p "$(dirname "$OUT")"; then
    log "cannot create folder $(dirname "$OUT")"
    exit 1
fi

if [ "$MODE" = "hyprshot" ] && command -v hyprshot >/dev/null 2>&1; then
    GF="${XDG_RUNTIME_DIR:-/tmp}/nyx-capture.geometry"
    printf '%s\n' "$GEOM" > "$GF"
    args=(-m region -o "$(dirname "$OUT")" -f "$(basename "$OUT")")
    [ "$HAS_SILENT" = 1 ] && args+=(-s)
    log "running  : hyprshot ${args[*]}"
    NYX_GEOM_FILE="$GF" PATH="$HERE/bin:$PATH" hyprshot "${args[@]}" >> "$LOG" 2>&1
    rc=$?
    rm -f "$GF"
    if [ -s "$OUT" ]; then log "hyprshot saved $OUT"; exit 0; fi
    log "hyprshot exited $rc without writing $OUT; falling back to grim"
fi

if ! command -v grim >/dev/null 2>&1; then
    log "ERROR: grim is not installed (install it, e.g. sudo pacman -S grim / sudo dnf install grim)"
    exit 1
fi
log "running  : grim -g \"$GEOM\" \"$OUT\""
if ! grim -g "$GEOM" "$OUT" >> "$LOG" 2>&1; then
    log "ERROR: grim failed"
    exit 1
fi
[ -s "$OUT" ] || { log "ERROR: grim reported success but $OUT is missing"; exit 1; }
if command -v wl-copy >/dev/null 2>&1; then wl-copy --type image/png < "$OUT"; else log "wl-copy missing: not copied to clipboard"; fi
log "saved    : $OUT"
exit 0
