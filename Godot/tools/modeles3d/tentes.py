"""Tentes en vraie 3D (maisons.py, sortes à clé « tente » dans maisons.json) : le dessin du jeu,
en 3/4, est la seule vue. Pas de vue de face ni de côté inventée : le modèle est reconstruit sur
les lignes du dessin, vu sous son angle (calage avec lacet), puis tourné à l'export pour que la
caméra du jeu le voie comme le dessin.

Calage : trois coins du pied de la tente sur le dessin (« sol » : avant gauche, avant droit,
arrière droit) forment un rectangle au sol ; l'élévation (theta) et le lacet (la vue tournée
vers la droite du modèle) en sortent, l'échelle est celle du jeu. Repère du modèle : X à droite
de la tente, Y de la porte vers le fond, Z en haut ; origine au milieu du pied de la porte.

Lignes (« courbes », px du dessin, recalées sur le dessin : « silhouette » sur le bord du
dessin, « trait » sur le trait sombre le plus proche) relevées chacune sur son plan : le faîtage
sur le plan de symétrie, les rives et le bas de la porte sur le plan du pignon (y = 0 ou y = L),
l'ourlet du pan droit sur le plan vertical de ses coins, le bas du mur sur le sol. Le maillage
suit donc exactement le dessin vu de son angle : faîtage affaissé, ourlets festonnés, bords
rongés. Pans et murs : carreaux de Coons tendus entre leurs quatre lignes, creusés au milieu
(« creux » : la toile s'affaisse). Côté caché (pan et mur gauches, pignon du fond) : les lignes
du côté droit en miroir, raccordées aux coins que le dessin montre ; peints par le morceau du
dessin qui leur correspond (attribut « src » : pan gauche = pan droit au même endroit, pignon du
fond = le rabat gauche de la porte, en miroir des deux côtés). Mâts, cordes et piquets : des
volumes à part, peints de leur propre motif.
"""
import json
import math
import numpy as np

X = np.array([1.0, 0.0, 0.0])
Y = np.array([0.0, 1.0, 0.0])
Z = np.array([0.0, 0.0, 1.0])
SNAP_R = {"silhouette": 6, "trait": 5}   # px : recherche du bord ou du trait autour du tracé
ROPE_OPEN = 4                             # px : ouverture qui retire cordes et piquets de la silhouette


# ================================================================== vue (sans Blender)
def axes(k):
    """(droite, haut, vers la caméra) de la vue calée k (theta, lacet en radians)."""
    th, ps = k["theta"], k.get("lacet", 0.0)
    R = np.array([math.cos(ps), math.sin(ps), 0.0])
    U = np.array([-math.sin(ps) * math.sin(th), math.cos(ps) * math.sin(th), math.cos(th)])
    D = np.array([math.sin(ps) * math.cos(th), -math.cos(ps) * math.cos(th), math.sin(th)])
    return R, U, D


def to_px(k, P):
    R, U, _ = axes(k)
    P = np.atleast_2d(np.asarray(P, float))
    return np.stack([k["u0"] + k["s"] * (P @ R), k["v0"] - k["s"] * (P @ U)], 1)


def lift(k, px, n, c):
    """Points (n, 3) du plan n·P = c vus aux px donnés (rayons orthographiques de la vue)."""
    R, U, D = axes(k)
    px = np.atleast_2d(np.asarray(px, float))
    P0 = ((px[:, 0] - k["u0"]) / k["s"])[:, None] * R + ((k["v0"] - px[:, 1]) / k["s"])[:, None] * U
    t = (c - P0 @ n) / (n @ D)
    return P0 + t[:, None] * D


def lift_vertical(k, px, x, y):
    """Point de la verticale (x, y) vu à la hauteur (ligne) du px donné."""
    _, U, _ = axes(k)
    z = ((k["v0"] - px[1]) / k["s"] - x * U[0] - y * U[1]) / U[2]
    return np.array([x, y, z])


def calage(cfg, s, w, h):
    """Calage de la vue du dessin : trois coins du pied (px) -> élévation, lacet, origine."""
    t = cfg["tente"]
    FL, FR, BR = (np.array(t["sol"][n], float) for n in ("av_g", "av_d", "ar_d"))
    e1, e2 = FL - FR, BR - FR
    vc = cfg["vues"].get("face", {})
    if vc.get("theta") is not None:
        theta = math.radians(vc["theta"])
    else:   # les deux côtés du pied à angle droit
        sin2 = -(e1[1] * e2[1]) / (e1[0] * e2[0])
        theta = math.asin(math.sqrt(float(np.clip(sin2, 0.003, 0.6))))
    d = FR - FL
    psi = math.radians(vc["lacet"]) if vc.get("lacet") is not None else math.atan2(d[1] / math.sin(theta), d[0])
    u0, v0 = (FL + FR) / 2.0
    return {"theta": theta, "theta_deg": round(math.degrees(theta), 2), "lacet": psi,
            "lacet_deg": round(math.degrees(psi), 2), "s": s, "u0": float(u0), "v0": float(v0), "w": w, "h": h}


