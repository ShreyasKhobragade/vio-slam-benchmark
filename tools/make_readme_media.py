"""Rebuild the README figures from results/ (light + dark variants).

  assets/trajectories_{light,dark}.png  top-down GT vs VINS-Fusion (+loop) vs ORB-SLAM3, SE(3)-aligned
  assets/ate_runs_{light,dark}.png      ATE RMSE per run, on the window ORB-SLAM3 tracked

Usage: .venv/bin/python -I tools/make_readme_media.py   (needs outputs/mh01_groundtruth.tum: evaluation/gt_to_tum.sh)
"""
import copy
import os
import re

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from evo.core import sync
from evo.tools import file_interface

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
RES = os.path.join(REPO, "results")
ASSETS = os.path.join(REPO, "assets")
GT = os.path.join(REPO, "outputs", "mh01_groundtruth.tum")

# Categorical slots 1-2 of the reference palette (validated light + dark, adjacent and all-pairs).
THEMES = {
    "light": dict(surface="#fcfcfb", ink="#0b0b0b", ink2="#52514e", muted="#898781", grid="#e1e0d9",
                  axis="#c3c2b7", vins="#2a78d6", orb="#eb6834", gt="#898781"),
    "dark": dict(surface="#1a1a19", ink="#f0efec", ink2="#c3c2b7", muted="#898781", grid="#2c2c2a",
                 axis="#383835", vins="#3987e5", orb="#d95926", gt="#898781"),
}
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10, "svg.fonttype": "none"})


def rmse(path):
    for line in open(path):
        m = re.match(r"\s*rmse\s+([\d.]+)", line)
        if m:
            return float(m.group(1))
    raise ValueError(path)


def aligned(est_path, gt):
    ref, est = sync.associate_trajectories(gt, file_interface.read_tum_trajectory_file(est_path), max_diff=0.01)
    est = copy.deepcopy(est)
    est.align(ref, correct_scale=False)  # same SE(3) Umeyama alignment as evo_ape -a
    return est


def style(ax, t):
    ax.set_facecolor(t["surface"])
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)
    for s in ("left", "bottom"):
        ax.spines[s].set_color(t["axis"])
    ax.tick_params(colors=t["muted"], labelcolor=t["ink2"], length=0, pad=6)
    ax.grid(True, color=t["grid"], linewidth=0.6)
    ax.set_axisbelow(True)


def trajectories(t, name, gt):
    vins = aligned(os.path.join(RES, "vins_fusion_loop", "vins_loop_mh01_est.tum"), gt)
    orb = aligned(os.path.join(RES, "orbslam3", "orbslam3_mh01_est.tum"), gt)
    fig, ax = plt.subplots(figsize=(7.8, 6.4), dpi=150, facecolor=t["surface"])
    style(ax, t)
    p = gt.positions_xyz
    ax.plot(p[:, 0], p[:, 1], color=t["gt"], lw=1.2, ls=(0, (4, 3)), label="Ground truth")
    for traj, col, lab in ((vins, t["vins"], "VINS-Fusion + loop closure\nATE 0.062 m, full sequence"),
                           (orb, t["orb"], "ORB-SLAM3 (first run)\nATE 0.097 m, from 46 s in")):
        q = traj.positions_xyz
        ax.plot(q[:, 0], q[:, 1], color=col, lw=1.4, label=lab, solid_capstyle="round")
    ax.set_aspect("equal", adjustable="box")
    ax.set_xlabel("x (m)", color=t["ink2"])
    ax.set_ylabel("y (m)", color=t["ink2"])
    ax.legend(loc="upper left", bbox_to_anchor=(1.03, 1.0), frameon=False, labelcolor=t["ink"], handlelength=2.2,
              borderaxespad=0)
    ax.set_title("EuRoC MH_01_easy, top-down, SE(3)-aligned", color=t["ink"],
                 loc="left", fontsize=11, pad=10)
    fig.tight_layout()
    fig.savefig(os.path.join(ASSETS, f"trajectories_{name}.png"), facecolor=t["surface"])
    plt.close(fig)


def ate_runs(t, name):
    cw = os.path.join(RES, "common_window")
    orb_runs = [rmse(os.path.join(RES, "orbslam3_repeats", f"run_{i}", "ape.txt")) for i in range(1, 6)]
    orb_mean = sum(orb_runs) / len(orb_runs)
    rows = [  # (label, values, color, filled)
        ("VINS-Fusion, odometry only", [rmse(os.path.join(cw, "vins_cropped_ape.txt"))], t["vins"], True),
        ("VINS-Fusion + loop closure", [rmse(os.path.join(cw, "loop_cropped_ape.txt"))], t["vins"], True),
        ("ORB-SLAM3, 5 headless runs", orb_runs, t["orb"], True),
        ("ORB-SLAM3, first run (viewer on)", [rmse(os.path.join(RES, "orbslam3", "ape.txt"))], t["orb"], False),
    ]
    fig, ax = plt.subplots(figsize=(7.8, 3.0), dpi=150, facecolor=t["surface"])
    style(ax, t)
    ax.grid(True, axis="x")
    ax.grid(False, axis="y")
    for y, (lab, vals, col, filled) in enumerate(rows):
        yy = len(rows) - 1 - y
        ax.scatter(vals, [yy] * len(vals), s=64, color=col if filled else t["surface"], edgecolor=col,
                   linewidth=1.6, zorder=3)
        if len(vals) > 1:
            ax.plot([min(vals), max(vals)], [yy, yy], color=col, lw=1.4, alpha=0.5, zorder=2)
            ax.plot([orb_mean] * 2, [yy - 0.22, yy + 0.22], color=t["ink"], lw=1.6, zorder=4)
            ax.annotate(f"mean {orb_mean:.3f} m", (max(vals), yy),
                        xytext=(10, 0), textcoords="offset points", va="center", color=t["ink2"])
        else:
            ax.annotate(f"{vals[0]:.3f} m", (vals[0], yy), xytext=(10, 0), textcoords="offset points",
                        va="center", color=t["ink2"])
    ax.set_yticks(range(len(rows)))
    ax.set_yticklabels([r[0] for r in reversed(rows)], color=t["ink"])
    ax.set_xlim(0, 0.17)
    ax.set_ylim(-0.6, len(rows) - 0.4)
    ax.spines["left"].set_visible(False)
    ax.set_xlabel("ATE RMSE (m), lower is better", color=t["ink2"])
    ax.set_title("ATE RMSE over the span ORB-SLAM3 tracked (626–764 s)", color=t["ink"],
                 loc="left", fontsize=11, pad=10)
    fig.tight_layout()
    fig.savefig(os.path.join(ASSETS, f"ate_runs_{name}.png"), facecolor=t["surface"])
    plt.close(fig)


if __name__ == "__main__":
    gt = file_interface.read_tum_trajectory_file(GT)
    for name, t in THEMES.items():
        trajectories(t, name, gt)
        ate_runs(t, name)
        print(f"wrote assets/trajectories_{name}.png, assets/ate_runs_{name}.png")
