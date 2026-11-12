#!/bin/bash
# Build the upstream VINS-Fusion image (ros:kinetic-perception + Ceres 1.12) and a thin RViz layer on top.
set -euo pipefail
source "$(dirname "$0")/../env.sh"
mkdir -p "$THIRD_PARTY"
if [ ! -d "$THIRD_PARTY/VINS-Fusion" ]; then
    git clone https://github.com/HKUST-Aerial-Robotics/VINS-Fusion "$THIRD_PARTY/VINS-Fusion"
    git -C "$THIRD_PARTY/VINS-Fusion" checkout be55a93
fi
(cd "$THIRD_PARTY/VINS-Fusion/docker" && docker build --tag ros:vins-fusion -f ./Dockerfile ..)   # == upstream `make build`
docker build -t "$VINS_IMAGE" -f "$REPO/vins_fusion/docker/Dockerfile.rviz" "$REPO/vins_fusion/docker"
