# Paths used by every script. Source it; override any variable from the environment.
#   data/MH_01_easy/MH_01_easy.bag     ROS bag (VINS-Fusion)
#   data/MH_01_easy/mav0/              ASL folder (ORB-SLAM3 images + IMU, ground truth for both)
#   third_party/ORB_SLAM3, third_party/install (Pangolin prefix), third_party/VINS-Fusion
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="${DATA:-$REPO/data/MH_01_easy}"
BAG="${BAG:-$DATA/MH_01_easy.bag}"
GT_CSV="${GT_CSV:-$DATA/mav0/state_groundtruth_estimate0/data.csv}"
THIRD_PARTY="${THIRD_PARTY:-$REPO/third_party}"
ORB_SLAM3="${ORB_SLAM3:-$THIRD_PARTY/ORB_SLAM3}"
PANGOLIN_PREFIX="${PANGOLIN_PREFIX:-$THIRD_PARTY/install}"
VENV="${VENV:-$REPO/.venv}"
VINS_IMAGE="${VINS_IMAGE:-ros:vins-fusion-rviz}"
