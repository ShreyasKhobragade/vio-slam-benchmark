# ORB-SLAM3 setup (native build)

ORB-SLAM3 is built natively on Ubuntu 22.04, with no Docker and no sudo. Everything lives under `third_party/`.

## Versions
- ORB_SLAM3 `4452a3c` (master, 2022-02-10), Pangolin `v0.9.6`
- System Eigen 3.4.0, OpenCV 4.5.4, Boost 1.74, gcc 11.4, cmake 3.22.1
- Every build and run step runs in a clean environment (`env -i HOME=$HOME PATH=/usr/bin:/bin bash --noprofile --norc`),
  which keeps conda and ROS 2 Humble off the include and library paths.

## Build
```bash
orbslam3/build.sh
```
The script clones and builds Pangolin v0.9.6 into `third_party/install`. Then it clones ORB-SLAM3 at `4452a3c`, applies
[`patches/orbslam3_cxx17.patch`](../orbslam3/patches/orbslam3_cxx17.patch), builds DBoW2 / g2o / Sophus / ORB-SLAM3,
and builds the headless example (below).

## Data
`tools/get_data.sh` (see [setup_vins_fusion.md](setup_vins_fusion.md#2-dataset)) extracts the ASL folder to
`data/MH_01_easy/mav0/`. ORB-SLAM3 uses `cam0`, `imu0`, and the EuRoC timestamp list shipped with ORB-SLAM3.

## Run and evaluate
```bash
VIEWER=1 orbslam3/run.sh                                   # original example with the Pangolin viewer
orbslam3/run.sh                                            # headless (VIEWER=0, default)
orbslam3/evaluate.sh outputs/orbslam3 results/orbslam3 --plots
N=5 P=3 orbslam3/run_repeats.sh                            # repeatability: 5 runs, 3 in parallel
```
The frame trajectory `f_<name>.txt` (every camera frame, 20 Hz) is the one evaluated, not the keyframe file.

## Headless example
The EuRoC example hard-codes the viewer (`System(..., IMU_MONOCULAR, true)`).
[`orbslam3/headless/mono_inertial_euroc_headless.cc`](../orbslam3/headless/mono_inertial_euroc_headless.cc) is a copy
with only that flag set to `false`. [`headless/build.sh`](../orbslam3/headless/build.sh) compiles it with the exact flags
CMake generated for the original target (`flags.make` / `link.txt`) and links it against the same `libORB_SLAM3.so`,
so nothing in the ORB-SLAM3 tree changes. (Hand-picked flags fail: Pangolin's headers need `-DHAVE_EPOXY` etc.)

## Decisions and workarounds

| Issue | What I did |
|---|---|
| Pangolin v0.9.x sets `CMAKE_CXX_STANDARD 17`, and its headers need C++17 | Chose **Pangolin v0.9.6 + ORB-SLAM3 at C++17** rather than Pangolin v0.6 (2019). C++14 doesn't work with these headers. |
| ORB-SLAM3 `CMakeLists.txt` hard-codes `-std=c++11` | Line 20: `-std=c++11` → `-std=c++17`. Kept `add_definitions(-DCOMPILEDWITHC11)` on purpose, because the code uses it to pick `std::chrono::steady_clock`. |
| C++17 error: `use of an operand of type 'bool' in 'operator++' is forbidden` (`src/LoopClosing.cc:985, 1236, 1809`) | `mnFullBAIdx++;` → `mnFullBAIdx = true;`. This is identical behaviour (bool++ always yields true). Changing the member to `int` would match the evident intent (an abort counter) but would change behaviour vs upstream. |
| Pangolin libs only found transitively (`libpango_windowing.so.0 => not found`) | `LD_LIBRARY_PATH=third_party/install/lib` in `orbslam3/run.sh` |
| Segfault (exit 139) at shutdown while writing `kf_*.txt`, seen once in the first (viewer) run | Known ORB-SLAM3 shutdown crash. Both files were complete. The 5 headless runs exited 0. |
| 12–36 map resets at the start ("Fail to track local map! IMU is not or recently initialized", "Not enough motion for initializing") | Normal for mono-inertial on the MH_01 take-off. The final map starts ~46 s in, so comparisons use a common window ([results.md](results.md)). |
| `error: XDG_RUNTIME_DIR not set` | Side effect of `env -i`; harmless (the X11 viewer works) |
| Pangolin found RealSense2 / OpenNI in `/usr/local` | Harmless; the extra RealSense examples get built too |
