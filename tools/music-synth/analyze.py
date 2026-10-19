"""Mesures objectives des musiques (on ne peut pas les ecouter : Greg juge a l'oreille).

  python analyze.py levels <fichiers...>       duree, pic, RMS actif (regle de Greg : fenetres de 50 ms > -50 dBFS, mono)
  python analyze.py seam <fichiers...>         boucle sans couture : saut a la jonction fin -> debut, compare au reste
  python analyze.py encseam <x.ogg> <x.wav>     la jonction apres encodage, comparee au signal d'avant (render.mjs --wav)
  python analyze.py compare <a.ogg> <b.ogg>    deux rendus du meme theme : decalage, enveloppe, spectre, chroma
  python analyze.py key <fichiers...>          tonalite estimee (profil de chroma) et notes les plus presentes
  python analyze.py profile <fichier> [pas]    niveau (RMS, dBFS) et pic par tranche de `pas` secondes (2 par defaut)

Numpy et soundfile seulement. Lancer avec -I (fichiers audio = donnees)."""
import sys, glob, json
import numpy as np
import soundfile as sf

sys.stdout.reconfigure(encoding="utf-8")
NAMES = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]


def db(x):
    return float(20 * np.log10(max(float(x), 1e-12)))


def load(path):
    d, sr = sf.read(path, always_2d=True, dtype="float64")
    if d.shape[1] == 1:
        d = np.repeat(d, 2, axis=1)
    return d[:, :2], sr


def active_rms_db(mono, sr):
    w = int(sr * 0.05)
    n = len(mono) // w
    fr = mono[: n * w].reshape(n, w)
    r = np.sqrt((fr ** 2).mean(axis=1))
    a = r[r > 10 ** (-50 / 20)]
    return db(np.sqrt((a ** 2).mean())) if len(a) else -120.0


def levels(path):
    d, sr = load(path)
    m = d.mean(axis=1)
    return {"file": path.replace("\\", "/").split("/")[-1], "seconds": round(len(m) / sr, 3), "peakDb": round(db(np.abs(d).max()), 2),
            "monoPeakDb": round(db(np.abs(m).max()), 2), "activeRmsDb": round(active_rms_db(m, sr), 2)}


def seam(path):
    """La jonction d'une boucle : le saut d'echantillon fin -> debut, rapporte aux sauts ordinaires du
    morceau (percentile) ; l'energie haute frequence (> 4 kHz) d'une fenetre de 10 ms centree sur la jonction,
    rapportee a la mediane des memes fenetres ailleurs (un clic la fait monter) ; l'ecart de niveau
    entre la derniere et la premiere demi-seconde ; la continuite de phase (prediction lineaire)."""
    d, sr = load(path)
    n = len(d)
    jump = np.abs(d[0] - d[-1]).max()
    steps = np.abs(np.diff(d, axis=0)).max(axis=1)
    pct = float((steps < jump).mean() * 100)
    # second difference (phase / slope continuity): x[0] predicted from x[-2], x[-1]
    pred = 2 * d[-1] - d[-2]
    curv = np.abs(d[0] - pred).max()
    curvs = np.abs(d[2:] - 2 * d[1:-1] + d[:-2]).max(axis=1)
    curv_pct = float((curvs < curv).mean() * 100)
    # HF energy around the seam vs elsewhere
    w = int(0.01 * sr)
    looped = np.concatenate([d[-w:], d[:w]])

    def hf(seg):
        x = seg.mean(axis=1) * np.hanning(len(seg))
        s = np.abs(np.fft.rfft(x)) ** 2
        f = np.fft.rfftfreq(len(x), 1 / sr)
        return s[f > 4000].sum() + 1e-18

    ref = [hf(d[i:i + 2 * w]) for i in np.linspace(w, n - 3 * w, 200).astype(int)]
    hf_ratio = hf(looped) / float(np.median(ref))
    hs = int(0.5 * sr)
    lvl_end = db(np.sqrt((d[-hs:] ** 2).mean()))
    lvl_start = db(np.sqrt((d[:hs] ** 2).mean()))
    return {"file": path.replace("\\", "/").split("/")[-1], "jump": round(float(jump), 5), "jumpPercentile": round(pct, 1),
            "slopeBreakPercentile": round(curv_pct, 1), "hfAtSeamVsMedian": round(float(hf_ratio), 2),
            "levelEndDb": round(lvl_end, 2), "levelStartDb": round(lvl_start, 2), "levelStepDb": round(lvl_start - lvl_end, 2)}


def encoded_seam(ogg, wav):
    """L'encodeur abime-t-il la jonction ? Le .ogg decode compare au signal d'avant l'encodage (.wav
    flottant, render.mjs --wav) : l'erreur sur les 20 ms de part et d'autre de la jonction (fin, puis
    debut) rapportee a l'erreur mediane des memes fenetres ailleurs (1 = la jonction n'est pas abimee)."""
    a, sr = load(ogg)
    b, _ = load(wav)
    n = min(len(a), len(b))
    err = np.abs(a[:n] - b[:n]).max(axis=1)
    w = int(0.02 * sr)
    seam = max(err[:w].max(), err[n - w:].max())
    ref = np.median([err[i:i + w].max() for i in np.linspace(w, n - 2 * w, 400).astype(int)])
    wrap_ogg = np.concatenate([a[n - w:n], a[:w]])
    wrap_wav = np.concatenate([b[n - w:n], b[:w]])
    return {"file": ogg.replace("\\", "/").split("/")[-1], "lengthDiffSamples": int(len(a) - len(b)),
            "seamErrorVsMedian": round(float(seam / (ref + 1e-12)), 2),
            "wrapMaxDiff": round(float(np.abs(wrap_ogg - wrap_wav).max()), 4), "typicalMaxErr": round(float(ref), 4)}


