#!/bin/bash
# The one evo recipe used for every number in this repo (evo 1.38.1):
#   ATE  = evo_ape -a -r trans_part                        (SE(3) Umeyama, no scale correction)
#   RPE  = evo_rpe -a -r trans_part --delta 1 --delta_unit m
#   RPEr = evo_rpe -a -r angle_deg  --delta 1 --delta_unit m
# Usage: evaluation/evo_eval.sh <est.tum> <out_dir> [prefix] [--plots]
#   writes <prefix>ape.txt, <prefix>rpe_1m.txt, <prefix>rpe_1m_rot.txt (+ *_results.zip),
#   and with --plots: <prefix>ape_plot_*.png, <prefix>rpe_1m_plot_*.png
set -euo pipefail
source "$(dirname "$0")/../env.sh"
EST="$(realpath "$1")"; OUT="$2"; P="${3:-}"; PLOTS="${4:-}"
GT="$REPO/outputs/mh01_groundtruth.tum"
[ -f "$GT" ] || "$REPO/evaluation/gt_to_tum.sh" > /dev/null
unset PYTHONPATH; export MPLBACKEND=Agg      # keep host ROS 2 python packages out; evo --plot would block
B="$VENV/bin"; mkdir -p "$OUT"; cd "$OUT"
PA=(); PR=()
if [ "$PLOTS" = "--plots" ]; then
    PA=(--plot_mode xy --save_plot "${P}ape_plot.png"); PR=(--plot_mode xy --save_plot "${P}rpe_1m_plot.png")
fi
"$B/evo_ape" tum "$GT" "$EST" -a -r trans_part -v "${PA[@]}" --save_results "${P}ape_results.zip" > "${P}ape.txt"
"$B/evo_rpe" tum "$GT" "$EST" -a -r trans_part --delta 1 --delta_unit m -v "${PR[@]}" \
    --save_results "${P}rpe_1m_results.zip" > "${P}rpe_1m.txt"
"$B/evo_rpe" tum "$GT" "$EST" -a -r angle_deg --delta 1 --delta_unit m -v \
    --save_results "${P}rpe_1m_rot_results.zip" > "${P}rpe_1m_rot.txt"
printf '%-28s ATE %s m | RPE1m %s m | RPE1m %s deg\n' "$(basename "$EST")" \
    "$(awk '$1=="rmse"{printf "%.3f",$2}' "${P}ape.txt")" "$(awk '$1=="rmse"{printf "%.3f",$2}' "${P}rpe_1m.txt")" \
    "$(awk '$1=="rmse"{printf "%.3f",$2}' "${P}rpe_1m_rot.txt")"
