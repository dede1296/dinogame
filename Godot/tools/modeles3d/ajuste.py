"""Ajustement d'un bâtiment assemblé (maisons.py) à la silhouette de ses dessins : le maillage fin
suit les formes des vues (faîtage et égout affaissés ou bombés, murs pas tout à fait droits,
cheminée penchée, rives irrégulières), au lieu de lignes tirées à la règle.

Pour chaque vue calée (face, côté, dos), le modèle est projeté (calage de la vue) et comparé au
dessin, colonne par colonne et rang par rang :
- le haut (contour supérieur) : faîtage, croupes, rives ; les parties en saillie au-dessus du
  corps (cheminée, redans) à part ;
- l'égout (frontière toit / mur) : le bord bas du trait sombre de l'égout dans le dessin (sombre
  au-dessus, mur clair dessous), près de l'égout du modèle, suivi de colonne en colonne (chemin
  continu) ; seule sa forme compte (décalage médian retiré) ;
- le bas des parties qui ne touchent pas le sol (avancée du toit, plancher sur pilotis) ;
- les bords gauche et droit de chaque tronçon de rang : ceux des murs (le toit suit le haut des
  murs) et ceux des parties en plus (cheminée : son propre champ).
Les parties en plus (cheminée, cristal, lucarne, poteaux, balcon…) gardent leur forme : elles se
déplacent d'un bloc et peuvent pencher (8 cm au plus). Chaque vue donne un champ de déplacement
dans son plan (perpendiculaire à sa direction de vue),
interpolé entre ces lignes (le sol ne bouge pas). Face et dos se partagent la hauteur et la
largeur selon la profondeur (la face, le dessin du jeu, décide jusqu'au-delà du milieu : un
faîtage creusé de face l'est aussi de dos) ; le côté donne la profondeur (Y). Les bords que
« effacer » a créés ne comptent pas. Deux passes ; déplacement borné (« max », m) ; un écart
est suivi en entier jusqu'à la moitié de « ecart », atténué au-delà.
Un écart de plus de « ecart » (0,12 m) n'est pas suivi : c'est un choix du modèle (croupe là où
une vue dessine un pignon). Contrôle : ajuste_<vue>.png dans le dossier de travail (rouge : monte,
bleu : descend, vert : de côté). Réglage par sorte (maisons.json) : "ajuster": false, ou {"max"
(0,2 m), "ecart", "passes", "cote" (poids), "fixes" (parties qui ne bougent pas : un toit ajouté
que le dessin cache)}.
"""
import os
import numpy as np

PROFILES = []       # (contrôle) profils mesurés, par vue
MAX_EDGE = 0.32     # m : arêtes plus longues coupées (les pans de toit ont des points à déplacer)
EAVE_HALF = 14      # px : recherche de l'égout du dessin autour de celui du modèle
EDGE_GUARD = 3      # px : un bord au contact d'une zone « effacer » n'est pas un bord du dessin


def refine(obj, max_len=MAX_EDGE):
    """Faces à plus de 4 côtés triangulées, arêtes longues coupées (grille) : des sommets partout."""
    import bmesh
    me = obj.data
    bm = bmesh.new(); bm.from_mesh(me)
    ngons = [f for f in bm.faces if len(f.verts) > 4]
    if ngons:
        bmesh.ops.triangulate(bm, faces=ngons)
    for _ in range(7):
        long_edges = [e for e in bm.edges if e.calc_length() > max_len]
        if not long_edges:
            break
        bmesh.ops.subdivide_edges(bm, edges=long_edges, cuts=1, use_grid_fill=True)
    bm.to_mesh(me); bm.free()
    me.update()


def _smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def _medfilt(a, size):
    """Filtre médian 1D (bords prolongés). (Le Python de Blender n'a ni scipy ni PIL.)"""
    half = size // 2
    p = np.pad(a, half, mode="edge")
    return np.median(np.lib.stride_tricks.sliding_window_view(p, size), axis=-1)


def _gauss1d(a, sigma, axis=0):
    """Flou gaussien le long d'un axe (bords prolongés)."""
    r = max(1, int(3 * sigma))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2)
    k /= k.sum()
    a = np.moveaxis(np.asarray(a, float), axis, 0)
    p = np.concatenate([np.repeat(a[:1], r, 0), a, np.repeat(a[-1:], r, 0)], 0)
    out = sum(k[i] * p[i:i + len(a)] for i in range(len(k)))
    return np.moveaxis(out, 0, axis)


