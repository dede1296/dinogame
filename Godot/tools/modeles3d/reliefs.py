"""Reliefs 3D des décors fixes : chaque image de décor (assets/art/props/<sorte>.png) devient un
maillage qui garde exactement l'image vue de face, creusé selon une carte de profondeur
estimée par Depth Anything 3 (ComfyUI). Voir docs/direction-artistique.md, « Décors en relief ».

  python reliefs.py prep     images de travail (sur gris) + workflow ComfyUI de profondeur
  (lancer le workflow dans ComfyUI : tools/modeles3d/profondeur_comfyui.json)
  python reliefs.py collect  copie les profondeurs de ComfyUI dans profondeurs/ (versionnées)
  python reliefs.py build [sorte…]  maillages assets/models/reliefs/<sorte>.obj (+ planche)
  python reliefs.py normals [sorte…]  cartes de normales <sorte>_n.png et d'occlusion <sorte>_ao.png

Python de ComfyUI (numpy, scipy, PIL) : C:\\ComfyUI_windows_portable\\python_embeded\\python.exe
Les sortes qui bougent (sway > 0, flottantes) et celles qui ont un vrai modèle ("model")
gardent leur image.
"""
import glob, json, math, os, re, shutil, sys
import numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt, gaussian_filter as gauss, grey_closing   # (normals)

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.normpath(os.path.join(HERE, "..", ".."))
ART = os.path.join(GODOT, "assets", "art", "props")
OUT = os.path.join(GODOT, "assets", "models", "reliefs")
DEPTHS = os.path.join(HERE, "profondeurs")
COMFY = "C:/ComfyUI_windows_portable/ComfyUI"
PX = 48.0                  # px 2D par mètre (une case)
STRETCH = 1.15             # comme les images (world_view.gd)
PLAYER_RADIUS = 11.0 / PX  # actors/player.tscn
SLOPE = 1.0                # pente max d'un relief (45°) : pas de flancs étirés
# Profondeur totale d'un objet, en fraction de sa largeur (défaut 0,6).
DEPTH = {
    # plats : panneaux, murs, portes, grilles
    "panneau": 0.12, "cloture": 0.12, "palissade": 0.15, "fresque": 0.12, "mur_cabinet": 0.15, "mur_fissure": 0.2,
    "porte_ambre": 0.18, "porte_temple": 0.2, "porte_vents": 0.2, "barreaux_cage": 0.08, "passerelle": 0.12,
    "ecaille": 0.15, "serrure": 0.3, "bibliotheque": 0.3, "rempart_eboulis": 0.35, "arche_rocheuse": 0.3,
    "vanne": 0.35, "ancre": 0.3, "banc": 0.4, "totem_vents": 0.4, "racines": 0.4,
    # pleins et ronds
    "rocher": 0.7, "rocher_mousse": 0.7, "rocher_grotte": 0.7, "rocher_canyon": 0.65, "cailloux": 0.6,
    "galet": 0.6, "monticule": 0.6, "souche": 0.75, "souche_geante": 0.7, "tonneau": 0.8, "bitte": 0.8,
    "colonne": 0.8, "puits_oasis": 0.8, "socle": 0.8, "caisses": 0.75, "casiers": 0.7, "caisse_ambre_noir": 0.8,
    "stalagmite": 0.7, "cristaux": 0.6, "tente": 0.8, "tente_nomade": 0.8,
    # bâtiments
    "maison_blanche": 0.7, "maison_jaune": 0.7, "maison_port": 0.7, "cabinet": 0.7, "cabane_pilotis": 0.7,
}
ROUNDNESS_DEFAULT = 0.6


def kinds_def():
    src = open(os.path.join(GODOT, "world", "prop.gd"), encoding="utf-8").read()
    out = {}
    for k, body in re.findall(r'^\t"(\w+)": \{([^}]*)\}', src, re.M):
        num = lambda key: float(re.search(r'"%s": ([\d.]+)' % key, body).group(1))
        solid = re.search(r'"solid": (Vector2\(([\d.]+), ([\d.]+)\)|[\d.]+)', body)
        out[k] = {
            "scale": num("scale"), "foot": num("foot"), "sway": num("sway"),
            "float": '"float": true' in body, "model": '"model"' in body,
            "solid": (float(solid.group(2)), float(solid.group(3))) if solid.group(2) else float(solid.group(1)),
        }
    return out


