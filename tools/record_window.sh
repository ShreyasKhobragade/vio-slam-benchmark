#!/bin/bash
# Record the on-screen rectangle of an X11 window (matched by title regex) with ffmpeg x11grab.
# Usage: scripts/record_window.sh <title-regex> <seconds> <out.mp4>
# Output: H.264 MP4, 1280 px wide (height keeps aspect, even), 30 fps, yuv420p, no mouse pointer.
set -euo pipefail
PAT="$1"; DUR="$2"; OUT="$3"
WID=""
for _ in $(seq 120); do                      # wait up to 60 s for the window to appear
    WID=$(wmctrl -l | awk -v p="$PAT" '$0 ~ p {print $1; exit}'); [ -n "$WID" ] && break; sleep 0.5
done
[ -n "$WID" ] || { echo "no window matching '$PAT'" >&2; wmctrl -l >&2; exit 1; }
wmctrl -i -a "$WID"                          # raise + focus
sleep 1
eval "$(xwininfo -id "$WID" | awk '/Absolute upper-left X/{print "X="$4} /Absolute upper-left Y/{print "Y="$4}
                                   /^  Width/{print "W="$2} /^  Height/{print "H="$2}')"
W=$((W/2*2)); H=$((H/2*2))
echo "recording window $WID '$PAT' at ${W}x${H}+${X}+${Y} for ${DUR}s -> $OUT"
ffmpeg -hide_banner -loglevel warning -y -f x11grab -draw_mouse 0 -framerate 30 \
    -video_size "${W}x${H}" -i "${DISPLAY}+${X},${Y}" -t "$DUR" \
    -vf "scale=1280:-2:flags=lanczos,fps=30" -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p \
    -movflags +faststart "$OUT"
