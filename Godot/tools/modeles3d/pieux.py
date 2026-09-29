"""Palissade en vraie 3D (maisons.py, sortes à clé « pieux » dans maisons.json) : des pieux taillés
en pointe liés par une corde. Le dessin du jeu, de face, est la vue.

Chaque pieu est un tronc tourné qui suit la silhouette du dessin rang par rang (largeur, penchée,
pointe taillée : là où le dessin s'amincit), un peu bosselé (« bosses », px) ; son devant est
peint par le dessin, son dos par le même dessin (le point de devant au même endroit). Les rangs
où la corde passe devant le pieu (plus larges, ou reliés au pieu voisin) ne comptent pas : la
largeur y est tirée des rangs voisins.
La corde est un volume à part, peint de son propre motif (tiré du dessin, le long du tube) : des
tours autour de chaque pieu (« tours » : px du milieu du tour sur le devant du pieu ; deux
tours), les brins tendus d'un pieu à l'autre et le bout qui pend (« brins », « bout » : lignes
tracées sur le dessin, relevées dans le plan des axes des pieux).
Repère : X à droite, Y vers le fond (devant des pieux à y = 0), Z en haut ; origine au milieu du
pied, au bas du dessin.
"""
import math
import numpy as np


# ================================================================== le dessin (numpy seul)
def _runs(row):
    d = np.diff(np.concatenate([[0], row.astype(np.int8), [0]]))
    return list(zip(np.nonzero(d == 1)[0], np.nonzero(d == -1)[0] - 1))


def _medfilt(a, size):
    half = size // 2
    p = np.pad(a, half, mode="edge")
    return np.median(np.lib.stride_tricks.sliding_window_view(p, size), axis=-1)


def analyse(cfg, im):
    """Profil de chaque pieu (px du dessin) : rangs du bas à la pointe, bords gauche et droit
    (rangs de la corde remplacés par leurs voisins). -> {"pieux": [{"v", "g", "d"}], "bas"}."""
    p = cfg["pieux"]
    alpha = im[..., 3] > 0.5
    H, W = alpha.shape
    out = []
    for ca, cb in p["colonnes"]:
        rows, left, right = [], [], []
        ys = [y for y in range(H) if alpha[y, ca:cb + 1].any()]
        center = None
        for y in sorted(ys, reverse=True):   # du bas vers le haut : le milieu suit le pieu
            runs = [(a + ca, b + ca) for a, b in _runs(alpha[y, ca:cb + 1])]
            if not runs:
                continue
            c = (ca + cb) / 2.0 if center is None else center
            a, b = min(runs, key=lambda r: 0 if r[0] <= c <= r[1] else min(abs(r[0] - c), abs(r[1] - c)))
            rows.append(y)
            left.append(float(a))
            right.append(float(b) + 1.0)
            center = 0.8 * (center if center is not None else (a + b) / 2.0) + 0.2 * (a + b + 1) / 2.0
        rows, left, right = np.array(rows), np.array(left), np.array(right)
        width = right - left
        ref = _medfilt(width, 31)
        bad = (width > ref + p.get("ecart_corde", 5)) | (left <= ca) | (right >= cb + 1)
        bad &= rows < rows.max() - 3   # (le pied, lui, reste)
        for band in p.get("rangs_corde", []):   # rangs tracés où la corde passe devant
            bad |= (rows >= band[0]) & (rows <= band[1])
        ok = ~bad
        idx = np.arange(len(rows))
        left = np.interp(idx, idx[ok], left[ok])
        right = np.interp(idx, idx[ok], right[ok])
        left, right = _medfilt(left, 5), _medfilt(right, 5)
        out.append({"v": rows.tolist(), "g": left.tolist(), "d": right.tolist()})
    bottom = max(max(q["v"]) for q in out) + 1.0
    return {"pieux": out, "bas": bottom}


