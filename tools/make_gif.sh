#!/bin/bash
# MP4 -> GIF with a two-pass ffmpeg palette (palettegen + paletteuse).
# 2x speed (setpts=0.5*PTS), 12 fps, 800 px wide; the palette PNG is kept in outputs/media/.
# Usage: scripts/make_gif.sh in.mp4 out.gif
set -euo pipefail
IN="$1"; OUT="$2"; ROOT="$(cd "$(dirname "$0")/.." && pwd)"; mkdir -p "$ROOT/outputs/media"
PAL="$ROOT/outputs/media/palette_$(basename "${OUT%.gif}").png"
F="setpts=0.5*PTS,fps=12,scale=800:-1:flags=lanczos"
ffmpeg -v error -y -i "$IN" -vf "$F,palettegen=stats_mode=diff" "$PAL"
ffmpeg -v error -y -i "$IN" -i "$PAL" -lavfi "$F[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" "$OUT"
ls -l "$OUT"
