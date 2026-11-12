#!/bin/bash
# Run the ORB-SLAM3 EuRoC mono-inertial example on MH_01_easy (ASL format), natively, in a clean env.
# Usage: [VIEWER=0] [OUT=outputs/orbslam3] [NAME=mh01_mono_inertial] orbslam3/run.sh
#   VIEWER=1  original binary with the Pangolin viewer on the host display
#   VIEWER=0  headless copy (outputs/bin/mono_inertial_euroc_headless, see orbslam3/headless/)
# Writes to $OUT: f_$NAME.txt (every frame, t[ns] x y z qx qy qz qw), kf_$NAME.txt, run.log, exit_code
#   (exit 139 at shutdown is a known ORB-SLAM3 segfault while saving; both files are complete).
set -euo pipefail
source "$(dirname "$0")/../env.sh"
VIEWER="${VIEWER:-0}"; NAME="${NAME:-mh01_mono_inertial}"
OUT="$(realpath -m "${OUT:-$REPO/outputs/orbslam3}")"; mkdir -p "$OUT"
[ -e "$OUT/f_$NAME.txt" ] && { echo "$OUT/f_$NAME.txt exists; not overwriting" >&2; exit 1; }
[ -d "$DATA/mav0/cam0" ] || { echo "ASL data not found: $DATA/mav0 (see docs/setup_orbslam3.md)" >&2; exit 1; }
if [ "$VIEWER" = "1" ]; then BIN="$ORB_SLAM3/Examples/Monocular-Inertial/mono_inertial_euroc"
else BIN="$REPO/outputs/bin/mono_inertial_euroc_headless"; [ -x "$BIN" ] || "$REPO/orbslam3/headless/build.sh" > /dev/null; fi
E="$ORB_SLAM3/Examples/Monocular-Inertial"
cd "$OUT"; rc=0
env -i HOME="$HOME" PATH=/usr/bin:/bin DISPLAY="${DISPLAY:-}" XAUTHORITY="${XAUTHORITY:-}" \
    LD_LIBRARY_PATH="$PANGOLIN_PREFIX/lib" \
    "$BIN" "$ORB_SLAM3/Vocabulary/ORBvoc.txt" "$E/EuRoC.yaml" "$DATA" "$E/EuRoC_TimeStamps/MH01.txt" "$NAME" \
    > run.log 2>&1 || rc=$?
echo $rc > exit_code; echo "ORB-SLAM3 exit=$rc, $(wc -l < "f_$NAME.txt") poses -> $OUT/f_$NAME.txt"