def fixed_kinds(defs):
    return [k for k, d in defs.items() if d["sway"] == 0 and not d["float"] and not d["model"]
            and os.path.exists(os.path.join(ART, k + ".png"))]


# ------------------------------------------------------------------ prep / collect
def prep(kinds):
    wf = {"1": {"class_type": "LoadDA3Model", "inputs": {"model_name": "depth_anything_3_mono_large.safetensors",
                                                          "weight_dtype": "fp32"}}}   # fp16 : cartes vides
    n = 10
    for k in kinds:
        im = Image.open(os.path.join(ART, k + ".png")).convert("RGBA")
        bg = Image.new("RGB", im.size, (200, 200, 200))
        bg.paste(im, mask=im.split()[3])
        bg.save(os.path.join(COMFY, "input", "relief_" + k + ".png"))
        wf[str(n)] = {"class_type": "LoadImage", "inputs": {"image": "relief_" + k + ".png"}}
        wf[str(n + 1)] = {"class_type": "DA3Inference", "inputs": {"da3_model": ["1", 0], "image": [str(n), 0],
                          "resolution": 504, "resize_method": "upper_bound_resize", "mode": "mono"}}
        wf[str(n + 2)] = {"class_type": "DA3Render", "inputs": {"da3_geometry": [str(n + 1), 0], "output": "depth",
                          "output.normalization": "min_max", "output.apply_sky_clip": False}}
        wf[str(n + 3)] = {"class_type": "SaveImage", "inputs": {"images": [str(n + 2), 0],
                          "filename_prefix": "relief/" + k}}
        n += 10
    path = os.path.join(HERE, "profondeur_comfyui.json")
    json.dump(wf, open(path, "w"), indent=1)
    print("workflow :", path, "(%d sortes)" % len(kinds))


def collect(kinds):
    os.makedirs(DEPTHS, exist_ok=True)
    for k in kinds:
        found = sorted(glob.glob(os.path.join(COMFY, "output", "relief", k + "_*.png")))
        if found:   # gris 8 bits, 320 px au plus : assez pour une grille de 44 cases
            im = Image.open(found[-1]).convert("L")
            im.thumbnail((320, 320), Image.LANCZOS)
            im.save(os.path.join(DEPTHS, k + ".png"), optimize=True)
        else:
            print("pas de profondeur :", k)


# ------------------------------------------------------------------ build
def blur(a, r):
    """Flou gaussien séparable (r en px)."""
    if r < 0.5:
        return a
    x = np.arange(-int(3 * r), int(3 * r) + 1)
    g = np.exp(-x * x / (2 * r * r))
    g /= g.sum()
    a = np.apply_along_axis(lambda m: np.convolve(m, g, mode="same"), 0, a)
    return np.apply_along_axis(lambda m: np.convolve(m, g, mode="same"), 1, a)


def shift(a, dy, dx, fill):
    out = np.full_like(a, fill)
    h, w = a.shape
    out[max(dy, 0):h + min(dy, 0), max(dx, 0):w + min(dx, 0)] = a[max(-dy, 0):h + min(-dy, 0), max(-dx, 0):w + min(-dx, 0)]
    return out


def front_clearance(solid):
    """Jusqu'où le relief peut avancer vers la caméra sans toucher Chloé (m)."""
    if isinstance(solid, tuple):
        return 6.0 / PX + PLAYER_RADIUS          # boîte : son bord avant est à +6 px (prop.gd)
    if solid > 0:
        return solid / PX + PLAYER_RADIUS
    return 0.12                                  # on marche au travers : presque plat devant


def depth_m(k, inside, w_m):
    """Profondeur par pixel de l'image (m, + = vers la caméra), le pied sur le plan de l'image ;
    aussi la bande du pied et la profondeur totale de l'objet (m)."""
    H, W = inside.shape
    depth = np.asarray(Image.open(os.path.join(DEPTHS, k + ".png")).convert("L").resize((W, H), Image.BILINEAR),
                       dtype=np.float32) / 255.0
    # Profondeur lissée sans baver sur le fond (convolution normalisée), puis 0..1 dans l'objet.
    r = max(W, H) * 0.012
    wgt = blur(inside.astype(np.float32), r)
    dn = blur(depth * inside, r) / np.maximum(wgt, 1e-4)
    lo, hi = np.percentile(dn[inside], 2), np.percentile(dn[inside], 98)
    dn = np.clip((dn - lo) / max(hi - lo, 1e-4), 0.0, 1.0)
    # Référence : le pied de l'objet (bande du bas, au milieu) reste sur le plan de l'image.
    ys, xs = np.nonzero(inside)
    y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
    band = inside.copy()
    band[: int(y1 - 0.06 * (y1 - y0))] = False
    cx, half = (x0 + x1) / 2, 0.2 * (x1 - x0)
    band[:, : int(cx - half)] = False
    band[:, int(cx + half) + 1:] = False
    dref = np.median(dn[band]) if band.any() else np.median(dn[inside])
    total = DEPTH.get(k, 0.6) * w_m
    return (dn - dref) * total, band, total


