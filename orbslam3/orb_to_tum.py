"""Convert ORB-SLAM3 SaveTrajectoryEuRoC output (t[ns] x y z qx qy qz qw) to TUM (t[s] ...)."""
import sys

src, dst = sys.argv[1], sys.argv[2]
n = 0
with open(src) as f, open(dst, "w") as g:
    for line in f:
        v = line.split()
        if len(v) != 8:
            continue
        g.write(f"{float(v[0]) * 1e-9:.9f} {' '.join(v[1:])}\n")
        n += 1
print(f"wrote {n} poses to {dst}")
