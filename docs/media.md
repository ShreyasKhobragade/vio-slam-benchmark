# Media: how the clips, GIFs and figures were made

**The videos and GIFs come from separate visual-only runs, recorded on screen. No numbers in this repo come
from them.** The scored runs are headless with nothing recording, so recording can't affect timing.

Recorded on X11 (GNOME Shell, 2560×1600) with ffmpeg 4.4.2 `x11grab`. The capture area is the window's on-screen
rectangle (found with `wmctrl` + `xwininfo`), and the mouse pointer is hidden. ffmpeg 4.4 has `-window_id`, but on GNOME
it often records GL windows as black, so the scripts capture the window's screen area instead.

| File | What it shows | Format |
|---|---|---|
| [`assets/vins_loop_rviz.mp4`](../assets/vins_loop_rviz.mp4) | VINS-Fusion + loop_fusion in RViz (upstream config), bag seconds ~100–180: the return passes, loop closures and the end. Green: VIO odometry path. Red: loop-closed pose graph. Lower left: tracked image and loop-match image. | 1280×790, 30 fps, 80 s, H.264 |
| [`assets/orbslam3_viewer.mp4`](../assets/orbslam3_viewer.mp4) | ORB-SLAM3 Pangolin Map Viewer (map points, keyframes, inertial graph), from 55 s after the window opens, i.e. just after the final map initializes. | 1280×960 (upscaled from the 1024×768 window), 30 fps, 80 s, H.264 |
| [`assets/vins_loop_rviz.gif`](../assets/vins_loop_rviz.gif) | Same as the MP4, **2× speed** | 800×494, 12 fps, 40 s, 9.4 MB |
| [`assets/orbslam3_viewer.gif`](../assets/orbslam3_viewer.gif) | Same as the MP4, **2× speed** | 800×600, 12 fps, 40 s, 7.0 MB |
| `assets/trajectories_{light,dark}.png` | Top-down GT vs VINS + loop closure vs ORB-SLAM3 (first run), SE(3)-aligned | `tools/make_readme_media.py` |
| `assets/ate_runs_{light,dark}.png` | ATE RMSE per run over the common window | `tools/make_readme_media.py` |
| `assets/ape_map_vins_loop.png`, `assets/ape_map_orbslam3.png` | Trajectory coloured by ATE (evo `--save_plot`) | copies of `results/vins_fusion_loop/loop_ape_plot_map.png`, `results/orbslam3/ape_plot_map.png` |

The GIFs play at 2× speed because the full 80 s at 12 fps and 800 px came to 16.5 MB. Speeding up keeps the
whole clip under the 10 MB target without cutting half of it.

## Commands
```bash
tools/record_media.sh vins        # VINS + RViz, records 'RViz' from bag_start + 100 s, for 80 s
tools/record_media.sh orbslam3    # ORB-SLAM3 with viewer, records 'Map Viewer' from window-up + 55 s, for 80 s
.venv/bin/python -I tools/make_readme_media.py
```
[`tools/record_window.sh`](../tools/record_window.sh) `<title-regex> <seconds> <out.mp4>` raises the window and runs:
```bash
ffmpeg -f x11grab -draw_mouse 0 -framerate 30 -video_size ${W}x${H} -i :0+${X},${Y} -t 80 \
       -vf "scale=1280:-2:flags=lanczos,fps=30" -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p \
       -movflags +faststart out.mp4
```
[`tools/make_gif.sh`](../tools/make_gif.sh) `in.mp4 out.gif` makes the GIF in two passes, with a palette:
```bash
F="setpts=0.5*PTS,fps=12,scale=800:-1:flags=lanczos"
ffmpeg -i in.mp4 -vf "$F,palettegen=stats_mode=diff" palette.png
ffmpeg -i in.mp4 -i palette.png -lavfi "$F[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" out.gif
```
Keep the window visible and the screen unlocked while recording.