# ================================================================== le dessin (PIL, scipy)
def disk(r):
    yy, xx = np.mgrid[-r:r + 1, -r:r + 1]
    return xx * xx + yy * yy <= r * r


def poly_mask(shape, poly):
    from PIL import Image, ImageDraw
    m = Image.new("L", (shape[1], shape[0]), 0)
    ImageDraw.Draw(m).polygon([tuple(p) for p in poly], fill=255)
    return np.asarray(m) > 127


def line_mask(shape, segs, width):
    from PIL import Image, ImageDraw
    m = Image.new("L", (shape[1], shape[0]), 0)
    d = ImageDraw.Draw(m)
    for a, b in segs:
        d.line([tuple(a), tuple(b)], fill=255, width=int(width))
    return np.asarray(m) > 127


def retouches(cfg, im, smooth_fill):
    """Retouches de la vue (RGBA 0..1, 5e canal « effacé » compris) avant les textures :
    « remplir » (polygone : les px transparents prennent la couleur du px donné : l'intérieur
    sombre de la porte jusqu'au sol) ; cordes et piquets qui passent devant la toile effacés (la
    toile d'à côté, en douceur) : ils sont des volumes à part."""
    t = cfg["tente"]
    out = im.copy()
    for spec in cfg["vues"]["face"].get("remplir", []):
        m = poly_mask(im.shape, spec["poly"]) & (out[..., 3] < 0.5)
        x, y = spec["px"]
        out[m, :3] = im[y, x, :3]
        out[m, 3] = 1.0
    lum = out[..., :3] @ np.array([0.299, 0.587, 0.114], np.float32)
    segs = []
    for p in t.get("piquets", []):
        if p.get("corde_px"):
            P = snap_rope(lum, out[..., 3] > 0.5, p["corde_px"])
            segs += list(zip(P[:-1].tolist(), P[1:].tolist()))
    segs += [(p["haut"], p["bas"]) for p in t.get("piquets", [])]
    segs += [tuple(m["px"]) for m in t.get("mats", []) if m.get("effacer")]
    if segs:
        from scipy import ndimage
        body = ndimage.binary_opening(out[..., 3] > 0.5, structure=disk(ROPE_OPEN))
        body = ndimage.binary_erosion(body, iterations=2)
        m = line_mask(im.shape, segs, cfg["vues"]["face"].get("largeur_cordes", 9)) & body
        lab, n = ndimage.label(m)
        for i in range(1, n + 1):   # chaque morceau à part : la toile qui l'entoure (le contour sombre
            part = lab == i         # de la corde, au bord du masque, ne compte pas)
            rgb = smooth_fill(out[..., :4], [], tol=0.3, mask=part)
            out[..., :3] = np.where(part[..., None], rgb[..., :3], out[..., :3])
    return out


def snap_rope(lum, alpha, seg, reach=8, half=3):
    """Corde tracée [a, b] (px) recalée sur son âme : à chaque pas, le px de la perpendiculaire
    (à moins de `reach` px) le plus clair que les traits sombres qui la bordent (à `half` px de
    part et d'autre) : une corde claire cernée, sur toile claire ou sombre ; polyligne lissée."""
    from scipy import ndimage
    P = resample2d(seg, 2.0)
    d = P[-1] - P[0]
    n = np.array([-d[1], d[0]]) / max(np.linalg.norm(d), 1e-9)
    ks = np.arange(-reach, reach + 1, dtype=float)
    offs = np.full(len(P), np.nan)
    L = ndimage.gaussian_filter(np.where(alpha, lum, 0.0), 0.7)
    A = alpha.astype(np.float32)
    for i, p in enumerate(P):
        core = _sample(L, p[None] + ks[:, None] * n[None])
        side = 0.5 * (_sample(L, p[None] + (ks - half)[:, None] * n[None]) + _sample(L, p[None] + (ks + half)[:, None] * n[None]))
        v = (core - side) * _sample(A, p[None] + ks[:, None] * n[None])
        j = int(np.argmax(v))
        if v[j] > 0.08:
            offs[i] = ks[j]
    ok = np.isfinite(offs)
    if ok.sum() < 3:
        return P
    idx = np.arange(len(P))
    offs = ndimage.gaussian_filter1d(ndimage.median_filter(np.interp(idx, idx[ok], offs[ok]), 9, mode="nearest"), 2.0)
    return P + offs[:, None] * n[None]


def resample2d(P, step):
    P = np.asarray(P, float)
    d = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]
    n = max(2, int(math.ceil(d[-1] / step)) + 1)
    s = np.linspace(0.0, d[-1], n)
    return np.stack([np.interp(s, d, P[:, 0]), np.interp(s, d, P[:, 1])], 1)


def _sample(img, q):
    h, w = img.shape
    x = np.clip(np.round(q[:, 0]).astype(int), 0, w - 1)
    y = np.clip(np.round(q[:, 1]).astype(int), 0, h - 1)
    return img[y, x]