def _dilate(mask, n):
    m = mask.copy()
    for _ in range(n):
        g = m.copy()
        g[1:] |= m[:-1]; g[:-1] |= m[1:]; g[:, 1:] |= m[:, :-1]; g[:, :-1] |= m[:, 1:]
        m = g
    return m


def _soft_gate(d, gate):
    """Écart suivi en entier jusqu'à gate/2, atténué jusqu'à gate, ignoré (NaN) au-delà."""
    d = np.asarray(d, float)
    w = np.clip((gate - np.abs(d)) / (0.5 * gate), 0.0, 1.0)
    return np.where(np.abs(d) > gate, np.nan, d * w)


def _fill_nan_1d(a):
    ok = ~np.isnan(a)
    if not ok.any():
        return np.zeros_like(a)
    idx = np.arange(len(a))
    return np.interp(idx, idx[ok], a[ok])


def _fill_nan_2d(img):
    """Trous (NaN) remplis le long des rangs, puis des colonnes (les rangs vides)."""
    out = img.copy()
    rows_ok = ~np.isnan(out).all(1)
    if not rows_ok.any():
        return np.zeros_like(out)
    for y in np.nonzero(rows_ok)[0]:
        out[y] = _fill_nan_1d(out[y])
    idx = np.arange(out.shape[0])
    for x in range(out.shape[1]):
        out[:, x] = np.interp(idx, idx[rows_ok], out[rows_ok, x])
    return out


def _tri_data(obj):
    """Sommets (n, 3) de chaque triangle, et sa partie."""
    me = obj.data
    me.calc_loop_triangles()
    n = len(me.loop_triangles)
    vi = np.empty(n * 3, np.int32); me.loop_triangles.foreach_get("vertices", vi)
    pi = np.empty(n, np.int32); me.loop_triangles.foreach_get("polygon_index", pi)
    part = np.empty(len(me.polygons), np.int32); me.attributes["part"].data.foreach_get("value", part)
    return vi.reshape(-1, 3), part[pi]


def _runs(row):
    """Tronçons [a, b] (inclus) des True d'un rang."""
    d = np.diff(np.concatenate([[0], row.astype(np.int8), [0]]))
    return list(zip(np.nonzero(d == 1)[0], np.nonzero(d == -1)[0] - 1))


def _track_eave(lum, cols, rows, half=EAVE_HALF, step=1, pen=0.06):
    """Bord bas du trait sombre de l'égout dans le dessin (sombre au-dessus, clair dessous : le mur),
    suivi de colonne en colonne (chemin continu), autour de l'égout du modèle : décalage (px) par
    colonne, et la luminance juste au-dessus (validité : un vrai trait sombre)."""
    H = lum.shape[0]
    n, K = len(cols), 2 * half + 1
    cost = np.full((n, K), 2.0)
    dark = np.full((n, K), 1.0)
    for i, (x, r) in enumerate(zip(cols, rows)):
        col = lum[:, max(0, x - 2):x + 3].mean(1)
        ys = np.arange(r - half, r + half + 1)
        ok = (ys >= 2) & (ys < H - 3)
        above = (col[ys[ok] - 1] + col[ys[ok] - 2]) / 2
        below = (col[ys[ok] + 2] + col[ys[ok] + 3]) / 2
        cost[i, ok] = -(below - above)
        dark[i, ok] = above
    acc, back = cost.copy(), np.zeros((n, K), np.int32)
    ks = np.arange(K)
    for i in range(1, n):
        prev = acc[i - 1]
        best = np.full(K, np.inf)
        for d in range(-step, step + 1):
            src = np.clip(ks + d, 0, K - 1)
            c = prev[src] + pen * abs(d)
            better = c < best
            best[better] = c[better]
            back[i, better] = src[better]
        acc[i] = cost[i] + best
    path = [int(np.argmin(acc[-1]))]
    for i in range(n - 1, 0, -1):
        path.append(int(back[i, path[-1]]))
    path = np.array(path[::-1])
    return path - half, dark[np.arange(n), path], -cost[np.arange(n), path]


