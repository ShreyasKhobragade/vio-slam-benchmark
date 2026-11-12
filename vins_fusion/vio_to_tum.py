"""Convert VINS-Fusion vio.csv (t[ns],x,y,z,qw,qx,qy,qz,vx,vy,vz,) to TUM (t[s] x y z qx qy qz qw)."""
import sys

src, dst = sys.argv[1], sys.argv[2]
n = 0
with open(src) as f, open(dst, "w") as g:
    for line in f:
        v = [s for s in line.strip().split(",") if s]
        if len(v) < 8:
            continue
        t, x, y, z, qw, qx, qy, qz = v[:8]
        g.write(f"{float(t) * 1e-9:.9f} {x} {y} {z} {qx} {qy} {qz} {qw}\n")
        n += 1
print(f"wrote {n} poses to {dst}")