def build_one(k, d):
    im = Image.open(os.path.join(ART, k + ".png")).convert("RGBA")
    W, H = im.size
    alpha = np.asarray(im, dtype=np.float32)[..., 3] / 255.0
    m = d["scale"] / PX
    w_m, h_m = W * m, H * m
    inside = alpha > 0.5
    z_px, band, total = depth_m(k, inside, w_m)
    # Grille : ~10 cases par mètre, 14 à 44 sur le grand côté.
    L = max(w_m, h_m * STRETCH)
    n_long = int(np.clip(round(L * 10), 14, 44))
    nx, ny = max(4, round(n_long * w_m / L)), max(4, round(n_long * h_m * STRETCH / L))
    gx = np.linspace(0, W - 1, nx + 1)
    gy = np.linspace(0, H - 1, ny + 1)
    ix, iy = np.meshgrid(gx.round().astype(int), gy.round().astype(int))
    z = z_px[iy, ix]
    # Couverture : l'image occupe-t-elle les alentours du sommet (une case autour) ?
    cov_img = blur(alpha, max(W / nx, H / ny) * 0.5)
    cov = cov_img[iy, ix]
    core = inside[iy, ix]
    # Hors de l'objet (bord de la grille) : la profondeur du voisin intérieur le plus proche.
    known = core.copy()
    for _ in range(nx + ny):
        if known.all():
            break
        acc = np.zeros_like(z); cnt = np.zeros_like(z)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            k2 = shift(known, dy, dx, False)
            acc += np.where(k2, shift(z, dy, dx, 0.0), 0.0); cnt += k2
        new = ~known & (cnt > 0)
        z[new] = acc[new] / cnt[new]
        known |= new
    # Pas plus près de la caméra que la collision ne le permet (douce), pas plus loin que la profondeur.
    fc = front_clearance(d["solid"])
    z = np.where(z > 0, fc * np.tanh(z / fc), np.maximum(z, -total))
    # Pente limitée : les bords proches s'arrondissent au lieu de former des parois étirées.
    sx, sy = w_m / nx, h_m * STRETCH / ny
    for _ in range(max(nx, ny)):
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            step = math.hypot(dx * sx, dy * sy)
            z = np.minimum(z, shift(z, dy, dx, np.inf) + SLOPE * step)
    # Un léger lissage final (normales plus douces).
    zb = np.pad(z, 1, mode="edge")
    z = 0.5 * z + 0.125 * (zb[2:, 1:-1] + zb[:-2, 1:-1] + zb[1:-1, 2:] + zb[1:-1, :-2])
    # La pente limitée tire les objets fins vers l'arrière : le pied revient sur le plan de l'image.
    foot = band[iy, ix]
    if foot.any():
        z -= np.median(z[foot])
        z = np.where(z > 0, fc * np.tanh(z / fc), z)
    # Sommets, normales, triangles (seulement là où il y a de l'image).
    X = (ix / (W - 1) - 0.5) * w_m
    Y = ((1.0 - iy / (H - 1)) - d["foot"]) * h_m * STRETCH
    zp = np.pad(z, 1, mode="edge")
    dzdx = (zp[1:-1, 2:] - zp[1:-1, :-2]) / (2 * sx)
    dzdy = -(zp[2:, 1:-1] - zp[:-2, 1:-1]) / (2 * sy)      # la grille descend, Y monte
    nrm = np.dstack([-dzdx, -dzdy, np.ones_like(z)])
    nrm /= np.linalg.norm(nrm, axis=2, keepdims=True)
    used = np.zeros(z.shape, bool)
    quads = []
    for j in range(ny):
        for i in range(nx):
            if max(cov[j, i], cov[j, i + 1], cov[j + 1, i], cov[j + 1, i + 1]) > 0.02:
                quads.append((j, i))
                used[j:j + 2, i:i + 2] = True
    index = -np.ones(z.shape, int)
    index[used] = np.arange(1, used.sum() + 1)
    lines = ["# relief de %s (tools/modeles3d/reliefs.py)" % k]
    for j, i in zip(*np.nonzero(used)):
        lines.append("v %.4f %.4f %.4f" % (X[j, i], Y[j, i], z[j, i]))
    for j, i in zip(*np.nonzero(used)):
        lines.append("vt %.5f %.5f" % (ix[j, i] / (W - 1), 1.0 - iy[j, i] / (H - 1)))
    for j, i in zip(*np.nonzero(used)):
        lines.append("vn %.4f %.4f %.4f" % tuple(nrm[j, i]))
    for j, i in quads:
        a, b, c, e = index[j + 1, i], index[j + 1, i + 1], index[j, i + 1], index[j, i]   # bas-g, bas-d, haut-d, haut-g
        lines.append("f %d/%d/%d %d/%d/%d %d/%d/%d" % (a, a, a, b, b, b, c, c, c))
        lines.append("f %d/%d/%d %d/%d/%d %d/%d/%d" % (a, a, a, c, c, c, e, e, e))
    os.makedirs(OUT, exist_ok=True)
    open(os.path.join(OUT, k + ".obj"), "w").write("\n".join(lines) + "\n")
    inner = core & (cov > 0.5)
    return {"sommets": int(used.sum()), "triangles": 2 * len(quads), "grille": [nx, ny],
            "avant_m": round(float(z[inner].max()), 2) if inner.any() else 0,
            "arriere_m": round(float(-z[inner].min()), 2) if inner.any() else 0,
            "largeur_m": round(w_m, 2), "hauteur_m": round(h_m * STRETCH, 2)}