def view_fields(k, tris2d, tri_part, part_names, drawing, erased, raster, max_px):
    """Champs (h, w) de déplacement d'une vue, en px : V vers le haut, Hh vers la droite. Un écart
    de plus de max_px n'est pas un détail du dessin mais un choix du modèle (croupe là où la vue
    dessine un pignon, toit ajouté) : ignoré, pas borné."""
    h, w = drawing.shape[:2]
    alpha = drawing[..., 3] > 0.5
    lum = np.where(alpha, drawing[..., :3].mean(2), 1.0)
    is_roof = np.array([n.startswith("toit") for n in part_names])
    is_body = np.array([n.startswith("toit") or n.startswith("murs") for n in part_names])
    full = raster(tris2d, w, h)
    body = raster(tris2d[is_body[tri_part]], w, h)
    roof = raster(tris2d[is_roof[tri_part]], w, h)
    guard = _dilate(erased, EDGE_GUARD) if erased.any() else erased
    ground = k["v0"] - 4
    # --- colonnes : haut, égout, bas
    top_full = np.where(full.any(0), full.argmax(0), -1)
    top_body = np.where(body.any(0), body.argmax(0), -1)
    bottom = np.where(full.any(0), h - 1 - full[::-1].argmax(0), -1)
    d_top = np.where(alpha.any(0), alpha.argmax(0), -1)
    extra = (top_full >= 0) & (top_body >= 0) & (top_full < top_body - 3)
    d_body = np.full(w, np.nan)
    d_extra = np.full(w, np.nan)
    for x in range(w):
        if top_full[x] < 0 or d_top[x] <= 0 or top_full[x] <= 0 or guard[max(0, d_top[x] - 2), x]:
            continue
        t_model = top_body[x] if (top_body[x] >= 0 and not extra[x]) else top_full[x]
        (d_extra if extra[x] else d_body)[x] = _soft_gate(float(t_model - d_top[x]), max_px)
    has_body = top_body >= 0
    if np.isfinite(d_body).sum() > 3:
        d_body = _fill_nan_1d(d_body)
        d_body = _gauss1d(_medfilt(d_body, 11), 2.0)
    else:
        d_body = np.zeros(w)
    d_extra = np.where(np.isnan(d_extra), 0.0, d_extra)
    # égout : la plus basse rangée du toit, avec du corps juste dessous
    eave_rows = np.full(w, -1)
    for x in range(w):
        if not roof[:, x].any():
            continue
        r = h - 1 - roof[::-1, x].argmax()
        if r + 4 < h and body[r + 4, x] and not roof[r + 4, x]:
            eave_rows[x] = r
    d_eave = np.full(w, np.nan)
    cols = np.nonzero(eave_rows >= 0)[0]
    if len(cols) > 10:
        offs, dark, contrast = _track_eave(lum, cols, eave_rows[cols])
        good = (dark < 0.45) & (contrast > 0.15)
        if good.sum() > 10:
            d = -offs.astype(float)
            d -= np.median(d[good])
            d = _soft_gate(d, max_px)
            d[~good] = np.nan
            prof = np.full(w, np.nan)
            prof[cols] = d
            filled = _fill_nan_1d(prof[cols[0]:cols[-1] + 1])
            filled = _gauss1d(_medfilt(filled, 21), 5.0)
            d_eave[cols[0]:cols[-1] + 1] = filled
            d_eave[eave_rows < 0] = np.nan
    # bas des parties qui ne touchent pas le sol
    d_bottom = np.zeros(w)
    for x in range(w):
        b = bottom[x]
        if b < 0 or b >= ground:
            continue
        col = alpha[:, x]
        if col[b]:
            y = b
            while y + 1 < h and col[y + 1]:
                y += 1
        else:
            y = b
            while y > 0 and not col[y] and b - y < 12:
                y -= 1
            if not col[y]:
                continue
        g = _soft_gate(float(b - y), max_px)
        if np.isfinite(g):
            d_bottom[x] = g
    d_bottom = _medfilt(d_bottom, 7)
    PROFILES.append({"haut": d_body, "egout": d_eave, "bas": d_bottom, "egout_modele": eave_rows})
    V = np.full((h, w), np.nan)
    rows = np.arange(h)
    for x in range(w):
        if top_full[x] < 0:
            continue
        keys = []
        if extra[x]:
            keys.append((top_full[x], d_extra[x]))
            keys.append((top_body[x], d_body[x]))
        else:
            keys.append((top_body[x] if has_body[x] else top_full[x], d_body[x]))
        if eave_rows[x] >= 0 and np.isfinite(d_eave[x]):
            keys.append((eave_rows[x], d_eave[x]))
        keys.append((bottom[x], 0.0 if bottom[x] >= ground else d_bottom[x]))
        keys.sort()
        kr, kv = [], []
        for r, v in keys:
            if not kr or r > kr[-1]:
                kr.append(r); kv.append(v)
        V[:, x] = np.interp(rows, kr, kv)
    V = _gauss1d(_gauss1d(_fill_nan_2d(V), 3.0, axis=0), 3.0, axis=1)
    # --- rangs : bords gauche et droit de chaque tronçon. Seuls les bords de mur (et le toit suit
    # le haut des murs) et ceux des parties en plus (cheminée : son propre champ) sont mesurés ;
    # un bord de toit (croupe, rive) ne l'est pas : le haut du contour le suit déjà.
    is_wall = np.array([n.startswith("murs") for n in part_names])
    walls = raster(tris2d[is_wall[tri_part]], w, h)
    extras = full & ~body

    def edge_d(y, a, b, c, d):
        dl, dr = float(c - a), float(d - b)
        dl = np.nan if (c <= 0 or guard[y, max(0, c - 1)]) else _soft_gate(dl, max_px)
        dr = np.nan if (d >= w - 1 or guard[y, min(w - 1, d + 1)]) else _soft_gate(dr, max_px)
        return dl, dr

    Hw = np.full((h, w), np.nan)
    He = np.full((h, w), np.nan)
    for y in range(h):
        mruns = _runs(full[y])
        if not mruns:
            continue
        druns = _runs(alpha[y])
        for a, b in mruns:
            best, ov = None, 0
            for c, d in druns:
                o = min(b, d) - max(a, c)
                if o > ov:
                    best, ov = (c, d), o
            if best is None:
                continue
            dl, dr = edge_d(y, a, b, *best)
            for field, sel in ((Hw, walls[y] & ~roof[y]), (He, extras[y])):
                if not (sel[a] or sel[b]):
                    continue
                l = dl if sel[a] else np.nan
                r = dr if sel[b] else np.nan
                if np.isnan(l) and np.isnan(r):
                    continue
                l = r if np.isnan(l) else l
                r = l if np.isnan(r) else r
                field[y, a:b + 1] = np.linspace(l, r, b - a + 1)
    Hw = _gauss1d(_gauss1d(_fill_nan_2d(Hw), 4.0, axis=0), 2.0, axis=1)
    He = _gauss1d(_fill_nan_2d(He), 2.0, axis=0)
    Hh = (Hw, He, _dilate(extras, 1))
    return V, Hh


