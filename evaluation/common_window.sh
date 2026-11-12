#!/bin/bash
# Like-for-like comparison: crop VINS-Fusion trajectories to the time span ORB-SLAM3 tracked
# (its final map starts ~46 s into MH_01), then evaluate with the same evo recipe.
# Usage: evaluation/common_window.sh   (reads results/*, writes results/common_window/)
set -euo pipefail
source "$(dirname "$0")/../env.sh"
R="$REPO/results"; O="$R/common_window"; mkdir -p "$O"
ORB="$R/orbslam3/orbslam3_mh01_est.tum"
T0=$(head -1 "$ORB" | cut -d' ' -f1); T1=$(tail -1 "$ORB" | cut -d' ' -f1)
crop() { awk -v a="$T0" -v b="$T1" '$1>=a && $1<=b' "$1" > "$2"; }
crop "$R/vins_fusion_odom/vins_odom_mh01_est.tum"      "$O/vins_mh01_est_cropped.tum"
crop "$R/vins_fusion_loop/vins_loop_mh01_est.tum" "$O/vins_loop_mh01_est_cropped.tum"
"$REPO/evaluation/evo_eval.sh" "$O/vins_mh01_est_cropped.tum"      "$O" vins_cropped_
"$REPO/evaluation/evo_eval.sh" "$O/vins_loop_mh01_est_cropped.tum" "$O" loop_cropped_
