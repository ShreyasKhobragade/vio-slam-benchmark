#!/bin/bash
# Native build of Pangolin v0.9.6 + ORB-SLAM3 (4452a3c) at C++17, in a clean environment
# (no conda / ROS on PATH). Ubuntu 22.04: system Eigen 3.4, OpenCV 4.5.4, Boost 1.74, gcc 11.
set -euo pipefail
source "$(dirname "$0")/../env.sh"
CLEAN=(env -i HOME="$HOME" PATH=/usr/bin:/bin bash --noprofile --norc -c)
mkdir -p "$THIRD_PARTY"; cd "$THIRD_PARTY"

[ -d Pangolin ] || { git clone https://github.com/stevenlovegrove/Pangolin.git && git -C Pangolin checkout v0.9.6; }
"${CLEAN[@]}" "cd Pangolin && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX='$PANGOLIN_PREFIX' \
    -DBUILD_PYPANGOLIN_MODULE=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF && cmake --build build -j16 && cmake --install build"

if [ ! -d "$ORB_SLAM3" ]; then
    git clone https://github.com/UZ-SLAMLab/ORB_SLAM3.git "$ORB_SLAM3"
    git -C "$ORB_SLAM3" checkout 4452a3c
    git -C "$ORB_SLAM3" apply "$REPO/orbslam3/patches/orbslam3_cxx17.patch"   # -std=c++17, bool++ fix
fi
"${CLEAN[@]}" "cd '$ORB_SLAM3' &&
  for d in Thirdparty/DBoW2 Thirdparty/g2o Thirdparty/Sophus; do
    cmake -S \$d -B \$d/build -DCMAKE_BUILD_TYPE=Release && cmake --build \$d/build -j16; done &&
  (cd Vocabulary && tar -xf ORBvoc.txt.tar.gz) &&
  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DPangolin_DIR='$PANGOLIN_PREFIX/lib/cmake/Pangolin' &&
  cmake --build build -j12"
"$REPO/orbslam3/headless/build.sh"