def snap(cfg, im):
    """Les tracés des courbes recalés sur le dessin (px) : « silhouette » sur le bord de la toile
    (cordes et piquets retirés), « trait » sur le trait sombre ; « libre » tel quel. Les bouts
    restent où ils sont tracés (ce sont les coins)."""
    from scipy import ndimage
    alpha = im[..., 3] > 0.5
    body = ndimage.binary_opening(alpha, structure=disk(ROPE_OPEN)).astype(np.float32)
    lum = np.where(alpha, im[..., :3] @ np.array([0.299, 0.587, 0.114], np.float32), 1.0)
    lum = ndimage.gaussian_filter(lum, 0.8)
    out = {}
    for name, c in cfg["tente"]["courbes"].items():
        mode = c.get("mode", "trait")
        P = resample2d(c["px"], 2.0)
        if mode not in SNAP_R or len(P) < 4:
            out[name] = P.tolist()
            continue
        tan = np.gradient(P, axis=0)
        tan /= np.maximum(np.linalg.norm(tan, axis=1, keepdims=True), 1e-9)
        nrm = np.stack([-tan[:, 1], tan[:, 0]], 1)
        R = SNAP_R[mode]
        ks = np.arange(-R, R + 1, dtype=float)
        offs = np.full(len(P), np.nan)
        for i, (p, n) in enumerate(zip(P, nrm)):
            q = p[None] + ks[:, None] * n[None]
            if mode == "silhouette":
                v = _sample(body, q)
                ch = np.nonzero(np.diff(v) != 0)[0]
                if len(ch):
                    mid = ks[ch] + 0.5
                    offs[i] = mid[np.argmin(np.abs(mid))]
            else:
                v = _sample(lum, q) + 0.004 * np.abs(ks)
                j = int(np.argmin(v))
                if 0 < j < len(ks) - 1 and v[j] < 0.5:
                    offs[i] = ks[j]
        ok = np.isfinite(offs)
        if ok.sum() < 2:
            out[name] = P.tolist()
            continue
        idx = np.arange(len(P))
        offs = np.interp(idx, idx[ok], offs[ok])
        offs = ndimage.gaussian_filter1d(ndimage.median_filter(offs, 7, mode="nearest"), 1.2, mode="nearest")
        taper = np.clip(np.minimum(idx, idx[::-1]) / 4.0, 0.0, 1.0)   # (les bouts : les coins tracés)
        out[name] = (P + (offs * taper)[:, None] * nrm).tolist()
    return out


# ================================================================== géométrie (numpy)
def resample(P, n):
    P = np.asarray(P, float)
    d = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]
    if d[-1] < 1e-9:
        return np.repeat(P[:1], n, 0)
    s = np.linspace(0.0, d[-1], n)
    return np.stack([np.interp(s, d, P[:, i]) for i in range(P.shape[1])], 1)


def fit_ends(P, A=None, B=None):
    """Polyligne aux bouts ramenés sur A et B (None : inchangé), l'écart réparti sur sa longueur."""
    P = np.asarray(P, float).copy()
    d = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]
    f = (d / max(d[-1], 1e-9))[:, None]
    if A is not None:
        P += (1.0 - f) * (np.asarray(A, float) - P[0])
    if B is not None:
        P += f * (np.asarray(B, float) - P[-1])
    return P


def mirror_x(P):
    P = np.asarray(P, float).copy()
    P[..., 0] = -P[..., 0]
    return P


def coons(B, T, F, K):
    """Carreau de Coons (nt, nw, 3) : B(t) en bas, T(t) en haut, F(w) devant, K(w) au fond."""
    t = np.linspace(0.0, 1.0, len(B))[:, None, None]
    w = np.linspace(0.0, 1.0, len(F))[None, :, None]
    return ((1 - w) * B[:, None] + w * T[:, None] + (1 - t) * F[None] + t * K[None]
            - ((1 - t) * (1 - w) * B[0] + t * (1 - w) * B[-1] + (1 - t) * w * T[0] + t * w * T[-1]))


def grid_normals(G):
    dt = np.gradient(G, axis=0)
    dw = np.gradient(G, axis=1)
    n = np.cross(dt, dw)
    return n / np.maximum(np.linalg.norm(n, axis=2, keepdims=True), 1e-9)


def sag(G, amount, inward):
    """La toile creusée au milieu (nulle sur les bords) de `amount` m, vers l'intérieur."""
    if amount == 0:
        return G
    nt, nw = G.shape[:2]
    n = grid_normals(G)
    sign = 1.0 if (n.reshape(-1, 3) @ inward).mean() > 0 else -1.0   # vers l'intérieur
    t = np.linspace(0.0, 1.0, nt)[:, None]
    w = np.linspace(0.0, 1.0, nw)[None, :]
    f = (np.sin(math.pi * t) ** 0.7) * np.sin(math.pi * w)
    return G + sign * amount * f[..., None] * n


def bilerp(G, t, w):
    """Point du carreau G aux paramètres (t, w) dans [0, 1] (interpolation bilinéaire)."""
    nt, nw = G.shape[:2]
    x, y = t * (nt - 1), w * (nw - 1)
    i, j = min(int(x), nt - 2), min(int(y), nw - 2)
    a, b = x - i, y - j
    return ((1 - a) * (1 - b) * G[i, j] + a * (1 - b) * G[i + 1, j] + (1 - a) * b * G[i, j + 1] + a * b * G[i + 1, j + 1])