# ------------------------------------------------------------------ normals
# Cartes de normales (« Relief v2 ») : assets/models/reliefs/<sorte>_n.png, même taille que l'image,
# dans le repère de l'image (R = +X à droite, G = +Y en haut, B = +Z vers la caméra, comme OpenGL),
# fond (alpha < 0,5) = (128,128,255). Elles portent toute la normale : la forme (la profondeur,
# comme build_one, mais à la finesse de l'image) et les détails dessinés (joints, planches, tuiles,
# fissures) que le maillage (~10 cases/m) ne porte pas. Plus <sorte>_ao.png : l'ombre des creux
# (255 = aucune). Il faut scipy (fourni avec le Python de ComfyUI).
# Poids des détails tirés de l'image (défaut 1) : pierre, bois, tuiles forts ; lisse faible.
DETAIL = {
    # lisses : ambre, verre, métal poli, os, champignons, tissu
    "ambre": 0.3, "ecaille": 0.25, "galet": 0.35, "lampe": 0.45, "lanterne": 0.6, "couveuse": 0.45,
    "champignons": 0.5, "cristaux": 0.6, "feu_camp": 0.6, "os_dino": 0.6, "os_geant": 0.7, "grand_crane": 0.75,
    "crane_geant_desert": 0.75, "tente": 0.7, "tente_nomade": 0.6, "fauteuil": 0.8, "monticule": 0.6,
    "nid_oviraptor": 0.7,
    # pierre, bois, tuiles, briques
    "maison_blanche": 1.3, "maison_jaune": 1.2, "maison_port": 1.3, "cabinet": 1.3, "cabane_pilotis": 1.3,
    "caisses": 1.3, "caisse_ambre_noir": 1.3, "tonneau": 1.2, "palissade": 1.2, "cloture": 1.2, "banc": 1.2,
    "panneau": 1.2, "passerelle": 1.2, "porte_temple": 1.3, "porte_ambre": 1.3, "porte_vents": 1.3,
    "fresque": 1.3, "rocher_canyon": 1.3, "arche_rocheuse": 1.2, "rempart_eboulis": 1.2, "mur_fissure": 1.3,
    "colonne": 1.2, "puits_oasis": 1.3, "vanne": 1.2, "statue_dino": 1.2, "totem_vents": 1.2, "socle": 1.2,
    "serrure": 1.1, "souche": 1.2, "souche_geante": 1.2, "tronc": 1.2, "tronc_mousse": 1.2, "racines": 1.2,
    "rocher": 1.1, "rocher_grotte": 1.1, "rocher_mousse": 1.1, "cailloux": 1.1, "mur_cabinet": 1.2,
}
DETAIL_DEFAULT = 1.0
INK_R = 2.5          # rayon (px × finesse) au-delà duquel un aplat sombre n'est plus un trait
SHAPE_R = 2.5        # lissage de la forme (px, × finesse) : les paliers de la profondeur 8 bits
BEVELS = ((1.5, 1.3), (4.0, 1.0))   # (rayon px × finesse, pente) des chanfreins le long des traits
LUMA = (0.7, 4.0, 4.0)              # passe-bande de la luminance (rayons px × finesse) et gain (px)
MAX_TILT = 1.6       # pente max de la normale finale (58°)
AO_RADII = (0.04, 0.12, 0.3)   # m : joints, recoins, creux (sous un balcon, une gueule)
AO_GAIN, AO_MIN = 1.2, 0.5


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def soft_clamp(gx, gy, limit):
    """Pente (gx, gy) bornée en douceur à `limit`."""
    g = np.hypot(gx, gy)
    s = limit * np.tanh(g / limit) / np.maximum(g, 1e-6)
    return gx * s, gy * s