def stft_mag(x, sr, size=8192, hop=2048):
    win = np.hanning(size)
    frames = [np.abs(np.fft.rfft(x[i:i + size] * win)) for i in range(0, len(x) - size, hop)]
    return np.array(frames), np.fft.rfftfreq(size, 1 / sr)


def chroma(x, sr):
    S, f = stft_mag(x, sr)
    keep = (f > 55) & (f < 2000)
    midi = 69 + 12 * np.log2(f[keep] / 440.0)
    pcs = np.round(midi).astype(int) % 12
    C = np.zeros((S.shape[0], 12))
    for p in range(12):
        C[:, p] = (S[:, keep][:, pcs == p] ** 2).sum(axis=1)
    return C


def bands(x, sr):
    S, f = stft_mag(x, sr)
    P = (S ** 2).mean(axis=0)
    edges = 31.25 * 2 ** (np.arange(0, 10.5, 1 / 3))
    out = []
    for lo, hi in zip(edges[:-1], edges[1:]):
        k = (f >= lo) & (f < hi)
        out.append(10 * np.log10(P[k].sum() + 1e-18))
    return np.array(out), edges


def compare(a, b):
    A, sra = load(a)
    B, srb = load(b)
    assert sra == srb
    sr = sra
    ma, mb = A.mean(axis=1), B.mean(axis=1)
    # circular lag (both are loops of a cycle): the shift of b that best matches the chroma frames of a
    ca, cb = chroma(ma, sr), chroma(mb, sr)
    k = min(len(ca), len(cb))
    na = ca[:k] / (np.linalg.norm(ca[:k], axis=1, keepdims=True) + 1e-12)
    nb = cb[:k] / (np.linalg.norm(cb[:k], axis=1, keepdims=True) + 1e-12)
    sims = [float(np.median((na * np.roll(nb, s, axis=0)).sum(axis=1))) for s in range(k)]
    shift = int(np.argmax(sims))
    num = np.array([sims[shift]])
    lag_samples = shift * 2048
    # envelope (20 ms) correlation at that lag
    h = int(0.02 * sr)
    n = min(len(ma), len(mb))
    env = lambda x: np.sqrt(np.convolve(x ** 2, np.ones(h) / h, "same")[::h])
    ea, eb = env(ma[:n]), env(np.roll(mb[:n], lag_samples))
    env_corr = float(np.corrcoef(ea, eb)[0, 1])
    lag = lag_samples / h
    ba, edges = bands(ma, sr)
    bb, _ = bands(mb, sr)
    ba -= ba.max()
    bb -= bb.max()
    side = lambda d: db(np.sqrt(((d[:, 0] - d[:, 1]) ** 2).mean()) / (np.sqrt(((d[:, 0] + d[:, 1]) ** 2).mean()) + 1e-12))
    S1, f = stft_mag(ma, sr)
    S2, _ = stft_mag(mb, sr)
    cent = lambda S: float((S.mean(axis=0) * f).sum() / S.mean(axis=0).sum())
    return {"a": levels(a), "b": levels(b), "lagSeconds": round(lag * h / sr, 3), "envelopeCorrelation": round(env_corr, 3),
            "chromaFrameSimilarityMedian": round(float(np.median(num)), 3),
            "chromaProfileCorrelation": round(float(np.corrcoef(ca.sum(axis=0), cb.sum(axis=0))[0, 1]), 4),
            "spectrumThirdOctaveMaxDiffDb": round(float(np.abs(ba - bb)[3:28].max()), 2),
            "spectrumThirdOctaveMeanDiffDb": round(float(np.abs(ba - bb)[3:28].mean()), 2),
            "centroidHz": [round(cent(S1)), round(cent(S2))], "sideToMidDb": [round(side(A), 2), round(side(B), 2)]}


MAJ = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
MIN = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])


def key(path):
    d, sr = load(path)
    c = chroma(d.mean(axis=1), sr).sum(axis=0)
    best = max(((np.corrcoef(np.roll(p, k), c)[0, 1], NAMES[k] + ("" if p is MAJ else "m")) for k in range(12) for p in (MAJ, MIN)))
    top = [NAMES[i] for i in np.argsort(-c)[:7]]
    return {"file": path.replace("\\", "/").split("/")[-1], "key": best[1], "fit": round(float(best[0]), 3), "topPitchClasses": top}


def profile(path, step=2.0):
    d, sr = load(path)
    m = d.mean(axis=1)
    w = int(step * sr)
    rows = []
    for i in range(0, len(m), w):
        seg = m[i:i + w]
        rows.append(f"{i / sr:6.1f}s {db(np.sqrt((seg ** 2).mean())):6.1f} dB  pic {db(np.abs(d[i:i + w]).max()):6.1f}")
    return rows


if __name__ == "__main__":
    cmd, rest = sys.argv[1], sys.argv[2:]
    if cmd == "profile":
        print("\n".join(profile(rest[0], float(rest[1]) if len(rest) > 1 else 2.0)))
        sys.exit(0)
    files = [f for p in rest for f in sorted(glob.glob(p))] if cmd not in ("compare", "encseam") else rest
    if cmd == "encseam":
        print(json.dumps(encoded_seam(files[0], files[1]), ensure_ascii=False))
    elif cmd == "compare":
        print(json.dumps(compare(files[0], files[1]), ensure_ascii=False))
    else:
        fn = {"levels": levels, "seam": seam, "key": key}[cmd]
        for f in files:
            print(json.dumps(fn(f), ensure_ascii=False))
