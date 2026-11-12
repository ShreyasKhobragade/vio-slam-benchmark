# VINS-Fusion setup (Docker)

VINS-Fusion `be55a93` targets ROS Kinetic (Ubuntu 16.04), so it runs in the upstream Docker image. A thin
layer adds RViz to that image, so the host doesn't need ROS 1. Mono + IMU, EuRoC config, CPU only.

Tested on Ubuntu 22.04.5, 32 cores, 31 GB RAM, Docker 29.9.2 (user in the `docker` group, no sudo), X11.

## 1. Build the images
```bash
vins_fusion/build_docker.sh
```
This clones VINS-Fusion into `third_party/` at `be55a93` and builds:
- `ros:vins-fusion` (4.2 GB): the upstream `docker build --tag ros:vins-fusion -f ./Dockerfile ..`, which is `make build`.
- `ros:vins-fusion-rviz`: [`vins_fusion/docker/Dockerfile.rviz`](../vins_fusion/docker/Dockerfile.rviz), which adds `ros-kinetic-rviz`.

## 2. Dataset
The old EuRoC page now says "permanently moved". The files are on the ETH Research Collection
(DOI [10.3929/ethz-b-000690084](https://doi.org/10.3929/ethz-b-000690084)). There is no per-sequence download:
MH_01_easy is inside `machine_hall.zip` (12.7 GB, MH_01–05). The server answers scripted downloads with HTTP 429,
so download it in a browser, then:
```bash
tools/get_data.sh ~/Downloads/machine_hall.zip      # -> data/MH_01_easy/{MH_01_easy.bag, mav0/}
```

## 3. Config
[`vins_fusion/config/`](../vins_fusion/config) is a copy of upstream `config/euroc/euroc_mono_imu_config.yaml` +
`cam0_mei.yaml`. The only change is `output_path` / `pose_graph_save_path` set to `/root/output/`.

## 4. Run
```bash
LOOP=0 vins_fusion/run.sh                 # odometry only (vins_node)            -> outputs/vins_odom/vio.csv
LOOP=1 vins_fusion/run.sh                 # + loop_fusion_node (4-DoF pose graph) -> outputs/vins_loop/vio_loop.csv
LOOP=1 RVIZ=1 vins_fusion/run.sh          # with RViz on the host display
```
One container runs roscore, `vins_node`, optionally `loop_fusion_node` and RViz, and `rosbag play` in real time (~188 s).
- `vio.csv` is `t[ns],x,y,z,qw,qx,qy,qz,vx,vy,vz`, about 10 Hz.
- `vio_loop.csv` holds the loop-closed keyframe poses `t[ns],x,y,z,qw,qx,qy,qz`, about 6 Hz. It is rewritten whenever a loop closes.

## 5. Evaluate
```bash
vins_fusion/evaluate.sh outputs/vins_loop results/vins_fusion_loop
```
This converts both CSVs to TUM ([`vio_to_tum.py`](../vins_fusion/vio_to_tum.py)) and runs the shared evo recipe
([`evaluation/evo_eval.sh`](../evaluation/evo_eval.sh)).

## What failed, and the workarounds

| Problem | Workaround |
|---|---|
| Upstream Dockerfile: `make -j$(USE_PROC)` is command substitution, so it fails with `USE_PROC: not found` and runs an unbounded `make -j` | Harmless on 32 cores / 31 GB; left as is |
| Upstream `run.sh` needs ROS 1 + RViz on the host and uses `xhost` | `vins_fusion/run.sh`: RViz runs in the container. X auth works by mounting `$XAUTHORITY` read-only with `--net=host`, so no `xhost` |
| The container's Mesa (16.04) can't use the host NVIDIA driver | `LIBGL_ALWAYS_SOFTWARE=1` (llvmpipe) |
| D-Bus warning about an empty machine-id in the container | Mount `/etc/machine-id:ro` |
| `output_path: "~/output/"`: `~` is not expanded in C++, so `vio.csv` would silently not be written | Absolute `/root/output/` in the config copy |
| The container writes files as root | The script `chown`s the output back to the host user |
| `vins_node` / `loop_fusion_node` print `Aborted (core dumped)` on SIGINT | Happens after the bag ends; output files are complete |
| ETH server returned HTTP 429 to curl / range requests | Manual browser download |
| evo `--plot` opens a blocking window (evo ignores `MPLBACKEND`) | `--save_plot` only |
| `pip` warns `launch-ros requires setuptools` | The host's ROS 2 `PYTHONPATH` leaks in. Harmless; the scripts `unset PYTHONPATH` |
| `evo_res --save_table` produced no table | Tables written by hand / by `evaluation/summarize_repeats.py` |
