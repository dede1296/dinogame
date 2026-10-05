"""Depuis plaines-layout.json : le relief (champ de hauteurs sur une grille de 0,5 m), les deux images
du plan (plaines-plan.png, plaines-plan-relief.png), et la vérification : praticabilité (pente,
eau, haies, parois), largeur de passage >= 1,2 m, atteignabilité de chaque ancre depuis le port
(avant / après les trois passages), temps de trajet (Dijkstra) à 1,6 et 5 m/s, pentes des sentiers.
Usage : python plan_zone.py <layout.json> <dossier de sortie>
"""
import json, math, sys, heapq, os
from collections import deque
import numpy as np
from PIL import Image, ImageDraw, ImageFont

layout = json.load(open(sys.argv[1], encoding="utf-8"))
OUT = sys.argv[2]
W_M, H_M = layout["size_m"]
RES = 0.5                       # m par cellule
NX, NZ = int(W_M / RES), int(H_M / RES)
xs = (np.arange(NX) + 0.5) * RES
zs = (np.arange(NZ) + 0.5) * RES
X, Z = np.meshgrid(xs, zs)      # [NZ, NX]

# ------------------------------------------------------------------ géométrie
def smoothstep(a, b, t):
    k = np.clip((t - a) / (b - a), 0.0, 1.0)
    return k * k * (3 - 2 * k)

def dist_segments(points, closed=False):
    """Distance de chaque cellule à la polyligne (m) et paramètre t (0..1 sur toute la longueur)."""
    pts = [tuple(p) for p in points]
    if closed:
        pts = pts + [pts[0]]
    best = np.full(X.shape, 1e9)
    tbest = np.zeros(X.shape)
    lens = [math.hypot(pts[i + 1][0] - pts[i][0], pts[i + 1][1] - pts[i][1]) for i in range(len(pts) - 1)]
    total = sum(lens) or 1.0
    acc = 0.0
    for i in range(len(pts) - 1):
        (x0, z0), (x1, z1) = pts[i], pts[i + 1]
        dx, dz = x1 - x0, z1 - z0
        l2 = dx * dx + dz * dz or 1e-9
        t = np.clip(((X - x0) * dx + (Z - z0) * dz) / l2, 0, 1)
        d = np.hypot(X - (x0 + t * dx), Z - (z0 + t * dz))
        m = d < best
        best = np.where(m, d, best)
        tbest = np.where(m, (acc + t * lens[i]) / total, tbest)
        acc += lens[i]
    return best, tbest

def inside_polygon(points):
    """Masque booléen des cellules dans le polygone (rayon)."""
    inside = np.zeros(X.shape, dtype=bool)
    n = len(points)
    for i in range(n):
        x0, z0 = points[i]
        x1, z1 = points[(i + 1) % n]
        cond = (z0 > Z) != (z1 > Z)
        xint = x0 + (Z - z0) * (x1 - x0) / ((z1 - z0) if z1 != z0 else 1e-9)
        inside ^= cond & (X < xint)
    return inside

def signed_dist_polygon(points):
    d, _ = dist_segments(points, closed=True)
    return np.where(inside_polygon(points), -d, d)

def ellipse_dist(center, radii, rot_deg=0.0):
    """« Distance » normalisée (1 sur le bord) d'une ellipse tournée."""
    cx, cz = center
    a = math.radians(rot_deg)
    dx, dz = X - cx, Z - cz
    u = dx * math.cos(a) + dz * math.sin(a)
    v = -dx * math.sin(a) + dz * math.cos(a)
    return np.hypot(u / radii[0], v / radii[1])

def fbm(x, z, wavelength, seed=7):
    """Bruit lisse (somme de sinus déphasés) entre -1 et 1."""
    rng = np.random.default_rng(seed)
    out = np.zeros_like(x)
    amp = 0.0
    for k in range(6):
        ang = rng.uniform(0, math.pi)
        f = (1.0 / wavelength) * (1.0 + 0.6 * k)
        ph = rng.uniform(0, 2 * math.pi)
        a = 1.0 / (1.0 + 0.7 * k)
        out += a * np.sin(2 * math.pi * f * (x * math.cos(ang) + z * math.sin(ang)) + ph)
        amp += a
    return out / amp

def wob(m, seed=11):
    """Ondulation des bords (m) : perturbe une distance pour casser les formes géométriques."""
    w = m.get("wobble_m", 0.0)
    return fbm(X, Z, 14.0, seed) * w if w else 0.0

# ------------------------------------------------------------------ chemins (masques)
PATHS = layout["paths"]
path_dist = np.full(X.shape, 1e9)
for p in PATHS:
    d, _ = dist_segments(p["points"])
    path_dist = np.minimum(path_dist, d - p["width_m"] / 2)
clear_mask = np.zeros(X.shape, dtype=bool)
for c in layout["clearings"]:
    clear_mask |= np.hypot(X - c["center"][0], Z - c["center"][1]) < c["radius"]

# ------------------------------------------------------------------ relief
H = np.full(X.shape, float(layout["relief"]["base_m"]))

def blend(H, target, w, op):
    if op == "add":
        return H + target * w
    if op == "max":
        return np.maximum(H, H * (1 - w) + target * w) if False else np.where(w > 0, np.maximum(H, (1 - w) * H + w * target), H)
    if op == "set":
        return H * (1 - w) + target * w
    raise ValueError(op)

