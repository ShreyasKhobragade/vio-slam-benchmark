#!/bin/bash
# Run VINS-Fusion mono+IMU on MH_01_easy in Docker (roscore, vins_node, optional loop_fusion_node and RViz
# all in one container), playing the bag in real time (~188 s).
#
# Usage: [LOOP=1] [RVIZ=0] [AUTO_EXIT=0] [OUT=outputs/vins_loop] vins_fusion/run.sh
#   LOOP=1       also run loop_fusion_node (loop closure / 4-DoF pose graph); LOOP=0 = odometry only
#   RVIZ=1       show RViz on the host X display (software GL); 0 = headless (use for scored runs)
#   AUTO_EXIT=1  close RViz when the run ends instead of waiting for its window to be closed
# Writes to $OUT: vio.csv (odometry, t[ns],x,y,z,qw,qx,qy,qz,vx,vy,vz), vio_loop.csv (LOOP=1, loop-closed
#   keyframes), vins_run.log, loop_fusion.log, bag_start (unix time `rosbag play` started), DONE
set -euo pipefail
source "$(dirname "$0")/../env.sh"
LOOP="${LOOP:-1}"; RVIZ="${RVIZ:-0}"; AUTO_EXIT="${AUTO_EXIT:-0}"
OUT="$(realpath -m "${OUT:-$REPO/outputs/vins_$([ "$LOOP" = 1 ] && echo loop || echo odom)}")"
[ -f "$BAG" ] || { echo "bag not found: $BAG (see docs/setup_vins_fusion.md)" >&2; exit 1; }
mkdir -p "$OUT"

X_ARGS=()
if [ "$RVIZ" = "1" ]; then
    [ -n "${DISPLAY:-}" ] || { echo "DISPLAY not set; run with RVIZ=0" >&2; exit 1; }
    # No `xhost +`: share the X socket and the user's cookie read-only; --net=host keeps the hostname
    # identical so the cookie matches. The container's Mesa (16.04) can't use the host NVIDIA driver.
    X_ARGS=(-e DISPLAY="$DISPLAY" -e QT_X11_NO_MITSHM=1 -e LIBGL_ALWAYS_SOFTWARE=1
            -v /tmp/.X11-unix:/tmp/.X11-unix:ro -v /etc/machine-id:/etc/machine-id:ro
            -v "${XAUTHORITY:-$HOME/.Xauthority}":/root/.Xauthority:ro)
fi

# The config's output_path is /root/output/ (absolute: `~` is not expanded by VINS and vio.csv would silently not be written).
docker run --rm --net=host "${X_ARGS[@]}" \
    -e LOOP="$LOOP" -e RVIZ="$RVIZ" -e AUTO_EXIT="$AUTO_EXIT" -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
    -v "$REPO/vins_fusion/config":/root/config:ro \
    -v "$(realpath "$BAG")":/root/data/MH_01_easy.bag:ro \
    -v "$OUT":/root/output \
    "$VINS_IMAGE" /bin/bash -c '
        source /root/catkin_ws/devel/setup.bash
        rm -f /root/output/DONE; mkdir -p /root/output/pose_graph
        roscore > /root/output/roscore.log 2>&1 &
        until rostopic list >/dev/null 2>&1; do sleep 0.5; done
        if [ "$RVIZ" = "1" ]; then
            rviz -d /root/catkin_ws/src/VINS-Fusion/config/vins_rviz_config.rviz > /root/output/rviz.log 2>&1 &
            RVIZ_PID=$!
        fi
        rosrun vins vins_node /root/config/euroc_mono_imu_config.yaml > /root/output/vins_run.log 2>&1 &
        PIDS=$!
        if [ "$LOOP" = "1" ]; then
            rosrun loop_fusion loop_fusion_node /root/config/euroc_mono_imu_config.yaml > /root/output/loop_fusion.log 2>&1 &
            PIDS="$PIDS $!"
        fi
        sleep 5
        date +%s.%N > /root/output/bag_start
        rosbag play /root/data/MH_01_easy.bag
        sleep 10                                   # let the estimator / pose graph drain their queues
        kill -INT $PIDS; for p in $PIDS; do wait $p || true; done   # vins_node aborts on SIGINT; files are complete
        chown -R "$HOST_UID:$HOST_GID" /root/output; touch /root/output/DONE
        echo "VINS finished: $(wc -l < /root/output/vio.csv) odometry poses" \
             "$([ -f /root/output/vio_loop.csv ] && echo "/ $(wc -l < /root/output/vio_loop.csv) loop-closed keyframes")"
        if [ "$RVIZ" = "1" ]; then
            if [ "$AUTO_EXIT" = "1" ]; then kill $RVIZ_PID || true; else echo "Close the RViz window to exit."; fi
            wait $RVIZ_PID || true
        fi
        chown -R "$HOST_UID:$HOST_GID" /root/output
    '