def nearest_param(col, x):
    """Indice du point de la colonne (hem -> faîte) dont le x est le plus proche de x."""
    return int(np.argmin(np.abs(col[:, 0] - x)))


class Mesh:
    """Sommets, faces (indices), sommets « source » de la peinture, partie de chaque face."""
    def __init__(self):
        self.v, self.src, self.faces, self.part = [], [], [], []

    def add_grid(self, G, S, part, flip=False):
        nt, nw = G.shape[:2]
        base = len(self.v)
        self.v += list(G.reshape(-1, 3))
        self.src += list(S.reshape(-1, 3))
        for i in range(nt - 1):
            for j in range(nw - 1):
                q = [base + i * nw + j, base + (i + 1) * nw + j, base + (i + 1) * nw + j + 1, base + i * nw + j + 1]
                self.faces.append(q[::-1] if flip else q)
                self.part.append(part)

    def add_faces(self, V, F, S, part):
        base = len(self.v)
        self.v += list(V)
        self.src += list(S)
        for f in F:
            self.faces.append([base + i for i in f])
            self.part.append(part)


def outward_flip(G, center):
    """Vrai si les faces du carreau regardent vers l'intérieur (il faut les retourner)."""
    n = grid_normals(G).reshape(-1, 3)
    c = G.reshape(-1, 3)
    return float(((c - center) * n).sum(1).mean()) < 0


def polygon_faces(P2):
    """Triangles (indices) d'un polygone plan simple (n, 2), par oreilles."""
    P2 = np.asarray(P2, float)
    n = len(P2)
    area = 0.5 * np.sum(P2[:, 0] * np.roll(P2[:, 1], -1) - np.roll(P2[:, 0], -1) * P2[:, 1])
    idx = list(range(n)) if area > 0 else list(range(n))[::-1]
    tris = []

    def inside(p, a, b, c):
        d1 = (p[0] - b[0]) * (a[1] - b[1]) - (a[0] - b[0]) * (p[1] - b[1])
        d2 = (p[0] - c[0]) * (b[1] - c[1]) - (b[0] - c[0]) * (p[1] - c[1])
        d3 = (p[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (p[1] - a[1])
        return not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0))

    guard = 0
    while len(idx) > 3 and guard < 20000:
        guard += 1
        m = len(idx)
        best = None
        for k in range(m):
            i0, i1, i2 = idx[k - 1], idx[k], idx[(k + 1) % m]
            a, b, c = P2[i0], P2[i1], P2[i2]
            cross = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
            if cross <= 1e-12:
                continue
            if any(inside(P2[j], a, b, c) for j in idx if j not in (i0, i1, i2)):
                continue
            # oreille la plus « ronde » d'abord (moins de triangles effilés)
            e = [np.linalg.norm(b - a), np.linalg.norm(c - b), np.linalg.norm(a - c)]
            q = cross / max(e[0] * e[1] * e[2], 1e-12)
            if best is None or q > best[0]:
                best = (q, k)
        if best is None:   # (polygone abîmé : on coupe au plus simple)
            best = (0, 1)
        k = best[1]
        tris.append((idx[k - 1], idx[k], idx[(k + 1) % len(idx)]))
        idx.pop(k)
    if len(idx) == 3:
        tris.append(tuple(idx))
    return tris


def dedupe(P, eps=1e-4):
    out = [P[0]]
    for p in P[1:]:
        if np.linalg.norm(p - out[-1]) > eps:
            out.append(p)
    if len(out) > 2 and np.linalg.norm(out[0] - out[-1]) <= eps:
        out.pop()
    return np.array(out)


def refine_tris(V, F, max_len):
    """Triangles coupés en 4 tant qu'une arête dépasse max_len (grilles fines : ombres, normales)."""
    V = [np.asarray(v, float) for v in V]
    F = [tuple(f) for f in F]
    for _ in range(2):
        if all(max(np.linalg.norm(V[a] - V[b]) for a, b in ((f[0], f[1]), (f[1], f[2]), (f[2], f[0]))) <= max_len
               for f in F):
            break
        mids = {}

        def mid(a, b):
            key = (min(a, b), max(a, b))
            if key not in mids:
                mids[key] = len(V)
                V.append((V[a] + V[b]) / 2.0)
            return mids[key]
        out = []
        for a, b, c in F:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            out += [(a, ab, ca), (ab, b, bc), (ca, bc, c), (ab, bc, ca)]
        F = out
    return np.array(V), F


