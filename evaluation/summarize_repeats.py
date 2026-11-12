"""Summarize results/orbslam3_repeats/run_*/: ATE/RPE (from evo text output), resets (from run.log), tracked span.
Writes <dir>/summary.md and prints it. Usage: python -I evaluation/summarize_repeats.py [results/orbslam3_repeats]"""
import glob, os, re, statistics as st, sys

base = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "results", "orbslam3_repeats"))
T0 = 1403636000.0

def stats(path):
    d = {}
    for line in open(path):
        m = re.match(r"\s*(rmse|mean|median|max|min|std)\s+([\d.eE+-]+)", line)
        if m:
            d[m.group(1)] = float(m.group(2))
    return d

rows = []
for d in sorted(glob.glob(os.path.join(base, "run_*")), key=lambda p: int(p.rsplit("_", 1)[1])):
    log = open(os.path.join(d, "run.log"), errors="replace").read()
    tum = [l.split() for l in open(os.path.join(d, "orbslam3_mh01_est.tum")) if l.strip()]
    rows.append(dict(
        run=os.path.basename(d),
        exit=open(os.path.join(d, "exit_code")).read().strip(),
        resets=log.count("SYSTEM-> Reseting active map"),
        fail_local=log.count("Fail to track local map!"),
        maps=len(set(re.findall(r"Map (\d+) has \d+ KFs", log))),
        t0=float(tum[0][0]) - T0, t1=float(tum[-1][0]) - T0, n=len(tum),
        ape=stats(os.path.join(d, "ape.txt")),
        rpe=stats(os.path.join(d, "rpe_1m.txt"))["rmse"],
        rot=stats(os.path.join(d, "rpe_1m_rot.txt"))["rmse"],
    ))

out = ["| Run | Exit | Map resets | Maps at end | Span (s after 1403636000) | Poses | ATE RMSE (m) | ATE median / max (m) | RPE 1 m trans (m) | RPE 1 m rot (deg) |",
       "|---|---|---|---|---|---|---|---|---|---|"]
for r in rows:
    out.append(f"| {r['run']} | {r['exit']} | {r['resets']} | {r['maps']} | {r['t0']:.1f} – {r['t1']:.1f} | {r['n']} | "
               f"{r['ape']['rmse']:.3f} | {r['ape']['median']:.3f} / {r['ape']['max']:.3f} | {r['rpe']:.3f} | {r['rot']:.3f} |")
a = [r["ape"]["rmse"] for r in rows]
res = [r["resets"] for r in rows]
out += ["", f"ATE RMSE over {len(a)} runs: mean {st.mean(a):.3f} m, min {min(a):.3f}, max {max(a):.3f}, "
        f"std {st.stdev(a) if len(a) > 1 else 0:.3f} (sample std, n-1)",
        f"Map resets ('SYSTEM-> Reseting active map'): {res}, mean {st.mean(res):.1f}"]
txt = "\n".join(out)
open(os.path.join(base, "summary.md"), "w").write(txt + "\n")
print(txt)
