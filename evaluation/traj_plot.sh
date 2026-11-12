#!/bin/bash
# Trajectory overlay vs ground truth (evo_traj, SE(3)-aligned). Usage: evaluation/traj_plot.sh <out_dir> <est.tum>...
set -euo pipefail
source "$(dirname "$0")/../env.sh"
OUT="$1"; shift; EST=(); for f in "$@"; do EST+=("$(realpath "$f")"); done
GT="$REPO/outputs/mh01_groundtruth.tum"; [ -f "$GT" ] || "$REPO/evaluation/gt_to_tum.sh" > /dev/null
unset PYTHONPATH; export MPLBACKEND=Agg; mkdir -p "$OUT"; cd "$OUT"
"$VENV/bin/evo_traj" tum "${EST[@]}" --ref "$GT" -a --plot_mode xy  --save_plot traj_xy.png  > /dev/null 2>&1
"$VENV/bin/evo_traj" tum "${EST[@]}" --ref "$GT" -a --plot_mode xyz --save_plot traj_xyz.png > /dev/null 2>&1