def cylinder(A, B, r, n, r_top=None):
    """Cylindre (sommets, faces) de A à B, rayon r (r_top au bout B), bouchons compris."""
    A, B = np.asarray(A, float), np.asarray(B, float)
    ax = B - A
    L = np.linalg.norm(ax)
    ax = ax / max(L, 1e-9)
    ref = X if abs(ax @ X) < 0.9 else Y
    e1 = np.cross(ax, ref)
    e1 /= np.linalg.norm(e1)
    e2 = np.cross(ax, e1)
    r_top = r if r_top is None else r_top
    V = []
    for c, rr in ((A, r), (B, r_top)):
        for i in range(n):
            a = 2 * math.pi * (i + 0.5) / n
            V.append(c + rr * (math.cos(a) * e1 + math.sin(a) * e2))
    V.append(A)
    V.append(B)
    F = []
    for i in range(n):
        j = (i + 1) % n
        F.append([i, j, n + j, n + i])
        F.append([2 * n, j, i])
        F.append([2 * n + 1, n + i, n + j])
    return np.array(V), F


# ================================================================== la tente
def curve3d(k, curves, name, plane):
    n, c = plane
    return lift(k, curves[name], n, c)


def skeleton(cfg, k, curves, fine):
    """Lignes 3D de la tente (repère du modèle) relevées sur le dessin, et ses points clés."""
    t = cfg["tente"]
    nt = t.get("n_long", 26) if fine else 10
    nw = t.get("n_pente", 16) if fine else 6
    nww = t.get("n_mur", 5) if fine else 3
    FL, FR, BR = (lift(k, t["sol"][n], Z, 0.0)[0] for n in ("av_g", "av_d", "ar_d"))
    L = float(BR[1])
    BL = FL + (BR - FR)
    A_f = lift_vertical(k, curves["faite"][0], 0.0, 0.0)
    A_b = lift_vertical(k, curves["faite"][-1], 0.0, L)
    faite = fit_ends(curve3d(k, curves, "faite", (X, 0.0)), A_f, A_b)
    faite[:, 0] = 0.0
    rive_av_d = fit_ends(curve3d(k, curves, "rive_av_d", (Y, 0.0)), A_f, None)
    rive_av_g = fit_ends(curve3d(k, curves, "rive_av_g", (Y, 0.0)), A_f, None)
    rive_ar_d = fit_ends(curve3d(k, curves, "rive_ar_d", (Y, L)), A_b, None)
    E_fr, E_fl, E_br = rive_av_d[-1], rive_av_g[-1], rive_ar_d[-1]
    E_bl = mirror_x(E_br)
    rive_ar_g = mirror_x(rive_ar_d)
    d = E_br - E_fr
    nh = np.array([d[1], -d[0], 0.0]) / max(math.hypot(d[0], d[1]), 1e-9)
    ourlet_d = fit_ends(curve3d(k, curves, "ourlet_d", (nh, float(nh @ E_fr))), E_fr, E_br)
    ourlet_g = fit_ends(mirror_x(ourlet_d), E_fl, E_bl)
    mur_bas_d = fit_ends(curve3d(k, curves, "mur_bas_d", (Z, 0.0)), FR, BR)
    mur_bas_d[:, 2] = 0.0
    mur_bas_g = fit_ends(mirror_x(mur_bas_d), FL, BL)
    mur_bas_g[:, 2] = 0.0
    # pans : carreaux (t : de l'avant au fond, w : de l'ourlet au faîtage)
    center = np.array([0.0, L / 2.0, 0.35 * A_f[2]])
    creux = t.get("creux", 8.0) / k["s"]   # (px du dessin -> m)

    def panel(hem, fe, be):
        G = coons(resample(hem, nt), resample(faite, nt), resample(fe[::-1], nw), resample(be[::-1], nw))
        return sag(G, creux, center - G.reshape(-1, 3).mean(0))

    Pd = panel(ourlet_d, rive_av_d, rive_ar_d)
    Pg = panel(ourlet_g, rive_av_g, rive_ar_g)
    # murs : du sol au contact du pan, au droit du pied
    jf_d, jb_d = nearest_param(Pd[0], FR[0]), nearest_param(Pd[-1], BR[0])
    jf_g, jb_g = nearest_param(Pg[0], FL[0]), nearest_param(Pg[-1], BL[0])
    C_fr, C_br, C_fl, C_bl = Pd[0, jf_d], Pd[-1, jb_d], Pg[0, jf_g], Pg[-1, jb_g]
    bord_av_d = fit_ends(curve3d(k, curves, "bord_av_d", (Y, 0.0)), FR, C_fr)
    mur_ar_d = fit_ends(curve3d(k, curves, "mur_ar_d", (Y, L)), BR, C_br)
    mur_ar_g = fit_ends(mirror_x(mur_ar_d), BL, C_bl)
    front_g = np.stack([np.linspace(FL[i], C_fl[i], 6) for i in range(3)], 1)

    def contact(P, jf, jb, n):
        nwp = P.shape[1] - 1
        return np.array([bilerp(P, s, (jf + (jb - jf) * s) / nwp) for s in np.linspace(0.0, 1.0, n)])

    Wd = coons(resample(mur_bas_d, nt), contact(Pd, jf_d, jb_d, nt), resample(bord_av_d, nww), resample(mur_ar_d, nww))
    Wg = coons(resample(mur_bas_g, nt), contact(Pg, jf_g, jb_g, nt), resample(front_g, nww), resample(mur_ar_g, nww))
    # bord gauche du rabat et bas de la porte (plan du pignon)
    bord_av_g = fit_ends(curve3d(k, curves, "bord_av_g", (Y, 0.0)), E_fl, FL)
    bas_av = curve3d(k, curves, "bas_av", (Y, 0.0))
    low = bas_av[:, 2] < 0.0   # (sous le pied : le bas du rabat s'évase sur le sol, devant le pignon)
    if low.any():
        bas_av[low] = lift(k, np.array(curves["bas_av"], float)[low], Z, 0.0)
    bas_av = fit_ends(bas_av, FL, FR)
    bas_av[:, 2] = np.maximum(bas_av[:, 2], 0.0)
    bas_av = resample(bas_av, 40)
    pts = {"FL": FL, "FR": FR, "BR": BR, "BL": BL, "A_f": A_f, "A_b": A_b, "E_fr": E_fr, "E_fl": E_fl,
           "E_br": E_br, "E_bl": E_bl, "C_fr": C_fr, "C_br": C_br, "C_fl": C_fl, "C_bl": C_bl}
    lines = {"faite": faite, "rive_av_d": rive_av_d, "rive_av_g": rive_av_g, "rive_ar_d": rive_ar_d,
             "rive_ar_g": rive_ar_g, "ourlet_d": ourlet_d, "ourlet_g": ourlet_g, "mur_bas_d": mur_bas_d,
             "mur_bas_g": mur_bas_g, "bord_av_d": bord_av_d, "mur_ar_d": mur_ar_d, "bord_av_g": bord_av_g,
             "bas_av": bas_av}
    door_i = None
    if "porte" in curves:   # l'entrée, une vraie ouverture : ses bords dans le plan du pignon, ses pieds sur le bas des rabats
        dp = np.array(curves["porte"], float)
        q = to_px(k, bas_av)
        door_i = (int(np.argmin(np.linalg.norm(q - dp[0], axis=1))), int(np.argmin(np.linalg.norm(q - dp[-1], axis=1))))
        door = fit_ends(lift(k, dp, Y, 0.0), bas_av[door_i[0]], bas_av[door_i[1]])
        door[:, 2] = np.maximum(door[:, 2], 0.0)
        lines["porte"] = door
    return {"L": L, "pts": pts, "lines": lines, "Pd": Pd, "Pg": Pg, "Wd": Wd, "Wg": Wg,
            "j": {"fd": jf_d, "bd": jb_d, "fg": jf_g, "bg": jb_g}, "porte_i": door_i}