def egaliser(cfg, im, prof):
    """L'ombre peinte sur les côtés de chaque pieu retirée (le modèle, rond, a sa vraie lumière) :
    pour chaque position dans la largeur du pieu (0 à gauche, 1 à droite), la luminosité médiane
    des rangs du corps (sous la pointe, hors corde) rapportée à celle du milieu ; les couleurs
    divisées par ce rapport (borné). Réglage "egaliser" : {"sous": px sous le haut du pieu
    (la pointe gardée telle quelle), "force": 0..1}."""
    spec = cfg["pieux"].get("egaliser")
    if not spec:
        return im
    out = im.copy()
    lum = im[..., :3] @ np.array([0.299, 0.587, 0.114], np.float32)
    bins = 16
    for pr in prof["pieux"]:
        v, g, d = np.array(pr["v"]), np.array(pr["g"]), np.array(pr["d"])
        top = v.min() + spec.get("sous", 60)
        sel = v >= top
        ratios = [[] for _ in range(bins)]
        for y, a, b in zip(v[sel], g[sel], d[sel]):
            xs = np.arange(int(a), int(b))
            if len(xs) < bins:
                continue
            row = lum[int(y), xs]
            mid = np.median(row[len(xs) // 3: 2 * len(xs) // 3])
            if mid < 0.05:
                continue
            rel = ((xs - a) / max(b - a, 1) * bins).astype(int).clip(0, bins - 1)
            for k in range(bins):
                vals = row[rel == k]
                if len(vals):
                    ratios[k].append(np.median(vals) / mid)
        prof_k = np.array([np.median(r) if r else 1.0 for r in ratios])
        gain = np.clip(1.0 + spec.get("force", 1.0) * (1.0 / np.maximum(prof_k, 0.2) - 1.0), 0.8, 1.9)
        for y, a, b in zip(v[sel], g[sel], d[sel]):
            xs = np.arange(int(a), int(b))
            rel = ((xs - a) / max(b - a, 1) * bins).astype(int).clip(0, bins - 1)
            out[int(y), xs, :3] = np.clip(im[int(y), xs, :3] * gain[rel][:, None], 0.0, 1.0)
    return out


# ================================================================== vue
def axes(theta):
    s, c = math.sin(theta), math.cos(theta)
    return np.array([1.0, 0.0, 0.0]), np.array([0.0, s, c]), np.array([0.0, -c, s])


def calage(cfg, s, w, h, prof):
    vc = cfg["vues"].get("face", {})
    theta = math.radians(vc.get("theta") or 10.0)
    return {"theta": theta, "theta_deg": round(math.degrees(theta), 2), "lacet": 0.0, "s": s,
            "u0": w / 2.0, "v0": float(prof["bas"]), "w": w, "h": h}


def to_px(k, P):
    R, U, _ = axes(k["theta"])
    P = np.atleast_2d(np.asarray(P, float))
    return np.stack([k["u0"] + k["s"] * (P @ R), k["v0"] - k["s"] * (P @ U)], 1)


def height(k, v, depth):
    """z d'un point à la profondeur y = depth vu à la ligne v du dessin."""
    th = k["theta"]
    return ((k["v0"] - v) / k["s"] - depth * math.sin(th)) / math.cos(th)


def lift_plane_y(k, px, y):
    """Points du plan y = const vus aux px donnés."""
    px = np.atleast_2d(np.asarray(px, float))
    x = (px[:, 0] - k["u0"]) / k["s"]
    z = np.array([height(k, v, y) for v in px[:, 1]])
    return np.stack([x, np.full(len(x), y), z], 1)


# ================================================================== géométrie
class Mesh:
    """Sommets, faces, source de la peinture (src), coordonnées le long d'un tube (uvt, px)."""
    def __init__(self):
        self.v, self.src, self.uvt, self.faces, self.part = [], [], [], [], []

    def add(self, V, F, S, T, part):
        base = len(self.v)
        self.v += list(V)
        self.src += list(S)
        self.uvt += list(T)
        for f in F:
            self.faces.append([base + i for i in f])
            self.part.append(part)


def _noise(i, j, seed):
    return math.sin(12.9898 * i + 78.233 * j + seed * 37.7) * 43758.5453 % 1.0 - 0.5


def stake(k, prof, cfg, idx, fine):
    """Un pieu : anneaux le long du profil du dessin (sommets, faces, sources, axe)."""
    p = cfg["pieux"]
    s = k["s"]
    step = p.get("pas", 4) if fine else 12
    n = p.get("cotes", 10) if fine else 6
    bumps = p.get("bosses", 1.2) / s
    ratio = p.get("profondeur", 1.0)   # (rayon dans la profondeur / demi-largeur : un tronc rond)
    v = np.array(prof["v"], float)
    g, d = np.array(prof["g"]), np.array(prof["d"])
    r_max = float(np.max((d - g) / 2.0)) / s * ratio
    yc = r_max   # (le devant du pieu le plus gros à y = 0)
    order = np.argsort(-v)   # du bas vers le haut
    v, g, d = v[order], g[order], d[order]
    picks = list(range(0, len(v), step))
    if picks[-1] != len(v) - 1:
        picks.append(len(v) - 1)
    rings, V, S = [], [], []
    for a, i in enumerate(picks):
        half = (d[i] - g[i]) / 2.0 / s
        cx = ((g[i] + d[i]) / 2.0 - k["u0"]) / s
        z = max(0.0, height(k, v[i], yc))
        if i == picks[-1]:
            half = 0.0   # la pointe
        ring = []
        for j in range(n):
            ang = 2 * math.pi * (j + 0.5) / n
            bump = bumps * _noise(a, j, idx) * (1.0 if half > 0 else 0.0)
            rx, ry = half + bump, half * ratio + bump
            P = np.array([cx + rx * math.cos(ang), yc - ry * math.sin(ang), z])
            ring.append(len(V))
            V.append(P)
            S.append(np.array([P[0], min(P[1], 2 * yc - P[1]), P[2]]))   # le dos : peint par le devant
        rings.append(ring)
    # pied enfoncé un peu sous le sol
    base = []
    for j in range(n):
        P = V[rings[0][j]].copy()
        P[2] = -0.06
        base.append(len(V))
        V.append(P)
        S.append(S[rings[0][j]].copy())
    rings.insert(0, base)
    F = []
    for r0, r1 in zip(rings[:-1], rings[1:]):
        for j in range(n):
            jj = (j + 1) % n
            F.append([r0[j], r0[jj], r1[jj], r1[j]])
    axis = {"x": [((g[i] + d[i]) / 2.0 - k["u0"]) / s for i in range(len(v))],
            "z": [max(0.0, height(k, v[i], yc)) for i in range(len(v))],
            "r": [(d[i] - g[i]) / 2.0 / s for i in range(len(v))], "yc": yc}
    return np.array(V), F, np.array(S), axis


def tube(path, r, n, closed=False):
    """Tube de rayon r le long d'une polyligne 3D : sommets, faces, uvt (longueur, tour ; m)."""
    P = np.asarray(path, float)
    m = len(P)
    T = np.gradient(P, axis=0) if not closed else (np.roll(P, -1, 0) - np.roll(P, 1, 0))
    T /= np.maximum(np.linalg.norm(T, axis=1, keepdims=True), 1e-9)
    ref = np.array([0.0, 0.0, 1.0])
    V, UV = [], []
    seg = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]
    for i in range(m):
        t = T[i]
        a = ref if abs(t @ ref) < 0.9 else np.array([0.0, 1.0, 0.0])
        e1 = np.cross(t, a)
        e1 /= np.linalg.norm(e1)
        e2 = np.cross(t, e1)
        for j in range(n):
            ang = 2 * math.pi * j / n
            V.append(P[i] + r * (math.cos(ang) * e1 + math.sin(ang) * e2))
            UV.append([seg[i], r * ang, 0.0])
    F = []
    last = m if closed else m - 1
    for i in range(last):
        i1 = (i + 1) % m
        for j in range(n):
            jj = (j + 1) % n
            F.append([i * n + j, i * n + jj, i1 * n + jj, i1 * n + j])
    if not closed:   # bouts fermés
        V.append(P[0]); UV.append([0.0, 0.0, 0.0])
        V.append(P[-1]); UV.append([seg[-1], 0.0, 0.0])
        c0, c1 = len(V) - 2, len(V) - 1
        for j in range(n):
            jj = (j + 1) % n
            F.append([c0, jj, j])
            F.append([c1, (m - 1) * n + j, (m - 1) * n + jj])
    return np.array(V), F, np.array(UV)


def rope(k, cfg, axes_, fine):
    """La corde : deux tours autour de chaque pieu, les brins, le bout qui pend."""
    p = cfg["pieux"]
    c = p.get("corde", {})
    s = k["s"]
    r = p.get("r_corde", 5.0) / s
    n = 6 if fine else 4
    out = []
    ratio = p.get("profondeur", 1.0)
    for w in c.get("tours", []):
        ax = axes_[w["pieu"]]
        zs, xs, rs = np.array(ax["z"]), np.array(ax["x"]), np.array(ax["r"])
        i = int(np.argmin(np.abs(zs - height(k, w["px"][1], 0.0))))
        # hauteur du tour : le milieu de son devant (à la profondeur du devant du pieu), vu sur le dessin
        zw = height(k, w["px"][1], ax["yc"] - rs[i] * ratio - r)
        i = int(np.argmin(np.abs(zs - zw)))
        cx, R0 = float(xs[i]), float(rs[i])
        m = 16 if fine else 8
        gap = w.get("ecart", 2.0 * p.get("r_corde", 5.0)) / s / math.cos(k["theta"])   # (px du dessin entre deux tours)
        for turn in range(w.get("tours", 2)):
            z = zw + turn * gap * (1 if w.get("vers", "haut") == "haut" else -1)
            loop = [np.array([cx + (R0 + r * 0.8) * math.cos(2 * math.pi * q / m),
                              ax["yc"] - (R0 * ratio + r * 0.8) * math.sin(2 * math.pi * q / m), z]) for q in range(m)]
            out.append(tube(loop, r, n, closed=True))
    yc = float(np.mean([a["yc"] for a in axes_]))
    for line in c.get("brins", []) + ([c["bout"]] if c.get("bout") else []):
        P = lift_plane_y(k, line, yc)
        out.append(tube(P, r, n))
    return out


def build(cfg, k, prof, fine):
    """La palissade : Mesh et noms des parties."""
    mesh = Mesh()
    names = []

    def pid(name):
        if name not in names:
            names.append(name)
        return names.index(name)

    axes_ = []
    for i, pr in enumerate(prof["pieux"]):
        V, F, S, ax = stake(k, pr, cfg, i, fine)
        mesh.add(V, F, S, np.zeros((len(V), 3)), pid("pieu"))
        axes_.append(ax)
    for V, F, UV in rope(k, cfg, axes_, fine):
        mesh.add(V, F, V, UV * k["s"], pid("corde"))
    return mesh, names
