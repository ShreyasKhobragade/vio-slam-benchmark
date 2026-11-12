#!/bin/bash
# Convert a VINS-Fusion run to TUM and evaluate it.
# Usage: vins_fusion/evaluate.sh <run_dir> <result_dir>
#   run_dir/vio.csv       -> <result_dir>/vins_odom_mh01_est.tum, odom_*  (odometry)
#   run_dir/vio_loop.csv  -> <result_dir>/vins_loop_mh01_est.tum, loop_*  (loop-closed, if present)
set -euo pipefail
source "$(dirname "$0")/../env.sh"
RUN="$(realpath "$1")"; OUT="$(realpath -m "$2")"; mkdir -p "$OUT"
PY="$VENV/bin/python -I"; unset PYTHONPATH
EST=()
$PY "$REPO/vins_fusion/vio_to_tum.py" "$RUN/vio.csv" "$OUT/vins_odom_mh01_est.tum"
"$REPO/evaluation/evo_eval.sh" "$OUT/vins_odom_mh01_est.tum" "$OUT" odom_ --plots; EST+=("$OUT/vins_odom_mh01_est.tum")
if [ -f "$RUN/vio_loop.csv" ]; then
    $PY "$REPO/vins_fusion/vio_to_tum.py" "$RUN/vio_loop.csv" "$OUT/vins_loop_mh01_est.tum"
    "$REPO/evaluation/evo_eval.sh" "$OUT/vins_loop_mh01_est.tum" "$OUT" loop_ --plots; EST+=("$OUT/vins_loop_mh01_est.tum")
fi
"$REPO/evaluation/traj_plot.sh" "$OUT" "${EST[@]}"