def gables(sk, cfg):
    """Pignons : devant (porte, plan y = 0) et fond (plan y = L, en deux moitiés), polygones 3D."""
    P, Pd, Pg, Wd, Wg, j = sk["pts"], sk["Pd"], sk["Pg"], sk["Wd"], sk["Wg"], sk["j"]
    ln = sk["lines"]
    ba = ln["bas_av"]
    if sk.get("porte_i"):   # FL -> pied gauche de l'entrée, son tour (encoche), son pied droit -> FR
        ia, ib = sk["porte_i"]
        bottom = [ba[1:ia + 1], ln["porte"][1:-1], ba[ib:]]
    else:
        bottom = [ba[1:]]
    front = np.concatenate([
        Pg[0, ::-1],                         # A_f -> E_fl (rive gauche, bord du pan gauche)
        resample(ln["bord_av_g"], 10)[1:],   # E_fl -> FL
        *bottom,                             # FL -> FR (bas des rabats, entrée)
        Wd[0, 1:],                           # FR -> C_fr (bord avant du mur droit)
        Pd[0, j["fd"] + 1:-1],               # C_fr -> (A_f) (rive droite)
    ])
    L = sk["L"]
    M_b = np.array([0.0, L, 0.0])
    half = np.concatenate([
        Pd[-1, ::-1][: Pd.shape[1] - j["bd"]],          # A_b -> C_br
        Wd[-1, ::-1][1:],                               # C_br -> BR
        np.linspace(P["BR"], M_b, 6)[1:],               # BR -> milieu du pied
        np.linspace(M_b, P["A_b"], 8)[1:-1],            # -> A_b (axe)
    ])
    return dedupe(front), dedupe(half)


def back_source(cfg, k, sk, V):
    """Peinture du pignon du fond : le rabat gauche de la porte, en miroir des deux côtés
    (x' = x0 - |x| (demi-largeur de devant + x0) / demi-largeur du fond ; hauteur à l'échelle)."""
    P = sk["pts"]
    x0 = cfg["tente"].get("dos_x0", -23.0) / k["s"]
    hwf = abs(P["E_fl"][0])
    hwb = max(abs(P["C_br"][0]), abs(P["BR"][0]))
    kz = P["A_f"][2] / max(P["A_b"][2], 1e-6)
    S = np.array(V, float).copy()
    S[:, 0] = x0 - np.abs(S[:, 0]) * (hwf + x0) / hwb
    S[:, 1] = 0.0
    S[:, 2] = S[:, 2] * kz
    return S


