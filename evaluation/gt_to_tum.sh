#!/bin/bash
# EuRoC ground truth (mav0/state_groundtruth_estimate0/data.csv, IMU/body frame) -> TUM, via evo_traj.
# Writes outputs/mh01_groundtruth.tum (not committed: 7.4 MB, regenerated from the dataset).
set -euo pipefail
source "$(dirname "$0")/../env.sh"
unset PYTHONPATH; export MPLBACKEND=Agg
mkdir -p "$REPO/outputs"; cd "$REPO/outputs"
"$VENV/bin/evo_traj" euroc "$GT_CSV" --save_as_tum && mv data.tum mh01_groundtruth.tum
echo "$REPO/outputs/mh01_groundtruth.tum"