def mblur(a, fin, r):
    """Flou dans l'objet seulement (convolution normalisée) : le fond ne bave pas sur le bord."""
    return gauss(a * fin, r) / np.maximum(gauss(fin, r), 1e-4)


def detail_height(rgb, inside, f):
    """Relief fin tiré du dessin (px de haut) : les traits sombres sont des creux, chanfreinés
    de part et d'autre (planches, joints, tuiles, fissures) ; le clair ressort un peu."""
    fin = inside.astype(np.float32)
    L = rgb @ np.array([0.299, 0.587, 0.114], np.float32)
    # Trait = plus sombre que la fermeture de l'image (un petit disque) : seulement les traits fins
    # et les joints ; les aplats sombres plus larges (mousse, taches, volets) ne sont pas des trous.
    Ls = np.where(inside, mblur(L, fin, 0.6 * f), 1.0)
    rd = max(2, int(round(INK_R * f)))
    yy, xx = np.mgrid[-rd:rd + 1, -rd:rd + 1]
    shut = grey_closing(Ls, footprint=xx * xx + yy * yy <= rd * rd + rd)
    ink = np.maximum(smoothstep(0.04, 0.3, (shut - Ls) / (shut + 0.05)), 0.8 * smoothstep(0.12, 0.05, Ls))
    solid = np.where(inside, 1.0 - ink, 0.0)
    # Chanfreins : une marche 0 -> 1 floutée de rayon r, haute de 2,5 r, a la pente voulue.
    h = sum(slope * 2.5 * r * f * gauss(solid, r * f) for r, slope in BEVELS)
    r1, r2, gain = LUMA
    return h + gain * f * (mblur(L, fin, r1 * f) - mblur(L, fin, r2 * f))


def occlusion(zt, fin, m):
    """Ombre des creux (1 = aucune) : ce qui est plus bas que ses alentours (à chaque rayon, en m) ;
    près du bord de l'image, le fond est ouvert (pondéré par la part d'objet autour)."""
    occl = 0.0
    for r in AO_RADII:
        cov = gauss(fin, r / m)
        around = gauss(zt * fin, r / m) / np.maximum(cov, 1e-4)
        occl = occl + np.clip((around - zt) / r, 0.0, 1.0) * cov * cov
    return np.clip(1.0 - AO_GAIN * occl / len(AO_RADII), AO_MIN, 1.0)