def _debug_image(drawing, V, Hh, scale):
    """Contrôle : le dessin en gris, V en rouge (monte) / bleu (descend), Hh en vert / magenta."""
    img = np.zeros(drawing.shape[:2] + (4,), np.float32)
    grey = drawing[..., :3].mean(2) * 0.5
    a = drawing[..., 3] > 0.5
    img[..., 0] = grey + np.clip(V / scale, 0, 1)
    img[..., 2] = grey + np.clip(-V / scale, 0, 1)
    img[..., 1] = grey + np.clip(np.abs(Hh[0]) / scale, 0, 1) * 0.8
    img[..., 3] = np.where(a, 1.0, 0.35)
    return np.clip(img, 0, 1)


def _rigid_extras(disp, co, part_of_v, extra_parts):
    """Une partie en plus (cheminée, cristal, lucarne, poteau, marche, balcon) garde sa forme :
    son déplacement devient une translation, plus une inclinaison (x et y variant avec la hauteur,
    moindres carrés) : une cheminée penche, elle ne se tord pas."""
    out = disp.copy()
    for p in extra_parts:
        idx = np.nonzero(part_of_v == p)[0]
        if len(idx) == 0:
            continue
        z = co[idx, 2]
        A = np.stack([np.ones(len(idx)), z - z.mean()], 1)
        for ax in (0, 1):
            coef, *_ = np.linalg.lstsq(A, disp[idx, ax], rcond=None)
            span = max(z.max() - z.min(), 1e-6)
            coef[1] = np.clip(coef[1], -0.08 / span, 0.08 / span)   # (8 cm d'inclinaison au plus)
            out[idx, ax] = A @ coef
        out[idx, 2] = disp[idx, 2].mean()
    return out


