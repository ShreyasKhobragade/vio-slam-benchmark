#!/bin/bash
# Repeatability: N headless runs (P in parallel), each evaluated, then summarized.
# Usage: [N=5] [P=3] orbslam3/run_repeats.sh  -> outputs/orbslam3_repeats/run_i, results/orbslam3_repeats/
set -euo pipefail
source "$(dirname "$0")/../env.sh"
N="${N:-5}"; P="${P:-3}"
"$REPO/orbslam3/headless/build.sh" > /dev/null
for ((i = 1; i <= N; i++)); do
    OUT="$REPO/outputs/orbslam3_repeats/run_$i" VIEWER=0 "$REPO/orbslam3/run.sh" &
    (( i % P == 0 )) && wait
done; wait
for ((i = 1; i <= N; i++)); do
    "$REPO/orbslam3/evaluate.sh" "$REPO/outputs/orbslam3_repeats/run_$i" "$REPO/results/orbslam3_repeats/run_$i"
done
"$VENV/bin/python" -I "$REPO/evaluation/summarize_repeats.py" "$REPO/results/orbslam3_repeats"