def normal_maps(k, d):
    """Normales (H×W×3, repère de l'image) et occlusion (H×W, 1 = aucune) d'une sorte."""
    im = np.asarray(Image.open(os.path.join(ART, k + ".png")).convert("RGBA"), dtype=np.float32) / 255.0
    H, W = im.shape[:2]
    inside = im[..., 3] > 0.5
    fin = inside.astype(np.float32)
    m = d["scale"] / PX
    f = float(np.clip(max(W, H) / 420.0, 0.75, 2.5))   # finesse du dessin (épaisseur des traits)

    def slopes(z_m):     # pentes en m/m d'une hauteur en m par pixel (Y en haut, image étirée)
        gy, gx = np.gradient(z_m)
        return gx / m, -gy / (m * STRETCH)

    # Forme : la profondeur de build_one, bornée devant comme le maillage, lissée, pente ≤ 45°.
    z, _, total = depth_m(k, inside, W * m)
    fc = front_clearance(d["solid"])
    z = np.where(z > 0, fc * np.tanh(z / fc), np.maximum(z, -total))
    z = mblur(z, fin, SHAPE_R * f)
    sx, sy = soft_clamp(*slopes(z), SLOPE)
    # Détails, en m, ajoutés à la pente de la forme.
    h_m = detail_height(im[..., :3], inside, f) * m * DETAIL.get(k, DETAIL_DEFAULT)
    dx, dy = slopes(h_m)
    nx, ny = soft_clamp(sx + dx, sy + dy, MAX_TILT)
    n = np.dstack([-nx, -ny, np.ones_like(nx)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    n[~inside] = (0.0, 0.0, 1.0)
    # Pas d'ombre sur le trait du contour (il n'y a rien derrière) : elle s'efface au bord.
    edge = smoothstep(1.0 * f, 4.0 * f, distance_transform_edt(inside))
    ao = 1.0 - (1.0 - occlusion(z + h_m, fin, m)) * edge
    return n, ao, inside


def save_normals(k, d):
    """Écrit <sorte>_n.png (RGB 8 bits) et <sorte>_ao.png (gris 8 bits)."""
    n, ao, inside = normal_maps(k, d)
    rgb = np.clip(np.round((n * 0.5 + 0.5) * 255.0), 0, 255).astype(np.uint8)
    rgb[~inside] = (128, 128, 255)
    Image.fromarray(rgb, "RGB").save(os.path.join(OUT, k + "_n.png"), optimize=True)
    Image.fromarray(np.round(ao * 255.0).astype(np.uint8), "L").save(os.path.join(OUT, k + "_ao.png"), optimize=True)


def preview(kinds, path):
    """Planche : l'image et sa profondeur de relief (clair = vers la caméra)."""
    cell = 180
    cols = 8
    rows = math.ceil(len(kinds) / cols) * 2
    board = Image.new("RGB", (cols * cell, rows * cell), (35, 35, 35))
    for n, k in enumerate(kinds):
        im = Image.open(os.path.join(ART, k + ".png")).convert("RGBA")
        dp = Image.open(os.path.join(DEPTHS, k + ".png")).convert("L").resize(im.size)
        a = im.split()[3]
        dp = Image.composite(dp, Image.new("L", im.size, 0), a)
        for row, pic in ((0, im), (1, dp.convert("RGB"))):
            t = pic.copy(); t.thumbnail((cell - 8, cell - 8))
            bg = Image.new("RGB", t.size, (90, 120, 80))
            bg.paste(t, mask=t.split()[3] if t.mode == "RGBA" else None)
            board.paste(bg, ((n % cols) * cell + 4, ((n // cols) * 2 + row) * cell + 4))
    board.save(path)


if __name__ == "__main__":
    defs = kinds_def()
    todo = fixed_kinds(defs)
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    if cmd == "normals":   # aussi le relief resté d'une sorte passée depuis en vrai modèle (secours)
        made = [os.path.basename(p)[:-4] for p in glob.glob(os.path.join(OUT, "*.obj"))]
        todo += sorted(k for k in made if k in defs and k not in todo)
    if len(sys.argv) > 2:
        todo = [k for k in sys.argv[2:] if k in todo]
    if cmd == "prep":
        prep(todo)
    elif cmd == "collect":
        collect(todo)
    elif cmd == "build":
        todo = [k for k in todo if os.path.exists(os.path.join(DEPTHS, k + ".png"))]
        info = {k: build_one(k, defs[k]) for k in todo}
        json.dump(info, open(os.path.join(OUT, "_reliefs.json"), "w"), indent=1, ensure_ascii=False)
        for k, v in info.items():
            print("%-20s %5d tri  grille %2dx%-2d  %.1f m × %.1f m  avant %.2f  arrière %.2f" % (
                k, v["triangles"], v["grille"][0], v["grille"][1], v["largeur_m"], v["hauteur_m"], v["avant_m"], v["arriere_m"]))
        print("total", sum(v["triangles"] for v in info.values()), "triangles,", len(info), "sortes")
    elif cmd == "normals":
        todo = [k for k in todo if os.path.exists(os.path.join(DEPTHS, k + ".png"))]
        os.makedirs(OUT, exist_ok=True)
        for k in todo:
            save_normals(k, defs[k])
        print(len(todo), "cartes de normales et d'occlusion dans", OUT)
