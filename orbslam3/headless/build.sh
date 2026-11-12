#!/bin/bash
# Build mono_inertial_euroc_headless: a copy of Examples/Monocular-Inertial/mono_inertial_euroc.cc whose only
# change is the viewer flag (true -> false), compiled with the exact flags CMake generated for the original
# target and linked against the same libORB_SLAM3.so. Nothing in the ORB-SLAM3 tree is modified.
set -euo pipefail
source "$(dirname "$0")/../../env.sh"
H="$REPO/orbslam3/headless"; B="$ORB_SLAM3/build"; T="$B/CMakeFiles/mono_inertial_euroc.dir"
OUTBIN="$REPO/outputs/bin"; mkdir -p "$OUTBIN"
get() { sed -n "s/^$1 = //p" "$T/flags.make"; }
LINK="$(sed -e "s#CMakeFiles/mono_inertial_euroc.dir/Examples/Monocular-Inertial/mono_inertial_euroc.cc.o#$OUTBIN/headless.o#" \
            -e "s#-o ../Examples/Monocular-Inertial/mono_inertial_euroc#-o $OUTBIN/mono_inertial_euroc_headless#" "$T/link.txt")"
cd "$B"     # link.txt paths are relative to the build dir
env -i HOME="$HOME" PATH=/usr/bin:/bin bash --noprofile --norc -c "
  /usr/bin/c++ $(get CXX_DEFINES) $(get CXX_INCLUDES) $(get CXX_FLAGS) -c '$H/mono_inertial_euroc_headless.cc' -o '$OUTBIN/headless.o' &&
  $LINK"
echo "$OUTBIN/mono_inertial_euroc_headless"