SWAP_Y = {"A_f": "A_b", "A_b": "A_f", "E_fr": "E_br", "E_br": "E_fr", "E_fl": "E_bl", "E_bl": "E_fl"}
SWAP_X = {"E_fr": "E_fl", "E_fl": "E_fr", "E_br": "E_bl", "E_bl": "E_br"}
OTHER_SIDE = {"ourlet_d": "ourlet_g", "ourlet_g": "ourlet_d", "rive_ar_d": "rive_ar_g", "rive_ar_g": "rive_ar_d"}


def sym_point(P, sym, L):
    """Point du côté caché : "x" (gauche <-> droite), "y" (avant <-> fond), "xy" (les deux)."""
    P = np.asarray(P, float).copy()
    if sym in ("x", "xy"):
        P[0] = -P[0]
    if sym in ("y", "xy"):
        P[1] = L - P[1]
    return P


def anchor_point(k, sk, spec, sym=None):
    """Point d'attache d'une corde : un point clé nommé ("A_f", "E_fr"…), ou le point d'une ligne
    le plus proche d'un px du dessin ({"ligne": nom, "px": [x, y]}) ; sur le côté caché (sym),
    le point correspondant (même point clé de l'autre côté, même rang sur la ligne d'en face)."""
    if isinstance(spec, str):
        name = spec
        if sym in ("y", "xy"):
            name = SWAP_Y.get(name, name)
        if sym in ("x", "xy"):
            name = SWAP_X.get(name, name)
        return np.array(sk["pts"][name], float)
    line = sk["lines"][spec["ligne"]]
    i = int(np.argmin(np.linalg.norm(to_px(k, line) - np.array(spec["px"], float), axis=1)))
    if sym in ("x", "xy") and spec["ligne"] in OTHER_SIDE:
        other = sk["lines"][OTHER_SIDE[spec["ligne"]]]
        P = other[min(i, len(other) - 1)].copy()
        return sym_point(P, "y", sk["L"]) if sym == "xy" else P
    return sym_point(line[i], sym, sk["L"]) if sym else line[i].copy()


def volumes(cfg, k, sk):
    """Mâts, piquets et cordes : [(nom de partie, sommets, faces)]."""
    t = cfg["tente"]
    L = sk["L"]
    _, _, D = axes(k)
    out = []
    px = 1.0 / k["s"]   # (rayons et longueurs en px du dessin : ils suivent l'échelle du jeu)
    r_peg, r_rope, r_pole = t.get("r_piquet", 6.5) * px, t.get("r_corde", 2.3) * px, t.get("r_mat", 6.7) * px
    planes = {"x0": (X, 0.0), "y0": (Y, 0.0), "yL": (Y, L), "sol": (Z, 0.0)}
    for m in t.get("mats", []):
        n, c = planes[m.get("plan", "x0")]
        a, b = lift(k, m["px"], n, c)
        if m.get("sol_bas"):   # (un mât planté : prolongé jusqu'un peu sous le sol)
            down = (a - b) / max(np.linalg.norm(a - b), 1e-9)
            if down[2] < -1e-3:
                a = a + down * max(0.0, (-10.0 * px - a[2]) / down[2])
        for sym in [None] + m.get("sym", []):
            pa, pb = (a, b) if sym is None else (sym_point(a, sym, L), sym_point(b, sym, L))
            V, F = cylinder(pa, pb, m.get("r", r_pole / px) * px, 8, m["r_haut"] * px if m.get("r_haut") else None)
            out.append(("mat", V, F))
    dh = np.array([D[0], D[1], 0.0])
    dh /= max(np.linalg.norm(dh), 1e-9)
    for p in t.get("piquets", []):
        base = lift(k, p["bas"], Z, 0.0)[0]
        top = lift(k, p["haut"], dh, float(dh @ base))[0]
        axis = (top - base) / max(np.linalg.norm(top - base), 1e-9)
        for sym in [None] + p.get("sym", []):
            b, tp = (base, top) if sym is None else (sym_point(base, sym, L), sym_point(top, sym, L))
            ax = axis if sym is None else (tp - b) / max(np.linalg.norm(tp - b), 1e-9)
            V, F = cylinder(b - ax * 10.0 * px, tp, r_peg, 8, r_peg * 0.85)
            out.append(("piquet", V, F))
            if p.get("corde") is not None:
                a = anchor_point(k, sk, p["corde"], sym)
                end = b + p.get("noeud", 0.72) * (tp - b)
                V, F = cylinder(a, end, r_rope, 5)
                out.append(("corde", V, F))
    return out