def fit(obj, cfg, cal, work, frame, raster, load_rgba, save_rgba=None):
    """Déforme obj (maillage fin, attribut « part ») pour suivre les dessins des vues calées."""
    opts = cfg.get("ajuster", {})
    if opts is False:
        return
    refine(obj)
    me = obj.data
    names = list(obj["parts"])
    fixed_names = set(opts.get("fixes", []))
    max_m = opts.get("max", 0.2)         # déplacement total borné (m)
    gate_m = opts.get("ecart", 0.12)     # écart d'une ligne au-delà duquel le dessin n'est pas suivi (m)
    co0 = np.empty(len(me.vertices) * 3); me.vertices.foreach_get("co", co0); co0 = co0.reshape(-1, 3)
    part = np.empty(len(me.polygons), np.int32); me.attributes["part"].data.foreach_get("value", part)
    movable = np.zeros(len(me.vertices), bool)
    for poly in me.polygons:
        if names[part[poly.index]] not in fixed_names:
            movable[list(poly.vertices)] = True
    tri_v, tri_part = _tri_data(obj)
    is_extra_v = np.zeros(len(me.vertices), bool)   # sommets des parties en plus (cheminée, lucarne…)
    part_of_v = np.full(len(me.vertices), -1)
    for poly in me.polygons:
        nm = names[part[poly.index]]
        part_of_v[list(poly.vertices)] = part[poly.index]
        if not (nm.startswith("toit") or nm.startswith("murs")):
            is_extra_v[list(poly.vertices)] = True
    extra_parts = sorted({part_of_v[i] for i in np.nonzero(is_extra_v)[0]})
    keep_tri = np.array([names[p] not in fixed_names for p in tri_part])
    views = {}
    for v in ("face", "dos", "cote"):
        path = os.path.join(work, "vue_%s.png" % v)
        if v in cal and os.path.exists(path):
            d = load_rgba(path)
            ep = os.path.join(work, "efface_%s.png" % v)
            e = load_rgba(ep)[..., 0] > 0.5 if os.path.exists(ep) else np.zeros(d.shape[:2], bool)
            views[v] = (d, e)
    ymin, ymax = co0[:, 1].min(), co0[:, 1].max()
    co = co0.copy()
    for it in range(opts.get("passes", 2)):
        t = (co[:, 1] - ymin) / max(ymax - ymin, 1e-6)
        w_face = 1.0 - _smoothstep(0.55, 0.95, t) if "dos" in views else np.ones(len(co))
        disp = np.zeros_like(co)
        for v, (drawing, erased) in views.items():
            k = cal[v]
            R, U, _ = frame(v, k["theta"])
            pts = co.copy()
            if v == "cote":   # (le côté gauche : la même vue, en miroir)
                pts[:, 0] = np.abs(pts[:, 0])
            p2 = np.stack([k["u0"] + k["s"] * (pts @ R), k["v0"] - k["s"] * (pts @ U)], 1)
            tris2d = p2[tri_v[keep_tri]]
            V, Hh = view_fields(k, tris2d, tri_part[keep_tri], names, drawing, erased, raster, gate_m * k["s"])
            if it == 0 and save_rgba:
                save_rgba(os.path.join(work, "ajuste_%s.png" % v), _debug_image(drawing, V, Hh, gate_m * k["s"]))
            px = np.clip(np.round(p2[:, 0]).astype(int), 0, V.shape[1] - 1)
            py = np.clip(np.round(p2[:, 1]).astype(int), 0, V.shape[0] - 1)
            dv = V[py, px] / k["s"]
            # une partie en plus qui dépasse du corps dans cette vue (cheminée) suit son propre champ ;
            # une partie contenue dans le corps (lucarne, balcon devant le mur) suit le corps
            own = np.zeros(len(co), bool)
            inside = Hh[2][py, px]
            for p in extra_parts:
                idx = part_of_v == p
                if inside[idx].any():
                    own |= idx
            dh = np.where(own, Hh[1][py, px], Hh[0][py, px]) / k["s"]
            if v == "cote":
                weight = opts.get("cote", 1.0) * np.clip(co[:, 2] / 0.6, 0.0, 1.0)   # (le pied de façade reste)
                disp[:, 1] += weight * dh * R[1]
            else:
                wv = w_face if v == "face" else 1.0 - w_face
                disp += wv[:, None] * (dv[:, None] * U[None] + dh[:, None] * R[None])
        disp = _rigid_extras(disp, co, part_of_v, extra_parts)
        co = co + np.where(movable[:, None], disp, 0.0)
        off = co - co0
        n = np.linalg.norm(off, axis=1)
        co = co0 + off * np.minimum(1.0, max_m / np.maximum(n, 1e-9))[:, None]
    me.vertices.foreach_set("co", co.ravel())
    me.update()
    moved = np.linalg.norm(co - co0, axis=1)
    print("AJUSTE : %d sommets, déplacement moyen %.3f m, max %.3f m" % (len(co), moved.mean(), moved.max()))
