# VINS-Fusion mono+IMU on EuRoC MH_01_easy (no loop closure)

evo 1.38.1, SE(3) Umeyama alignment (`-a`, no scale), 1819 / 1831 poses matched (max dt 0.01 s).

| Metric | RMSE | Mean | Median | Max | Std |
|---|---|---|---|---|---|
| ATE, translation (m) | **0.1807** | 0.1554 | 0.1336 | 0.4159 | 0.0922 |
| RPE, translation, delta 1 m (m) | 0.0341 | 0.0300 | 0.0296 | 0.0968 | 0.0161 |
| RPE, rotation, delta 1 m (deg) | 1.2681 | 0.4087 | 0.1721 | 10.3106 | 1.2004 |

Full evo output: odom_ape.txt, odom_rpe_1m.txt, odom_rpe_1m_rot.txt; raw results in odom_*_results.zip.