def build(cfg, k, curves, fine):
    """La tente : Mesh (sommets, faces, sources de peinture, parties) et ses lignes 3D."""
    t = cfg["tente"]
    sk = skeleton(cfg, k, curves, fine)
    mesh = Mesh()
    names = []

    def pid(name):
        if name not in names:
            names.append(name)
        return names.index(name)

    L = sk["L"]
    center = np.array([0.0, L / 2.0, 0.35 * sk["pts"]["A_f"][2]])
    for name, G, S in (("toit_d", sk["Pd"], sk["Pd"]), ("toit_g", sk["Pg"], sk["Pd"]),
                       ("mur_d", sk["Wd"], sk["Wd"]), ("mur_g", sk["Wg"], sk["Wd"])):
        mesh.add_grid(G, S, pid(name), flip=outward_flip(G, center))
    front, half = gables(sk, cfg)
    max_len = t.get("maille", 100.0) if fine else 100.0   # (pignons plans, peints par projection : pas de grille)
    V, F = refine_tris(front, polygon_faces(to_px(k, front) * [1.0, -1.0]), max_len)   # (dans le plan de la vue :
    # le bas des rabats sort du plan du pignon)
    F = [f if _faces_out(V, f, axes(k)[2]) else f[::-1] for f in F]   # (tournées vers la vue du dessin)
    mesh.add_faces(V, F, V, pid("pignon_av"))
    V, F = refine_tris(half, polygon_faces(half[:, [0, 2]]), max_len)
    F = [f if _faces_out(V, f, Y) else f[::-1] for f in F]
    mesh.add_faces(V, F, back_source(cfg, k, sk, V), pid("pignon_ar"))
    Vm = mirror_x(V)
    mesh.add_faces(Vm, [f[::-1] for f in F], back_source(cfg, k, sk, Vm), pid("pignon_ar"))
    if sk.get("porte_i"):   # le dedans, vu par l'entrée : la doublure des pans, des murs et du fond, peinte
        inset = t.get("doublure", 3.0) / k["s"]   # par la toile du dessin (côté dedans : la lumière cuite
        for G, S in ((sk["Pd"], sk["Pd"]), (sk["Pg"], sk["Pd"]), (sk["Wd"], sk["Wd"]), (sk["Wg"], sk["Wd"])):
            flip = outward_flip(G, center)   # l'assombrit, interieurs.py) ; un sol, des meubles
            n_out = grid_normals(G) * (-1.0 if flip else 1.0)
            Gi = G - inset * n_out
            mesh.add_grid(Gi, S, pid("dedans"), flip=not flip)
        for W in (V, Vm):
            Wi = np.asarray(W, float) - np.array([0.0, inset, 0.0])
            Fi = [f[::-1] for f in F] if W is V else list(F)
            mesh.add_faces(Wi, Fi, back_source(cfg, k, sk, W), pid("dedans"))
        interior(cfg, sk, mesh, pid)
    for name, V, F in volumes(cfg, k, sk):
        mesh.add_faces(V, F, V, pid(name))
    return mesh, names, sk


def interior(cfg, sk, mesh, pid):
    """Le dedans de la tente (réglage tente.interieur) : un sol (motif du jeu, « sol »), des meubles
    (boîtes, cylindres : interieurs.furniture_polys), et sk["interieurs"] : ses parties, l'entrée
    qui l'éclaire, sa boîte, la peinture ComfyUI ; sk["peintres"] : leurs motifs."""
    import interieurs
    it = cfg["tente"].get("interieur")
    if not it:
        return
    P, L = sk["pts"], sk["L"]
    corners = np.array([P["FL"], P["FR"], P["BR"], P["BL"]], float)
    c = corners.mean(0)
    d = c - corners
    corners = corners + d / np.linalg.norm(d, axis=1, keepdims=True) * it.get("retrait", 0.08)
    corners[:, 2] = it.get("z_sol", 0.015)
    peintres = {"dedans_sol": it.get("sol", "tuile:terre")}
    mesh.add_faces(corners, [[0, 1, 2, 3]], corners, pid("dedans_sol"))
    parts = ["dedans", "dedans_sol"]
    for j, m in enumerate(it.get("meubles", [])):
        name = "piece0_meuble%d" % j
        peintres[name] = m.get("peintre", "tuile:bois")
        parts.append(name)
        polys = [np.array(q, float) for q in interieurs.furniture_polys(m)]
        mc = np.concatenate(polys).mean(0)
        for q in polys:
            nrm = np.cross(q[1] - q[0], q[2] - q[0])
            q = q if nrm @ (q.mean(0) - mc) >= 0 else q[::-1]
            mesh.add_faces(q, [list(range(len(q)))], q, pid(name))
    door = sk["lines"]["porte"]
    allv = np.concatenate([sk["Pd"].reshape(-1, 3), sk["Pg"].reshape(-1, 3), sk["Wd"].reshape(-1, 3), sk["Wg"].reshape(-1, 3)])
    sk["peintres"] = peintres
    sk["interieurs"] = [{"cle": "piece0", "parts": parts,
                         "ouvertures": [{"poly": door[:, [0, 2]].tolist(), "y": 0.0, "sens": 1.0}],
                         "boite": [[float(allv[:, 0].min()), float(allv[:, 0].max())], [0.0, float(L)],
                                   [0.0, float(allv[:, 2].max())]],
                         "decor": it.get("decor"), "lumiere": it.get("lumiere", {"fond": 0.3})}]


def _faces_out(V, f, want):
    a, b, c = (np.asarray(V[i], float) for i in f[:3])
    return float(np.cross(b - a, c - a) @ want) >= 0.0
