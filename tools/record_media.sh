#!/bin/bash
# Visual-only runs + screen recordings (X11, ffmpeg x11grab). NOT used for any numbers: the scored runs are
# headless with nothing recording. Keep each window visible and the screen unlocked while recording.
# Usage: tools/record_media.sh [vins|orbslam3|all]   -> outputs/media/*.mp4 (copy the keepers to assets/) + assets/*.gif
set -euo pipefail
source "$(dirname "$0")/../env.sh"
WHAT="${1:-all}"; M="$REPO/outputs/media"; mkdir -p "$M" "$REPO/assets"

if [[ "$WHAT" == vins || "$WHAT" == all ]]; then
    D="$M/vins_run"; rm -f "$D/bag_start"
    OUT="$D" LOOP=1 RVIZ=1 AUTO_EXIT=1 "$REPO/vins_fusion/run.sh" > "$M/vins_run.log" 2>&1 &
    RUN=$!
    until [ -f "$D/bag_start" ]; do sleep 1; done
    sleep "$(python3 -c "import time; print(max(0, $(cat "$D/bag_start") + 100 - time.time()))")"  # bag seconds 100-180
    "$REPO/tools/record_window.sh" 'RViz' 80 "$M/vins_loop_rviz.mp4"
    wait $RUN
    "$REPO/tools/make_gif.sh" "$M/vins_loop_rviz.mp4" "$REPO/assets/vins_loop_rviz.gif"
fi

if [[ "$WHAT" == orbslam3 || "$WHAT" == all ]]; then
    D="$M/orb_run"; mkdir -p "$D"; rm -f "$D"/f_*.txt
    OUT="$D" VIEWER=1 NAME=mh01_media "$REPO/orbslam3/run.sh" > "$M/orb_run.log" 2>&1 &
    RUN=$!
    until wmctrl -l | grep -q 'Map Viewer'; do kill -0 $RUN 2>/dev/null || { echo "ORB-SLAM3 exited early" >&2; exit 1; }; sleep 0.5; done
    sleep 55                                    # final map initializes ~46 s into MH_01
    "$REPO/tools/record_window.sh" 'Map Viewer' 80 "$M/orbslam3_viewer.mp4"
    wait $RUN || true
    "$REPO/tools/make_gif.sh" "$M/orbslam3_viewer.mp4" "$REPO/assets/orbslam3_viewer.gif"
fi