for m in layout["relief"]["modifiers"]:
    k = m["kind"]
    op = m.get("op", "add")
    if m.get("after_water"):
        continue
    if k == "dome":
        r = ellipse_dist(m["center"], m["radii"], m.get("rot_deg", 0))
        w = 1 - smoothstep(m.get("flat", 0.0), 1.0, r)
        H = H + m["height"] * w
    elif k == "plateau":
        if "polygon" in m:
            sd = signed_dist_polygon(m["polygon"]) + wob(m)
            w = 1 - smoothstep(0.0, m["edge_m"], sd)   # 1 dedans, 0 à edge_m dehors
        else:
            r = ellipse_dist(m["center"], m["radii"], m.get("rot_deg", 0))
            rm = (m["radii"][0] + m["radii"][1]) / 2
            r = r + wob(m) / rm
            w = 1 - smoothstep(1.0, 1.0 + m["edge_m"] / rm, r)
        H = blend(H, np.full(X.shape, float(m["level"])), w, op)
    elif k == "ridge":
        d, _ = dist_segments(m["points"])
        d = d + wob(m)
        w = 1 - smoothstep(m["half_width_m"], m["half_width_m"] + m["falloff_m"], d)
        if m.get("absolute"):
            H = blend(H, np.full(X.shape, float(m["height"])), w, op)
        else:
            H = H + m["height"] * w
    elif k == "gradient":
        axis = (X if m["axis"] == "x" else Z) + wob(m)
        (c0, h0), (c1, h1) = m["from"], m["to"]
        t = np.clip((axis - c0) / (c1 - c0), 0, 1)
        target = h0 + (h1 - h0) * t
        active = ((axis - c0) / (c1 - c0)) > 0
        H = np.where(active, np.maximum(H, target), H) if op == "max" else H
    elif k == "water_basin":
        sd = signed_dist_polygon(m["polygon"]) if "polygon" in m else (ellipse_dist(m["ellipse"]["center"], m["ellipse"]["radii"]) - 1) * min(m["ellipse"]["radii"])
        lvl, dep, inn, out = m["level"], m["depth"], m["inner_m"], m["outer_m"]
        target = np.where(sd <= -inn, lvl - dep, np.where(sd <= 0, lvl - dep * (-sd / inn), lvl))
        w = np.where(sd <= 0, 1.0, 1 - smoothstep(0, out, sd))
        H = H * (1 - w) + target * w
    elif k == "carve":
        d, t = dist_segments(m["points"])
        if m.get("levels"):
            h0, h1 = m["levels"]
            target = h0 + (h1 - h0) * t
        else:   # follow_ground : le profil lissé du sol le long de la ligne, décalé
            pts = m["points"]; samples = []
            for i in range(len(pts) - 1):
                (x0, z0), (x1, z1) = pts[i], pts[i + 1]
                n = max(1, int(math.hypot(x1 - x0, z1 - z0)))
                samples += [(x0 + (x1 - x0) * q / n, z0 + (z1 - z0) * q / n) for q in range(n)]
            samples.append(tuple(pts[-1]))
            ii = np.clip((np.array([q[0] for q in samples]) / RES).astype(int), 0, NX - 1)
            jj = np.clip((np.array([q[1] for q in samples]) / RES).astype(int), 0, NZ - 1)
            prof = H[jj, ii]
            kk = 15
            prof = np.convolve(np.pad(prof, (kk // 2, kk // 2), mode="edge"), np.ones(kk) / kk, mode="valid")
            prof = np.minimum.accumulate(prof) if m.get("monotone_down", True) else prof
            idx = np.clip((t * (len(prof) - 1)).astype(int), 0, len(prof) - 1)
            target = prof[idx] + m.get("offset_m", 0.0)
        w = 1 - smoothstep(m["width_m"] / 2, m["width_m"] / 2 + m["blend_m"], d)
        H = H * (1 - w) + target * w
    elif k == "noise":
        n = fbm(X, Z, m["wavelength_m"]) * m["amplitude_m"]
        mask = smoothstep(1.0, m["clear_paths_m"], path_dist) * (~clear_mask)
        H = H + n * mask
    else:
        raise ValueError(k)

# l'eau (étang) : creuse
water_level = np.full(X.shape, -99.0)      # niveau d'eau là où il y en a
for wtr in layout["water"]:
    if wtr["kind"] == "pond":
        e = wtr["ellipse"]
        r = ellipse_dist(e["center"], e["radii"])
        rm = min(e["radii"])
        sd = (r - 1) * rm
        inn, dep, lvl = max(2.0, rm * 0.5), wtr["depth"], wtr["level"]
        target = np.where(sd <= -inn, lvl - dep, np.where(sd <= 0, lvl - dep * (-sd / inn), lvl))
        w = np.where(sd <= 0, 1.0, 1 - smoothstep(0, 4.0, sd))
        H = H * (1 - w) + target * w
        water_level = np.where(sd <= 0.3, lvl, water_level)
    elif wtr["kind"] == "sea":
        water_level = np.where(H < 0.0, 0.0, water_level)
for m in layout["relief"]["modifiers"]:
    if not m.get("after_water"):
        continue
    if m["kind"] == "plateau_ellipse_after_water":
        r = ellipse_dist(m["center"], m["radii"])
        rm = min(m["radii"])
        w = 1 - smoothstep(1.0, 1.0 + m["edge_m"] / rm, r)
        H = H * (1 - w) + m["level"] * w
        water_level = np.where(H > water_level, -99.0, water_level)
    elif m["kind"] == "rect_after_water":
        r = m["rect"]
        sd = np.maximum(np.maximum(r[0] - X, X - (r[0] + r[2])), np.maximum(r[1] - Z, Z - (r[1] + r[3])))
        w = 1 - smoothstep(0.0, m["blend_m"], sd)
        H = np.where(w > 0, np.maximum(H, H * (1 - w) + m["level"] * w), H)
brook = next(w for w in layout["water"] if w["kind"] == "brook")

# les sentiers rabotent le sol : profil lissé le long de chaque sentier
def sample(h, x, z):
    i = np.clip((np.asarray(x) / RES).astype(int), 0, NX - 1)
    j = np.clip((np.asarray(z) / RES).astype(int), 0, NZ - 1)
    return h[j, i]

for p in PATHS:
    pts = p["points"]
    # échantillons tous les 1 m le long du sentier
    samples = []
    for i in range(len(pts) - 1):
        (x0, z0), (x1, z1) = pts[i], pts[i + 1]
        n = max(1, int(math.hypot(x1 - x0, z1 - z0)))
        for k in range(n):
            t = k / n
            samples.append((x0 + (x1 - x0) * t, z0 + (z1 - z0) * t))
    samples.append(tuple(pts[-1]))
    sx = np.array([s[0] for s in samples]); sz = np.array([s[1] for s in samples])
    prof = sample(H, sx, sz)
    # lissage (moyenne glissante 9 m)
    k = 9
    pad = np.pad(prof, (k // 2, k // 2), mode="edge")
    prof_s = np.convolve(pad, np.ones(k) / k, mode="valid")
    # pente maxi du sentier : on relaxe le profil jusqu'à la respecter (le sol est raboté ensuite)
    lim = math.tan(math.radians(p["grade_max_deg"]))
    ds = np.hypot(np.diff(sx), np.diff(sz))
    for _ in range(400):
        dh = np.diff(prof_s)
        over = np.abs(dh) > lim * ds
        if not over.any():
            break
        corr = (np.abs(dh) - lim * ds) * np.sign(dh) * 0.5
        corr = np.where(over, corr, 0.0)
        prof_s[:-1] += corr
        prof_s[1:] -= corr
    # rabotage : cible = profil lissé interpolé le long du sentier
    d, t = dist_segments(pts)
    idx = np.clip((t * (len(prof_s) - 1)).astype(int), 0, len(prof_s) - 1)
    target = prof_s[idx]
    w = 1 - smoothstep(p["width_m"] / 2, p["width_m"] / 2 + 2.0, d)
    H = H * (1 - w) + target * w
    p["_profile"] = (sx, sz, prof_s)

# ------------------------------------------------------------------ praticabilité
gx = np.zeros_like(H); gz = np.zeros_like(H)
gx[:, 1:-1] = (H[:, 2:] - H[:, :-2]) / (2 * RES)
gz[1:-1, :] = (H[2:, :] - H[:-2, :]) / (2 * RES)
slope_deg = np.degrees(np.arctan(np.hypot(gx, gz)))
WALK_SLOPE = 42.0
depth = np.where(water_level > -50, water_level - H, 0.0)
deep = depth > 0.6
walk = (slope_deg <= WALK_SLOPE) & ~deep
walk[0, :] = walk[-1, :] = walk[:, 0] = walk[:, -1] = False

blocked_story = {}   # id -> masque
for b in layout["blockers"]:
    k = b["kind"]
    if k in ("hedge", "bank"):
        for key in ("polyline", "polyline2"):
            if key in b:
                d, _ = dist_segments(b[key], closed=bool(b.get("closed")) and key == "polyline")
                mk = d < b["width_m"] / 2
                if "gap" in b and key == "polyline":
                    g = b["gap"]
                    mk &= ~(np.hypot(X - g["at"][0], Z - g["at"][1]) < g["width_m"] / 2 + 0.5)
                walk &= ~mk
    elif k == "trunk":
        mk = np.hypot(X - b["at"][0], Z - b["at"][1]) < b["length_m"] / 2
        blocked_story[b["id"]] = mk
    elif k == "boulder":
        mk = np.hypot(X - b["at"][0], Z - b["at"][1]) < b["diameter_m"] / 2 + b.get("eboulis_m", 2.0)   # + éboulis de part et d'autre
        blocked_story[b["id"]] = mk
    elif k == "door":
        mk = (np.abs(X - b["at"][0]) < b["width_m"] / 2 + 1) & (np.abs(Z - b["at"][1]) < (2.0 if b["id"] == "grand_crane" else 1.0))
        blocked_story[b["id"]] = mk
    elif k == "moon_ford":
        r = b["rect"]
        mk = (X >= r[0]) & (X < r[0] + r[2]) & (Z >= r[1]) & (Z < r[1] + r[3])
        walk |= mk & (slope_deg <= WALK_SLOPE)     # à la pleine lune, praticable
        blocked_story[b["id"]] = mk
    elif k == "forest_edge":
        for key in ("polygon", "polygon2"):
            if key in b:
                walk &= ~inside_polygon(b[key])

def erode(mask):
    """Largeur de passage : une cellule n'est praticable que si ses 8 voisines le sont (≈ 1,2-1,4 m)."""
    m = mask.copy()
    for dz in (-1, 0, 1):
        for dx in (-1, 0, 1):
            m &= np.roll(np.roll(mask, dz, 0), dx, 1)
    return m

def reach(walkable, start):
    m = erode(walkable)
    i0, j0 = int(start[0] / RES), int(start[1] / RES)
    # le départ : la cellule praticable la plus proche
    seen = np.zeros_like(m)
    if not m[j0, i0]:
        for r in range(1, 12):
            cand = [(j0 + dj, i0 + di) for dj in range(-r, r + 1) for di in range(-r, r + 1) if 0 <= j0 + dj < NZ and 0 <= i0 + di < NX and m[j0 + dj, i0 + di]]
            if cand:
                j0, i0 = cand[0]; break
    q = deque([(j0, i0)]); seen[j0, i0] = True
    while q:
        j, i = q.popleft()
        for dj, di in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            jj, ii = j + dj, i + di
            if 0 <= jj < NZ and 0 <= ii < NX and m[jj, ii] and not seen[jj, ii]:
                seen[jj, ii] = True; q.append((jj, ii))
    return seen, m

def near_reach(seen, at, r_m=3.0):
    i, j = int(at[0] / RES), int(at[1] / RES)
    r = int(r_m / RES)
    sub = seen[max(0, j - r):j + r + 1, max(0, i - r):i + r + 1]
    return bool(sub.any())

def dijkstra(walkable_eroded, start):
    """Distances (m) depuis start sur la grille 0,5 m (8 voisins, longueur 3D)."""
    INF = 1e9
    dist = np.full(walkable_eroded.shape, INF)
    i0, j0 = int(start[0] / RES), int(start[1] / RES)
    if not walkable_eroded[j0, i0]:
        for r in range(1, 12):
            found = False
            for dj in range(-r, r + 1):
                for di in range(-r, r + 1):
                    if 0 <= j0 + dj < NZ and 0 <= i0 + di < NX and walkable_eroded[j0 + dj, i0 + di]:
                        j0, i0 = j0 + dj, i0 + di; found = True; break
                if found: break
            if found: break
    dist[j0, i0] = 0.0
    pq = [(0.0, j0, i0)]
    nb = [(1, 0, RES), (-1, 0, RES), (0, 1, RES), (0, -1, RES), (1, 1, RES * 1.4142), (1, -1, RES * 1.4142), (-1, 1, RES * 1.4142), (-1, -1, RES * 1.4142)]
    while pq:
        d, j, i = heapq.heappop(pq)
        if d > dist[j, i]:
            continue
        for dj, di, l in nb:
            jj, ii = j + dj, i + di
            if 0 <= jj < NZ and 0 <= ii < NX and walkable_eroded[jj, ii]:
                dh = H[jj, ii] - H[j, i]
                nd = d + math.hypot(l, dh) * (1.0 if path_dist[jj, ii] <= 0 else 1.0)
                if nd < dist[jj, ii]:
                    dist[jj, ii] = nd; heapq.heappush(pq, (nd, jj, ii))
    return dist

def dist_at(dist, at, r_m=3.0):
    i, j = int(at[0] / RES), int(at[1] / RES)
    r = int(r_m / RES)
    sub = dist[max(0, j - r):j + r + 1, max(0, i - r):i + r + 1]
    v = sub.min()
    return None if v >= 1e8 else float(v)

report = []
def say(s):
    print(s); report.append(s)

anchors = layout["anchors"]
def anchor_points():
    out = []
    for a in anchors:
        if "new" in a:
            out.append((a["id"], a["new"]))
        elif "new_points" in a:
            for k, p in enumerate(a["new_points"]):
                out.append((f"{a['id']}[{k}]", p))
        elif "new_rect" in a and a["kind"] not in ("keep_clear",):
            r = a["new_rect"]; out.append((a["id"], [r[0] + r[2] / 2, r[1] + r[3] / 2]))
    return out

say("=== Vérification du plan : %s (%d x %d m, grille %.1f m) ===" % (layout["name"], W_M, H_M, RES))
say("pente maxi praticable %.0f°, eau bloquante > 0,6 m, largeur de passage >= 1,2 m (érosion 3x3)" % WALK_SLOPE)
walk_closed = walk.copy()
for mk in blocked_story.values():
    walk_closed &= ~mk
start = next(a for a in anchors if a["id"] == "spawn_DepuisPort")["new"]
seen_closed, _ = reach(walk_closed, start)
seen_open, m_open = reach(walk, start)
behind = {"GueDeLune", "ilot", "Page2", "pierre_plate", "GaletIlot", "AmbreProtoceratops", "props_bosquet[0]", "props_bosquet[1]", "props_bosquet[2]", "props_bosquet[3]", "props_bosquet[4]", "RocherGrotte", "galets_arbres[6]", "EntreeGrotte", "exit_grotte_echos", "spawn_DepuisGrotte", "spawn_Falaises", "poste_banc", "panneau_falaises", "page3", "ecaille_falaises", "table_observation", "feu_camp_poste", "nids_dimorphodon[0]", "nids_dimorphodon[1]", "galets_recoins[1]", "galets_arbres[5]", "AntreCrane", "exit_antre_crane", "spawn_DepuisAntre", "scene_crane[0]"}
bad = 0
for aid, at in anchor_points():
    c, o = near_reach(seen_closed, at), near_reach(seen_open, at)
    expect_closed = aid not in behind
    status = "ok"
    if not o:
        status = "INATTEIGNABLE (même passages ouverts)"; bad += 1
    elif expect_closed and not c:
        status = "INATTEIGNABLE avant les passages"; bad += 1
    elif not expect_closed and c:
        status = "ATTENTION : atteignable AVANT son passage (contournement)"; bad += 1
    say("  %-28s (%6.1f, %6.1f) h=%5.2f  avant:%s après:%s  %s" % (aid, at[0], at[1], float(sample(H, at[0], at[1])), "oui" if c else "non", "oui" if o else "non", status))
say("ancres en défaut : %d" % bad)

# temps de trajet
WALK, RUN = 1.6, 5.0
dist_port = dijkstra(m_open, start)
A = {a["id"]: a["new"] for a in anchors if "new" in a}
legs = [("port -> Maïa (carrefour)", start, A["Maia"]), ("port -> gué du ru", start, [118, 127]),
        ("carrefour -> tronc de Tranche", A["Maia"], A["TroncBosquet"]), ("tronc -> fragment d'ambre (clairière)", A["TroncBosquet"], A["AmbreProtoceratops"]),
        ("carrefour -> rocher de Charge", A["Maia"], A["RocherGrotte"]), ("carrefour -> porte d'ambre", A["Maia"], A["PorteAmbre"]),
        ("porte d'ambre -> poste d'observation", A["PorteAmbre"], A["page3"]), ("carrefour -> Grand Crâne (panneau)", A["Maia"], A["panneau_crane"]),
        ("étang (panneau) -> Grand Crâne", A["panneau_etang"], A["panneau_crane"]), ("carrefour -> nid de Chipie", A["Maia"], A["NidChipie"]),
        ("carrefour -> sortie Forêt", A["Maia"], A["spawn_DepuisForet"]), ("gué du ru -> crique (panneau)", [118, 127], A["panneau_anse"]), ("carrefour -> parvis du Crâne", A["Maia"], A["MaiaDefi"]), ("carrefour -> poste (tout le passage 3)", A["Maia"], A["page3"]), ("carrefour -> cascade", A["Maia"], [226, 88]), ("carrefour -> fragment (tout le passage 1)", A["Maia"], A["AmbreProtoceratops"]),
        ("carrefour -> belvédère", A["Maia"], [128, 29]), ("Grand Crâne -> port (retour)", A["panneau_crane"], start),
        ("carrefour -> dormeur", A["Maia"], A["Dormeur"])]
say("\n=== Temps de trajet (plus court chemin praticable, passages ouverts) : marche 1,6 m/s / course 5 m/s ===")
cache = {}
for name, a, b in legs:
    key = tuple(a)
    if key not in cache:
        cache[key] = dijkstra(m_open, a)
    d = dist_at(cache[key], b)
    if d is None:
        say("  %-42s : INATTEIGNABLE" % name)
    else:
        say("  %-42s : %5.0f m  marche %3.0f s  course %3.0f s" % (name, d, d / WALK, d / RUN))

say("\n=== Pentes des sentiers (profil lissé) ===")
for p in PATHS:
    sx, sz, prof = p["_profile"]
    g = np.abs(np.diff(prof)) / np.maximum(1e-6, np.hypot(np.diff(sx), np.diff(sz)))
    gmax = math.degrees(math.atan(float(g.max()))) if g.size else 0.0
    im = int(g.argmax()) if g.size else 0
    flag = "" if gmax <= p["grade_max_deg"] + 0.5 else "  <-- dépasse %d° vers (%.0f, %.0f)" % (p["grade_max_deg"], sx[im], sz[im])
    say("  %-20s %-10s long. %4.0f m  de %5.2f à %5.2f m  pente maxi %4.1f°%s" % (p["id"], p["kind"], float(np.hypot(np.diff(sx), np.diff(sz)).sum()), prof[0], prof[-1], gmax, flag))

# sentiers : aucune cellule de sentier bloquée (paroi/eau) ?
on_path = path_dist <= 0
say("\ncellules de sentier non praticables (pente/eau/haie) : %d sur %d" % (int((on_path & ~walk).sum()), int(on_path.sum())))
say("surface praticable : %.0f %% de la zone ; parois (> 50°) : %.1f %% ; eau profonde : %.1f %%" % (100 * walk.mean(), 100 * (slope_deg > 50).mean(), 100 * deep.mean()))

# ------------------------------------------------------------------ dessin
PX = 8                            # px par mètre
IW, IH = W_M * PX, H_M * PX
LEG_W = 520
def font(sz, bold=False):
    for name in (("arialbd.ttf" if bold else "arial.ttf"), "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, sz)
        except Exception:
            pass
    return ImageFont.load_default()

def hillshade(h, az=315, alt=45):
    hx = np.zeros_like(h); hz = np.zeros_like(h)
    hx[:, 1:-1] = (h[:, 2:] - h[:, :-2]) / (2 * RES); hz[1:-1, :] = (h[2:, :] - h[:-2, :]) / (2 * RES)
    sl = np.arctan(np.hypot(hx, hz) * 1.0)
    asp = np.arctan2(-hz, hx)
    azr, altr = math.radians(360 - az + 90), math.radians(alt)
    sh = np.sin(altr) * np.cos(sl) + np.cos(altr) * np.sin(sl) * np.cos(azr - asp)
    return np.clip(sh, 0, 1)

def to_img(arr_rgb):
    return Image.fromarray(np.clip(arr_rgb, 0, 255).astype(np.uint8)).resize((IW, IH), Image.BILINEAR)

def ramp(h):
    """Couleur du sol selon la hauteur (vert prairie -> ocre -> roche -> neige)."""
    stops = [(-3, (40, 100, 150)), (0, (232, 212, 154)), (1, (150, 190, 95)), (3, (120, 175, 80)), (6, (150, 170, 80)), (10, (170, 150, 95)), (14, (160, 140, 110)), (24, (140, 130, 120)), (36, (235, 235, 240))]
    out = np.zeros(h.shape + (3,))
    for c in range(3):
        out[..., c] = np.interp(h, [s[0] for s in stops], [s[1][c] for s in stops])
    return out

def contours(img, h, step, colour, width=1, bold_every=None):
    d = ImageDraw.Draw(img)
    band = np.floor(h / step)
    edge = (band[:, 1:] != band[:, :-1])
    edge2 = (band[1:, :] != band[:-1, :])
    ys, xs_ = np.nonzero(edge)
    pts = [(int((x + 1) * RES * PX), int((y + 0.5) * RES * PX)) for y, x in zip(ys, xs_)]
    ys2, xs2 = np.nonzero(edge2)
    pts += [(int((x + 0.5) * RES * PX), int((y + 1) * RES * PX)) for y, x in zip(ys2, xs2)]
    d.point(pts, fill=colour)

def draw_poly(d, pts, **kw):
    d.polygon([(x * PX, z * PX) for x, z in pts], **kw)

def draw_line(d, pts, **kw):
    d.line([(x * PX, z * PX) for x, z in pts], **kw)

def base_image(relief_only=False):
    sh = hillshade(H)
    col = ramp(H) if not relief_only else np.full(H.shape + (3,), 225.0)
    if relief_only:
        col = ramp(H) * 0.25 + 170
    shade = (0.55 + 0.6 * sh)[..., None]
    rgb = col * shade
    # eau
    wmask = water_level > -50
    wcol = np.array([70, 140, 205.0])
    dep = np.clip(depth / 2.0, 0, 1)[..., None]
    wrgb = wcol * (1 - 0.35 * dep)
    rgb = np.where(wmask[..., None], wrgb, rgb)
    # parois
    cliff = slope_deg > 50
    rgb = np.where(cliff[..., None], rgb * 0.55 + np.array([60, 40, 25.0]) * 0.45, rgb)
    img = to_img(rgb)
    return img

def paste_legend(img, title, legend_rows):
    canvas = Image.new("RGB", (IW + LEG_W, IH), (248, 244, 232))
    canvas.paste(img, (0, 0))
    d = ImageDraw.Draw(canvas)
    f, fb, fs = font(17), font(19, True), font(14)
    d.rectangle([4, 4, 4 + d.textlength(title, font=fs) + 10, 26], fill=(255, 255, 255))
    d.text((9, 7), title, fill=(30, 20, 10), font=fs)
    y = 18
    d.text((IW + 18, y), "Légende", fill=(30, 20, 10), font=fb); y += 34
    for row in legend_rows:
        kind = row[0]
        x0 = IW + 18
        if kind == "title":
            y += 6; d.text((x0, y), row[1], fill=(30, 20, 10), font=fb); y += 30; continue
        if kind == "swatch":
            d.rectangle([x0, y + 2, x0 + 26, y + 20], fill=row[2], outline=(60, 40, 20))
        elif kind == "line":
            d.line([x0, y + 11, x0 + 26, y + 11], fill=row[2], width=row[3])
        elif kind == "dash":
            for k in range(0, 26, 8):
                d.line([x0 + k, y + 11, x0 + k + 4, y + 11], fill=row[2], width=row[3])
        elif kind == "circle":
            d.ellipse([x0 + 4, y + 2, x0 + 22, y + 20], fill=row[2], outline=(0, 0, 0))
            if len(row) > 3: d.text((x0 + 8, y + 3), row[3], fill=(255, 255, 255), font=fs)
        elif kind == "star":
            star(d, x0 + 13, y + 11, 10, row[2])
        elif kind == "diamond":
            d.polygon([(x0 + 13, y + 1), (x0 + 24, y + 11), (x0 + 13, y + 21), (x0 + 2, y + 11)], fill=row[2], outline=(0, 0, 0))
        elif kind == "text":
            d.text((x0, y), row[1], fill=(30, 20, 10), font=fs); y += 20; continue
        d.text((x0 + 36, y + 2), row[1], fill=(30, 20, 10), font=f)
        y += 26
    return canvas

def star(d, cx, cy, r, fill):
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        rr = r if k % 2 == 0 else r * 0.45
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(pts, fill=fill, outline=(0, 0, 0))

def grid(d, f):
    for mx in range(0, W_M + 1, 20):
        d.line([mx * PX, 0, mx * PX, IH], fill=(0, 0, 0, 0) if False else (90, 80, 70), width=1)
        d.text((mx * PX + 3, IH - 18), str(mx), fill=(40, 30, 20), font=f)
    for mz in range(0, H_M + 1, 20):
        d.line([0, mz * PX, IW, mz * PX], fill=(90, 80, 70), width=1)
        d.text((3, mz * PX + 2), str(mz), fill=(40, 30, 20), font=f)

AREA_COL = {"bois_du_port": (60, 110, 60), "seuil": (230, 200, 90), "vallee_ru": (110, 190, 190), "carrefour": (250, 230, 140), "prairie_voyageur": (200, 230, 120), "bois_chipie": (90, 150, 80), "lisiere_nord": (170, 200, 110), "encoche_grotte": (150, 140, 130), "colline_grotte": (190, 180, 120), "hauts_du_col": (205, 215, 150), "etang": (130, 200, 220), "prairie_elise": (235, 240, 170), "vertebres": (240, 220, 190), "parvis_crane": (250, 235, 200), "tertre_crane": (200, 170, 130), "eboulis_est": (190, 180, 170), "prairies_sud": (185, 225, 120), "bois_sud_est": (70, 120, 70), "crique": (240, 225, 170), "bois_crique": (100, 160, 90), "chemin_creux": (140, 120, 90), "bosquet_helene": (120, 180, 110), "lisiere_foret": (50, 90, 50), "vallon_des_nids": (210, 190, 140), "terrasses": (220, 200, 160)}

def render_plan():
    img = base_image().convert("RGBA")
    over = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    # secteurs : fond translucide + végétation (pointillé proportionnel à la canopée)
    rng = np.random.default_rng(3)
    for a in layout["areas"]:
        col = AREA_COL.get(a["id"], (200, 200, 200))
        draw_poly(d, a["polygon"], fill=col + (70,), outline=col + (200,), width=2)
        if "polygon2" in a:
            draw_poly(d, a["polygon2"], fill=col + (70,), outline=col + (200,), width=2)
        # arbres : points verts, densité = canopée
        for poly in ([a["polygon"]] + ([a["polygon2"]] if "polygon2" in a else [])):
            m = inside_polygon(poly) & ~(water_level > -50) & (slope_deg < 50)
            area_m2 = m.sum() * RES * RES
            n = int(area_m2 / 100.0 * a["vegetation"]["canopy"]["per_100m2"] * 0.5)   # la moitié des arbres, pour la lisibilité
            idx = np.flatnonzero(m)
            if n > 0 and idx.size:
                pick = rng.choice(idx, size=min(n, idx.size), replace=False)
                for q in pick:
                    j, i = divmod(int(q), NX)
                    cx, cy = (i + 0.5) * RES * PX, (j + 0.5) * RES * PX
                    d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(30, 90, 35, 200))
            n2 = int(area_m2 / 100.0 * a["vegetation"]["understory"]["per_100m2"] * 0.25)
            if n2 > 0 and idx.size:
                pick = rng.choice(idx, size=min(n2, idx.size), replace=False)
                for q in pick:
                    j, i = divmod(int(q), NX)
                    cx, cy = (i + 0.5) * RES * PX, (j + 0.5) * RES * PX
                    d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=(90, 140, 60, 180))
        # herbes hautes
        for tg in a.get("tall_grass", []):
            cx, cz = tg["center"]; rx, rz = tg["radii"]
            d.ellipse([(cx - rx) * PX, (cz - rz) * PX, (cx + rx) * PX, (cz + rz) * PX], fill=(60, 120, 40, 90), outline=(50, 100, 30, 220), width=2)
    img = Image.alpha_composite(img, over)
    d = ImageDraw.Draw(img)
    f, fb, fs, ft = font(15), font(17, True), font(13), font(12)
    # eau : ru
    for wb in layout["water"]:
        if wb["kind"] == "brook":
            draw_line(d, wb["points"], fill=(60, 130, 210), width=max(3, int(wb["width_m"] * PX)))
    # haies / talus / lisières denses
    for b in layout["blockers"]:
        if b["kind"] in ("hedge", "bank"):
            for key in ("polyline", "polyline2"):
                if key in b:
                    draw_line(d, b[key], fill=(40, 70, 30), width=int(b["width_m"] * PX))
        if b["kind"] == "forest_edge":
            for key in ("polygon", "polygon2"):
                if key in b:
                    draw_poly(d, b[key], fill=(30, 55, 30), outline=(20, 40, 20))
    # sentiers
    for p in PATHS:
        col = {"main": (205, 160, 90), "secondary": (215, 185, 130), "trail": (225, 205, 160)}[p["kind"]]
        wpx = max(3, int(p["width_m"] * PX))
        if p["kind"] == "main":
            draw_line(d, p["points"], fill=(120, 85, 40), width=wpx + 4)
            draw_line(d, p["points"], fill=col, width=wpx)
        else:
            pts = p["points"]
            # pointillé
            for i in range(len(pts) - 1):
                (x0, z0), (x1, z1) = pts[i], pts[i + 1]
                L = math.hypot(x1 - x0, z1 - z0); n = max(1, int(L / 2.5))
                for k in range(0, n, 2):
                    t0, t1 = k / n, min(1, (k + 1) / n)
                    d.line([(x0 + (x1 - x0) * t0) * PX, (z0 + (z1 - z0) * t0) * PX, (x0 + (x1 - x0) * t1) * PX, (z0 + (z1 - z0) * t1) * PX], fill=(110, 75, 35), width=wpx)
    # clairières
    for c in layout["clearings"]:
        cx, cz, r = c["center"][0] * PX, c["center"][1] * PX, c["radius"] * PX
        for k in range(0, 360, 20):
            a0, a1 = math.radians(k), math.radians(k + 10)
            d.arc([cx - r, cz - r, cx + r, cz + r], start=k, end=k + 10, fill=(255, 255, 255), width=2)
    # ancres
    for a in anchors:
        pts = []
        if "new" in a: pts = [a["new"]]
        elif "new_points" in a and a["kind"].startswith(("pebbles", "scene", "npc_path", "props")): pts = a["new_points"]
        elif "new_rect" in a and a["kind"].startswith(("exit", "moon", "islet")):
            r = a["new_rect"]; d.rectangle([r[0] * PX, r[1] * PX, (r[0] + r[2]) * PX, (r[1] + r[3]) * PX], outline=(220, 30, 30), width=3)
        if "new" in a and a.get("moved_m", 0) > 2 and a["kind"] not in ("spawn",):
            o, n = a["old"], a["new"]
            d.line([o[0] * PX, o[1] * PX, n[0] * PX, n[1] * PX], fill=(255, 120, 120), width=2)
            d.ellipse([o[0] * PX - 3, o[1] * PX - 3, o[0] * PX + 3, o[1] * PX + 3], outline=(255, 120, 120), width=2)
        peb = a["kind"].startswith("pebbles")
        for x, z in pts:
            if peb:
                d.ellipse([x * PX - 5, z * PX - 5, x * PX + 5, z * PX + 5], fill=(255, 190, 40), outline=(0, 0, 0))
            else:
                d.ellipse([x * PX - 6, z * PX - 6, x * PX + 6, z * PX + 6], fill=(225, 35, 35), outline=(255, 255, 255), width=2)
    # repères
    for lm in layout["landmarks"]:
        if lm["type"] == "backdrop": continue
        x, z = lm["at"]
        star(d, x * PX, z * PX, 16, (255, 220, 40))
        t = lm["name"]
        tw = d.textlength(t, font=fb)
        tx, ty = x * PX - tw / 2, z * PX + 18
        tx = min(max(2, tx), IW - tw - 2)
        d.rectangle([tx - 3, ty - 1, tx + tw + 3, ty + 20], fill=(255, 255, 255))
        d.text((tx, ty), t, fill=(30, 20, 10), font=fb)
    # vignettes
    for v in layout["vignettes"]:
        x, z = v["at"]
        d.polygon([(x * PX, z * PX - 11), (x * PX + 11, z * PX), (x * PX, z * PX + 11), (x * PX - 11, z * PX)], fill=(140, 60, 180), outline=(255, 255, 255))
        d.text((x * PX - 8, z * PX - 7), v["id"][1:], fill=(255, 255, 255), font=ft)
    # noms des secteurs
    for a in layout["areas"]:
        poly = np.array(a["polygon"]); cx, cz = poly.mean(axis=0)
        if a["id"] == "lisiere_foret": cx, cz = 12, 30
        if a["id"] == "crique": cx, cz = 28, 160
        if a["id"] == "bois_du_port": cx, cz = 100, 172
        if a["id"] == "eboulis_est": cx, cz = 228, 150
        if a["id"] == "corridor": cx, cz = 160, 68
        if a["id"] == "etang": cx, cz = 134, 134
        if a["id"] == "prairies_sud": cx, cz = 100, 146
        if a["id"] == "vertebres": cx, cz = 132, 113
        if a["id"] == "prairie_elise": cx, cz = 133, 148
        t = a["name"]
        tw = d.textlength(t, font=f)
        tx = min(max(2, cx * PX - tw / 2), IW - tw - 2)
        d.rectangle([tx - 3, cz * PX - 10, tx + tw + 3, cz * PX + 9], fill=(255, 255, 255))
        d.text((tx, cz * PX - 9), t, fill=(20, 40, 20), font=f)
    # flèches vers les voisines
    def arrow(x0, z0, x1, z1, label):
        d.line([x0 * PX, z0 * PX, x1 * PX, z1 * PX], fill=(200, 30, 30), width=6)
        ang = math.atan2(z1 - z0, x1 - x0)
        for s in (-1, 1):
            d.line([x1 * PX, z1 * PX, (x1 - 3 * math.cos(ang + s * 0.5)) * PX, (z1 - 3 * math.sin(ang + s * 0.5)) * PX], fill=(200, 30, 30), width=6)
        tw = d.textlength(label, font=fb)
        tx, tz = x0 * PX - tw / 2, z0 * PX - 24 if z1 > z0 else z0 * PX + 8
        if x1 < x0: tx, tz = x0 * PX + 6, z0 * PX - 10
        tx = min(max(2, tx), IW - tw - 2)
        d.rectangle([tx - 3, tz - 1, tx + tw + 3, tz + 20], fill=(255, 255, 255)); d.text((tx, tz), label, fill=(200, 30, 30), font=fb)
    arrow(120, 166, 120, 178, "→ Port-Ambre (sud)")
    arrow(14, 104, 2, 104, "→ Forêt Jurassique (ouest)")
    d.text((IW - 300, 8), "Monts à l'est : paroi (pas de passage)", fill=(120, 20, 20), font=fb)
    d.text((IW // 2 - 150, IH - 40), "", fill=(120, 20, 20), font=fb)
    grid(d, fs)
    legend = [("title", "Relief et eau"), ("swatch", "prairie 3 m → hauteurs (ocre, roche)", (150, 170, 80)), ("swatch", "paroi (pente > 50°) : roche, infranchissable", (95, 80, 60)), ("swatch", "eau (étang 2,4 m, mer 0 m) ; foncé = profond", (70, 140, 205)), ("line", "le ru (0,3 m, on y marche)", (60, 130, 210), 8),
              ("title", "Circulation"), ("line", "sentier principal (3 m, ocre)", (205, 160, 90), 8), ("dash", "sente (1,8 m) / piste (1,2 m)", (110, 75, 35), 5), ("line", "flèche : raccord avec la zone voisine", (200, 30, 30), 6),
              ("title", "Histoire"), ("circle", "ancre d'histoire (à sa nouvelle place)", (225, 35, 35)), ("circle", "galet caché (un arbre / une pierre ici)", (255, 190, 40)), ("line", "déplacement d'une ancre (ancienne place -> nouvelle)", (255, 120, 120), 2), ("swatch", "sortie / gué / îlot (cadre rouge)", (255, 255, 255)),
              ("title", "Décor"), ("star", "repère visible de loin", (255, 220, 40)), ("diamond", "vignette composée (numéro, voir plan.md)", (140, 60, 180)), ("dash", "clairière / zone calme (cercle blanc)", (255, 255, 255), 2), ("line", "haie de ronces, talus (infranchissable, visible)", (40, 70, 30), 8), ("swatch", "lisière dense (bord de zone)", (30, 55, 30)),
              ("title", "Végétation"), ("swatch", "secteur d'ambiance (teinte) et son nom", (200, 230, 120)), ("circle", "arbre (1 point = 2 arbres)", (30, 90, 35)), ("circle", "buissons (1 point = 4)", (90, 140, 60)), ("swatch", "herbes hautes (rencontres), sans décor", (60, 120, 40)),
              ("title", "Repère"), ("text", "x vers l'est, z vers le sud (origine au coin NO)"), ("text", "grille 20 m ; case 2,5D = (x/2, z/2)")]
    canvas = paste_legend(img.convert("RGB"), "Prairie du Grand Crâne — plan 3D (parti « l'amphithéâtre ») — 240 × 180 m", legend)
    canvas.save(os.path.join(OUT, "plaines-plan.png"))

def render_relief():
    img = base_image(relief_only=True)
    contours(img, H, 1.0, (120, 95, 60))
    contours(img, H, 5.0, (70, 45, 20))
    d = ImageDraw.Draw(img)
    f, fb, fs = font(15), font(16, True), font(13)
    # parois hachurées
    # eau
    draw_line(d, brook["points"], fill=(60, 130, 210), width=int(brook["width_m"] * PX))
    # rampes / carves : flèches
    for m in layout["relief"]["modifiers"]:
        if m["kind"] == "carve" and m.get("levels") and m["levels"][0] != m["levels"][1]:
            pts = m["points"]
            draw_line(d, pts, fill=(200, 60, 20), width=3)
            x0, z0 = pts[-2]; x1, z1 = pts[-1]
            if m["levels"][1] < m["levels"][0]:
                x0, z0, x1, z1 = pts[1][0], pts[1][1], pts[0][0], pts[0][1]
            ang = math.atan2(z1 - z0, x1 - x0)
            for s in (-1, 1):
                d.line([x1 * PX, z1 * PX, (x1 - 2 * math.cos(ang + s * 0.5)) * PX, (z1 - 2 * math.sin(ang + s * 0.5)) * PX], fill=(200, 60, 20), width=3)
            lab = "%s %.0f→%.0f m" % (m["id"], m["levels"][0], m["levels"][1])
            d.text((pts[0][0] * PX + 6, pts[0][1] * PX - 18), lab, fill=(150, 40, 10), font=fs)
    # cotes
    spots = [("mer 0", 20, 160), ("corridor 3", 160, 70), ("rampe", 146, 108), ("plage 0,6", 60, 140), ("crique", 44, 150), ("prairie 3", 100, 124), ("Seuil 6", 120, 156), ("cuvette 2,8", 140, 100), ("étang 2,4 (fond 1,2)", 134, 124), ("butte 4", 110, 99), ("bosquet 5", 34, 60), ("bois Chipie 4", 72, 64), ("Hauts du Col 5,5", 146, 40), ("colline 9,5", 114, 30), ("encoche 3,6", 116, 52), ("rempart 10", 200, 58), ("vallon 7", 200, 44), ("terrasse 10", 200, 32), ("poste 14", 196, 18), ("tertre 10", 190, 84), ("parvis 6,5", 172, 110), ("Monts 26+", 232, 100), ("montagnes 36", 120, 4), ("lisière 4", 10, 60), ("bois SE 4,6", 176, 148)]
    for t, x, z in spots:
        hv = float(sample(H, x, z))
        txt = "%s (%.1f)" % (t, hv)
        tw = d.textlength(txt, font=f)
        d.rectangle([x * PX - tw / 2 - 2, z * PX - 9, x * PX + tw / 2 + 2, z * PX + 9], fill=(255, 255, 255))
        d.text((x * PX - tw / 2, z * PX - 8), txt, fill=(60, 30, 10), font=f)
    for p in PATHS:
        if p["kind"] == "main":
            draw_line(d, p["points"], fill=(255, 255, 255), width=3)
    grid(d, fs)
    legend = [("title", "Relief prévu"), ("line", "courbe de niveau tous les 1 m", (120, 95, 60), 1), ("line", "courbe maîtresse tous les 5 m", (70, 45, 20), 2), ("swatch", "paroi (pente > 50°) : roche", (95, 80, 60)), ("swatch", "eau", (70, 140, 205)), ("line", "rampe / encoche creusée (de → à, en m)", (200, 60, 20), 3), ("line", "sentier principal (sol raboté, pente ≤ 12°)", (255, 255, 255), 3), ("text", "cote « nom N (h) » : hauteur visée (hauteur calculée)"), ("text", "ombrage : lumière du nord-ouest"), ("title", "Règles"), ("text", "pente praticable ≤ 42° ; sentiers ≤ 12°"), ("text", "jamais de marche : Terrain3D lisse (0,5 m)"), ("text", "les parois sont peintes roche + strates"), ("text", "hauteur = m au-dessus de la mer (0)")]
    canvas = paste_legend(img, "Prairie du Grand Crâne — relief prévu (Terrain3D) — courbes 1 m / 5 m", legend)
    canvas.save(os.path.join(OUT, "plaines-plan-relief.png"))

render_plan()
render_relief()
# carte de praticabilité (contrôle)
dbg = np.zeros(H.shape + (3,), dtype=np.uint8)
dbg[..., 1] = np.where(seen_open, 200, 60)
dbg[..., 0] = np.where(~walk, 200, 0)
dbg[..., 2] = np.where(water_level > -50, 200, 0)
ctrl = Image.fromarray(dbg).resize((IW // 2, IH // 2), Image.NEAREST)
dc = ImageDraw.Draw(ctrl)
for aid, at in anchor_points():
    dc.ellipse([at[0] * 4 - 3, at[1] * 4 - 3, at[0] * 4 + 3, at[1] * 4 + 3], fill=(255, 255, 0))
ctrl.save(os.path.join(OUT, "_controle_praticabilite.png"))
# export du champ de hauteurs (16 bits, 0,5 m) pour l'agent relief
h16 = np.clip((H + 10.0) * 1000.0, 0, 65535).astype(np.uint16)
Image.fromarray(h16).save(os.path.join(OUT, "plaines-relief-cible.png"))
open(os.path.join(OUT, "_verification.txt"), "w", encoding="utf-8").write("\n".join(report))
print("images écrites dans", OUT)

# --- débogage : profil le long de x = 186 (gorge) et de x = 206 (terrasse)
if os.environ.get("DBG"):
    for xq in (186.0, 206.0):
        print("x =", xq)
        for zq in np.arange(14, 92, 2.0):
            i, j = int(xq / RES), int(zq / RES)
            print("  z %5.1f  h %6.2f  pente %5.1f  walk %s  deep %s" % (zq, H[j, i], slope_deg[j, i], walk[j, i], deep[j, i]))
if os.environ.get("DBG2"):
    m_dbg = erode(walk)
    for zq in np.arange(112, 134, 1.0):
        row = ""
        for xq in np.arange(120, 149, 1.0):
            i, j = int(xq / RES), int(zq / RES)
            row += ("#" if m_dbg[j, i] else ("." if walk[j, i] else ("~" if deep[j, i] else "x")))
        print("z %5.1f %s  h(134)=%.2f d=%.2f s=%.0f" % (zq, row, H[int(zq / RES), 268], depth[int(zq / RES), 268], slope_deg[int(zq / RES), 268]))
