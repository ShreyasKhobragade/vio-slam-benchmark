#!/bin/bash
# Extract MH_01_easy from the EuRoC machine_hall.zip (12.7 GB, ETH Research Collection, DOI 10.3929/ethz-b-000690084).
# The server rate-limits scripted downloads (HTTP 429), so download it in a browser first:
#   https://www.research-collection.ethz.ch/server/api/core/bitstreams/7b2419c1-62b5-4714-b7f8-485e5fe3e5fe/content
# Usage: tools/get_data.sh path/to/machine_hall.zip   -> data/MH_01_easy/{MH_01_easy.bag, mav0/}
set -euo pipefail
source "$(dirname "$0")/../env.sh"
ZIP="$(realpath "$1")"; TMP="$DATA/_extract"; mkdir -p "$TMP"
unzip -q -j "$ZIP" machine_hall/MH_01_easy/MH_01_easy.bag machine_hall/MH_01_easy/MH_01_easy.zip -d "$TMP"
mv "$TMP/MH_01_easy.bag" "$DATA/"
unzip -q "$TMP/MH_01_easy.zip" -d "$DATA"           # ASL format: mav0/{cam0,cam1,imu0,state_groundtruth_estimate0,...}
rm -r "$TMP"
ls "$DATA" "$DATA/mav0"
