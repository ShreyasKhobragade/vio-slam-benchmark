#!/bin/bash
# Convert an ORB-SLAM3 run (f_*.txt frame trajectory) to TUM and evaluate it.
# Usage: orbslam3/evaluate.sh <run_dir> <result_dir> [--plots]
set -euo pipefail
source "$(dirname "$0")/../env.sh"
RUN="$(realpath "$1")"; OUT="$(realpath -m "$2")"; mkdir -p "$OUT"; unset PYTHONPATH
F=$(ls "$RUN"/f_*.txt | head -1)
"$VENV/bin/python" -I "$REPO/orbslam3/orb_to_tum.py" "$F" "$OUT/orbslam3_mh01_est.tum"
"$REPO/evaluation/evo_eval.sh" "$OUT/orbslam3_mh01_est.tum" "$OUT" "" "${3:-}"
for f in run.log exit_code; do [ -f "$RUN/$f" ] && cp "$RUN/$f" "$OUT/"; done
if [ "${3:-}" = "--plots" ]; then "$REPO/evaluation/traj_plot.sh" "$OUT" "$OUT/orbslam3_mh01_est.tum"; fi
