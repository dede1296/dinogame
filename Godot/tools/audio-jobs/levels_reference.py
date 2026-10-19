"""Mesure les fichiers audio EXISTANTS du jeu (suivis par git) et ecrit tools/audio-jobs/levels_reference.json :
par categorie, mediane / min / max du RMS actif (fenetres de 50 ms au-dessus de -50 dBFS) et du pic, en dBFS.
Usage (depuis Godot/) : python tools/audio-jobs/levels_reference.py
Les sons neufs (non suivis par git) sont exclus : ils se calent ensuite sur ces medianes (normalize_to_category.mjs)."""
import json, re, subprocess, sys, numpy as np, soundfile as sf
sys.stdout.reconfigure(encoding="utf-8")
def db(x): return float(20 * np.log10(max(x, 1e-9)))
def measure(path):
    d, sr = sf.read(path, always_2d=True)
    m = d.mean(axis=1); w = int(sr * 0.05)
    n = len(m) // w
    if n == 0: return None
    frames = m[: n * w].reshape(n, w)
    rms = np.sqrt((frames ** 2).mean(axis=1))
    act = rms[rms > 10 ** (-50 / 20)]
    if len(act) == 0: return None
    return {"activeRmsDb": db(np.sqrt((act ** 2).mean())), "peakDb": db(np.abs(m).max()), "seconds": len(m) / sr}
def category(path, seconds):
    p = path.split("assets/audio/")[1]; folder = p.split("/")[0]; name = p.split("/")[-1].rsplit(".", 1)[0]
    if folder == "footsteps": return "footsteps/" + re.sub(r"\d+$", "", name)
    if folder == "ambience": return "ambience-bed" if seconds >= 10 else "ambience-call"
    return folder
files = subprocess.run(["git", "ls-files", "assets/audio"], capture_output=True, text=True).stdout.split()
groups, items = {}, {}
for f in files:
    if not re.search(r"\.(ogg|mp3|wav)$", f) or "/voices/" in f: continue
    try: r = measure(f)
    except Exception as e: print("ignore", f, e); continue
    if not r: continue
    c = category(f, r["seconds"]); items[f] = {"category": c, **{k: round(v, 1) for k, v in r.items()}}
    groups.setdefault(c, []).append(r)
ref = {}
for c, rs in sorted(groups.items()):
    a = [r["activeRmsDb"] for r in rs]; p = [r["peakDb"] for r in rs]
    ref[c] = {"count": len(rs), "activeRmsDb": {"median": round(float(np.median(a)), 1), "min": round(min(a), 1), "max": round(max(a), 1)},
              "peakDb": {"median": round(float(np.median(p)), 1), "min": round(min(p), 1), "max": round(max(p), 1)}}
    print(f"{c:22s} n={len(rs):3d} RMS actif med {ref[c]['activeRmsDb']['median']:6.1f} [{ref[c]['activeRmsDb']['min']:.1f};{ref[c]['activeRmsDb']['max']:.1f}]  pic med {ref[c]['peakDb']['median']:6.1f} [{ref[c]['peakDb']['min']:.1f};{ref[c]['peakDb']['max']:.1f}]")
json.dump({"categories": ref, "files": items}, open("tools/audio-jobs/levels_reference.json", "w", encoding="utf-8"), indent=1, ensure_ascii=False)
