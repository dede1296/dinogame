"""Bâtiments « assemblés » en vraie 3D (maison_blanche, maison_jaune, maison_port, cabinet,
cabane_pilotis) : un modèle simple et propre construit dans Blender aux proportions mesurées sur
des vues dessinées (face, côté droit, dos), chaque face peinte par le morceau de la vue qui la
montre (projection orthographique, sous l'élévation propre à chaque vue), plus une carte de
normales tirée des dessins (méthode de reliefs.py). Remplace, pour ces bâtiments, la
reconstruction Hunyuan3D de volumes_blender.py (toits déformés, peinture étirée). Réglages par
sorte (dimensions mesurées sur les vues, calage, retouches) : maisons.json (clé "_aide").

Usage (vues : generated_imgs/vues/<sorte>_face|cote|dos.png, même échelle en px/m) :
  python maisons.py textures <sorte>       (Python de ComfyUI : numpy, scipy, PIL)
      chaque vue -> vue_<v>.png (retouches « effacer »), tex_<v>.png (contour brun extérieur
      rongé, couleurs étendues au-delà), haut_<v>.png (relief des détails, 16 bits) ; variantes
      _toit / _murs (cheminée peinte sur le toit, balcon devant les fenêtres : remplacés par le
      dessin voisin, « toit_sans » / « murs_sans ») ; motifs répétés (« tuiles ») pour les dessus
      qu'aucune vue ne montre (terrasse, plancher, dessus du cristal).
  blender -b -P maisons.py -- calage <sorte>
      modèle grossier ; pour chaque vue, l'élévation (theta), le décalage (échelle du jeu : 48/scale
      px par m) qui recouvrent le mieux la vue (IoU de silhouette) -> calage.json ; arêtes du modèle
      tracées sur chaque vue : calage_<v>.png.
  blender -b -P maisons.py -- bake <sorte>
      modèle fin (coins arrondis, murs bosselés, biseaux) ; atlas UV 2048 ; cuisson Cycles (CPU) de
      la peinture (projections des vues), des normales (relief des vues en bosselage) et d'une
      occlusion légère ; export assets/models/volumes/<sorte>.glb (une surface, baseColor +
      normalTexture, tangentes ; Y en haut, façade vers +Z, origine au pied de façade).
  blender -b -P maisons.py -- rendus <sorte>
      rendus du glb : calés sur chaque vue, caméra du jeu (0°/40°), ±45°/35°, 90°/20°, 180°/30°.
  blender -b -P maisons.py -- tout <sorte>      (calage, bake, rendus)
      (le bake ajuste d'abord le maillage à la silhouette et aux lignes des dessins : ajuste.py)
  blender -b -P maisons.py -- ajuste <sorte>    contrôle rapide de l'ajustement, sans cuisson :
      ajuste_contour_<v>.png (contour du modèle ajusté sur chaque vue), ajuste_<v>.png (champs)
  python maisons.py planche <sorte>        planche generated_imgs/captures/maisons_assemblees_<sorte>.png
  python maisons.py vues <sorte>           côté et dos composés depuis la face (réglage "depuis_face" ;
                                           maisons simples sans dessin de côté ni de dos)
Intérieurs des ouvertures (réglages « pieces », tente.interieur ; interieurs.py) :
  blender -b -P maisons.py -- guide <sorte>     guide de la peinture ComfyUI de chaque pièce
  python maisons.py peindre <sorte> [clé]       peinture ComfyUI (img2img du guide) ; puis bake
  blender -b -P maisons.py -- rendus_interieurs <sorte>   contrôles de face, de 3/4, caméra du jeu
  python maisons.py planche_interieurs [sortes…]   generated_imgs/captures/interieurs_ouvertures.png

Dossier de travail (hors dépôt) : C:/ComfyUI_windows_portable/blender_tests/maisons/<sorte>/.
Puis dans world/prop.gd (Prop.KINDS) : "model" et "solid" (bake l'affiche), import Godot.
"""
import json, math, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.normpath(os.path.join(HERE, "..", ".."))
VUES = "C:/Users/Greg/Dinogame/generated_imgs/vues"
CAPTURES = "C:/Users/Greg/Dinogame/generated_imgs/captures"
WORK_ROOT = "C:/ComfyUI_windows_portable/blender_tests/maisons"
PX = 48.0                 # px 2D par mètre
VIEWS = ("face", "cote", "dos")
ERODE_FRAC = 6.0 / 453    # contour brun extérieur rongé : 6 px pour un dessin de 453 px
FRONT_CLEAR = 6.0 / PX    # bord avant de la collision d'un décor (prop.gd) devant l'origine

try:
    import bpy, bmesh
    import numpy as np
    from mathutils import Vector, noise
    IN_BLENDER = True
except ImportError:
    IN_BLENDER = False


def config(kind):
    return json.load(open(os.path.join(HERE, "maisons.json"), encoding="utf-8"))[kind]


def kind_scale(kind):
    src = open(os.path.join(GODOT, "world", "prop.gd"), encoding="utf-8").read()
    found = re.search(r'^\t"%s": \{(.*?)\}' % kind, src, re.M | re.S)
    if found is None:   # (pas encore dans Prop.KINDS : l'échelle prévue de l'image, maisons.json « scale_jeu »)
        return float(config(kind)["scale_jeu"])
    return float(re.search(r'"scale": ([\d.]+)', found.group(1)).group(1))


def work_dir(kind):
    d = os.path.join(WORK_ROOT, kind)
    os.makedirs(d, exist_ok=True)
    return d


# ================================================================== hors Blender (PIL, scipy)
def pil_textures(kind):
    import numpy as np
    from PIL import Image
    from scipy import ndimage
    sys.path.insert(0, HERE)
    from reliefs import detail_height, DETAIL, DETAIL_DEFAULT
    cfg, work = config(kind), work_dir(kind)
    info = {}
    tent = "tente" in cfg
    if tent or "pieux" in cfg:   # tente, palissade : leur seule vue est le dessin du jeu, tel quel
        import shutil            # (la tente, de 3/4 : calage avec lacet)
        shutil.copyfile(os.path.join(GODOT, "assets", "art", "props", kind + ".png"),
                        os.path.join(VUES, "%s_face.png" % kind))
        import tentes, pieux
    plain = {n: t["couleur"] for n, t in cfg.get("tuiles", {}).items() if t.get("couleur")}
    for op in cfg.get("ouvertures", []):   # (vraies ouvertures : embrasure et sol sombres, sauf motif donné)
        for n, rgb in ((op.get("embrasure", "dedans"), [44, 34, 30]), (op.get("sol", "dedans_sol"), [74, 56, 44])):
            if n not in cfg.get("tuiles", {}):
                plain[n] = rgb
    for name, rgb in plain.items():   # motif uni (une corde : trop fine pour en tirer un motif ; le dedans sombre)
        Image.fromarray(np.full((8, 8, 3), rgb, np.uint8), "RGB").save(os.path.join(work, "tex_tuile_%s.png" % name))
        Image.fromarray(np.zeros((8, 8), np.uint16)).save(os.path.join(work, "haut_tuile_%s.png" % name))
        info["tuile_" + name] = {"relief_px": 0.0, "w": 8.0, "h": 8.0, "vue": "face", "repete": True}
    for v in VIEWS:
        src = os.path.join(VUES, "%s_%s.png" % (kind, v))
        if not os.path.exists(src):
            print("pas de vue :", src)
            continue
        vc = cfg["vues"].get(v, {})
        im = np.asarray(Image.open(src).convert("RGBA"), np.float32) / 255.0
        # 5e canal : ce qu'« effacer » a retiré (ses bords ne sont pas des bords du dessin : ajuste.py)
        im = np.concatenate([im, np.zeros(im.shape[:2] + (1,), np.float32)], 2)
        for x0, y0, x1, y1 in vc.get("effacer", []):
            im[y0:y1, x0:x1, 3] = 0.0
            im[y0:y1, x0:x1, 4] = 1.0
        if tent and v == "face":   # porte remplie, cordes devant la toile effacées ; lignes recalées sur le dessin
            im = tentes.retouches(cfg, im, smooth_fill)
            json.dump(tentes.snap(cfg, im), open(os.path.join(work, "courbes.json"), "w"))
        if "pieux" in cfg and v == "face":   # profil de chaque pieu, rang par rang ; l'ombre peinte des côtés retirée
            prof = pieux.analyse(cfg, im)
            json.dump(prof, open(os.path.join(work, "pieux.json"), "w"))
            im = pieux.egaliser(cfg, im, prof)
        for spec in vc.get("egaliser", []):   # lumière du dessin retirée (avant « remodeler » : ses reprises
            if not spec.get("apres"):         # font moins de bandes ; rangs de la vue d'origine)
                im = even_light(im, spec)
        if vc.get("lumiere_face"):   # tour ronde : la lumière peinte de la face, portée autour de l'axe
            face = np.asarray(Image.open(os.path.join(VUES, "%s_face.png" % kind)).convert("RGBA"), np.float32) / 255.0
            im = face_light(im, v, vc["lumiere_face"], face)
        im = remodel(im, vc.get("remodeler", []))
        for spec in vc.get("egaliser", []):   # « apres » : colonne par colonne, après « remodeler » (les
            if spec.get("apres"):             # coutures de ses reprises effacées)
                im = even_light(im, spec)
        im, erased = im[..., :4].copy(), im[..., 4] > 0.5
        H, W = im.shape[:2]
        mask = im[..., 3] > 0.5
        lab, n = ndimage.label(mask)   # miettes détachées (détourage) : retirées
        if n > 1:
            sizes = ndimage.sum(mask, lab, range(1, n + 1))
            mask = np.isin(lab, 1 + np.nonzero(sizes >= 0.02 * sizes.max())[0])
        im[..., 3] = np.where(mask, im[..., 3], 0.0)
        erode = cfg.get("ronger") or max(3, int(round(ERODE_FRAC * max(W, H))))   # (px ; un contour épais : plus)
        filled = mask & ~ndimage.binary_dilation(~mask, iterations=erode)
        _, (iy, ix) = ndimage.distance_transform_edt(~filled, return_indices=True)
        rgb = im[iy, ix, :3]   # chaque pixel hors du dessin rongé : la couleur la plus proche
        variants = {"": rgb}
        if vc.get("toit_sans"):
            variants["_toit"] = clone_out(rgb, vc["toit_sans"])
        if vc.get("murs_sans"):
            variants["_murs"] = clone_out(rgb, vc["murs_sans"])
        for part, spec in vc.get("parties", {}).items():   # peinture propre d'une partie (devant d'une lucarne)
            variants["_" + part] = keep_disc(rgb, spec)
        # Bandes de colonnes retirées (une vue dessinée trop profonde) : ce qui reste garde son échelle.
        keep = np.ones(W, bool)
        for x0, x1 in vc.get("raccourcir", []):
            keep[x0:x1] = False
        cut = lambda a: a[:, keep]
        Image.fromarray(np.round(cut(im) * 255).astype(np.uint8), "RGBA").save(os.path.join(work, "vue_%s.png" % v))
        Image.fromarray(cut(erased).astype(np.uint8) * 255).save(os.path.join(work, "efface_%s.png" % v))
        f = float(np.clip(max(W, H) / 420.0, 0.75, 2.5))
        for suffix, col in variants.items():
            Image.fromarray(np.round(cut(col) * 255).astype(np.uint8), "RGB").save(
                os.path.join(work, "tex_%s%s.png" % (v, suffix)))
            h = detail_height(col, np.ones((H, W), bool), f) * DETAIL.get(kind, DETAIL_DEFAULT) * cfg.get("relief", 1.0)
            h = cut(h)
            lo, hi = float(h.min()), float(h.max())
            q = np.round((h - lo) / max(hi - lo, 1e-6) * 65535).astype(np.uint16)
            Image.fromarray(q).save(os.path.join(work, "haut_%s%s.png" % (v, suffix)))
            info[v + suffix] = {"relief_px": hi - lo, "w": int(keep.sum()), "h": H}
        print(v, W, "x", H, "->", int(keep.sum()), "rongé", erode, "px ; variantes", list(variants))
        for name, t in cfg.get("tuiles", {}).items():   # motifs répétés (dessus que nulle vue ne montre)
            if t.get("vue") == v and not t.get("sorte") and not t.get("couleur"):   # (brut : le dessin non rongé,
                save_tile(kind, cfg, work, info, name, t, im[..., :3] if t.get("brut") else rgb, f)   # un piquet)
    for name, t in cfg.get("tuiles", {}).items():   # motif tiré d'une image du jeu (sols, mur du Cabinet)
        if t.get("jeu"):
            save_game_tile(cfg, work, info, name, t)
    for name, t in cfg.get("tuiles", {}).items():   # motif tiré de la vue d'une autre sorte (toit de la même ville)
        if t.get("sorte"):
            src = os.path.join(VUES, "%s_%s.png" % (t["sorte"], t["vue"]))
            rgb = np.asarray(Image.open(src).convert("RGB"), np.float32) / 255.0
            save_tile(kind, cfg, work, info, name, t, rgb, float(np.clip(max(rgb.shape[:2]) / 420.0, 0.75, 2.5)))
    json.dump(info, open(os.path.join(work, "textures.json"), "w"), indent=1)


def save_tile(kind, cfg, work, info, name, t, rgb, f):
    """Motif répété tex_tuile_<nom>.png (+ son relief) : le rectangle t["rect"] de la vue, répété
    en miroir, ou tel quel ("repete" : rangs d'ardoises, la coupure passe pour un joint) ;
    "etirement" : [ex, ey], taille du motif (px de la vue) multipliée."""
    import numpy as np
    from PIL import Image
    from reliefs import detail_height, DETAIL, DETAIL_DEFAULT
    x0, y0, x1, y1 = t["rect"]
    H, W = rgb.shape[:2]
    h = detail_height(rgb, np.ones((H, W), bool), f)[y0:y1, x0:x1] * DETAIL.get(kind, DETAIL_DEFAULT) * cfg.get("relief", 1.0)
    col = rgb[y0:y1, x0:x1]
    if t.get("egaliser"):   # la lumière du dessin (dégradé, lueur) retirée : pas de bandes à chaque reprise
        from scipy.ndimage import gaussian_filter
        low = gaussian_filter(col, (t["egaliser"], t["egaliser"], 0), mode="wrap")
        col = np.clip(col / np.maximum(low, 1e-3) * col.mean((0, 1)), 0.0, 1.0)
    if t.get("tourner"):   # (un bout de corde dessiné debout : le motif couché, le long du tube)
        col, h = np.ascontiguousarray(np.rot90(col)), np.ascontiguousarray(np.rot90(h))
        x0, y0, x1, y1 = y0, x0, y1, x1
    Image.fromarray(np.round(col * 255).astype(np.uint8), "RGB").save(os.path.join(work, "tex_tuile_%s.png" % name))
    lo, hi = float(h.min()), float(h.max())
    q = np.round((h - lo) / max(hi - lo, 1e-6) * 65535).astype(np.uint16)
    Image.fromarray(q).save(os.path.join(work, "haut_tuile_%s.png" % name))
    ex, ey = t.get("etirement", [1.0, 1.0])   # (motif étiré le long des planches)
    info["tuile_" + name] = {"relief_px": hi - lo, "w": col.shape[1] * ex, "h": (y1 - y0) * ey, "vue": t["vue"],
                             "repete": bool(t.get("repete"))}


def save_game_tile(cfg, work, info, name, t):
    """Motif répété tiré d'une image du jeu (assets/art/<jeu> : un sol, le mur du Cabinet),
    rogné à son contenu (ou « rect ») ; « taille » [l, h] en m ; « origine » [x, y, z] (m) : le
    coin du motif (un lambris posé au sol) ; répété tel quel (images raccordables)."""
    import numpy as np
    from PIL import Image
    from reliefs import detail_height, DETAIL_DEFAULT
    im = Image.open(os.path.join(GODOT, "assets", "art", t["jeu"])).convert("RGBA")
    im = im.crop(tuple(t["rect"]) if t.get("rect") else im.getbbox())
    rgb = np.asarray(im.convert("RGB"), np.float32) / 255.0
    H, W = rgb.shape[:2]
    h = detail_height(rgb, np.ones((H, W), bool), float(np.clip(max(W, H) / 420.0, 0.75, 2.5))) * DETAIL_DEFAULT * cfg.get("relief", 1.0)
    im.convert("RGB").save(os.path.join(work, "tex_tuile_%s.png" % name))
    lo, hi = float(h.min()), float(h.max())
    Image.fromarray(np.round((h - lo) / max(hi - lo, 1e-6) * 65535).astype(np.uint16)).save(os.path.join(work, "haut_tuile_%s.png" % name))
    info["tuile_" + name] = {"relief_px": hi - lo, "w": W, "h": H, "vue": "face", "repete": t.get("repete", True),
                             "m": t["taille"], "relief_m": (hi - lo) * t["taille"][0] / W * t.get("relief", 0.5),
                             "origine": t.get("origine", [0.0, 0.0, 0.0])}


def keep_disc(rgb, spec):
    """Variante d'une vue pour une partie : "disque" [cx, cy, r] gardé (une fenêtre ronde), tout
    le reste de la couleur médiane du rectangle "fond" [x0, y0, x1, y1] (l'enduit)."""
    import numpy as np
    cx, cy, r = spec["disque"]
    x0, y0, x1, y1 = spec["fond"]
    H, W = rgb.shape[:2]
    ys, xs = np.mgrid[0:H, 0:W]
    out = rgb.copy()
    out[(xs + 0.5 - cx) ** 2 + (ys + 0.5 - cy) ** 2 > r * r] = np.median(rgb[y0:y1, x0:x1].reshape(-1, 3), 0)
    return out


def even_light(im, spec):
    """La lumière du dessin (un côté doré, l'autre dans l'ombre, les bandes des reprises de
    « remodeler ») retirée : couleur médiane de chaque colonne sur les rangs "rangs" [y0, y1]
    (sans les traits sombres ni le bord du dessin ; "tol" : seulement les pixels proches de la
    couleur médiane de la bande, pas les lucarnes), lissée ("sigma" px), ramenée partout à sa
    moyenne ; appliqué aux rangs "zone" [a, b] (défaut : de y0 jusqu'en bas, le toit garde sa
    lumière)."""
    import numpy as np
    from scipy.ndimage import binary_erosion, gaussian_filter1d
    y0, y1 = spec["rangs"]
    za, zb = spec.get("zone", [y0, im.shape[0]])
    band = im[y0:y1, :, :3]
    inside = binary_erosion(im[..., 3] > 0.5, iterations=10)[y0:y1]
    usable = inside & (band.mean(2) > (0.2 if spec.get("tol") else 0.35))
    if spec.get("tol"):
        ref = np.median(band[usable], 0)
        usable &= np.abs(band - ref).max(2) < spec["tol"]
    if spec.get("plan"):   # dans les deux sens (bandes de lignes et de colonnes) : les rangs y0..y1
        from scipy.ndimage import gaussian_filter
        sig = spec.get("sigma", 25)
        num = gaussian_filter(band * usable[..., None], (sig, sig, 0))
        den = gaussian_filter(usable.astype(np.float32), sig)[..., None]
        low = num / np.maximum(den, 1e-3)
        out = im.copy()
        out[y0:y1, :, :3] = np.clip(band * np.median(band[usable], 0) / np.maximum(low, 1e-3), 0.0, 1.0)
        return out
    cols = np.array([np.median(band[usable[:, x], x], 0) if usable[:, x].sum() > 8 else [np.nan] * 3
                     for x in range(im.shape[1])])
    ok = ~np.isnan(cols[:, 0])
    idx = np.arange(len(cols))
    for c in range(3):
        cols[:, c] = np.interp(idx, idx[ok], cols[ok, c])
    cols = gaussian_filter1d(cols, spec.get("sigma", 20), axis=0, mode="nearest")
    gain = cols[ok].mean(0) / np.maximum(cols, 1e-3)
    out = im.copy()
    out[za:zb, :, :3] = np.clip(im[za:zb, :, :3] * gain[None], 0.0, 1.0)
    return out


def _column_light(im, rows, sigma):
    """Couleur médiane de chaque colonne sur les rangs [y0, y1] (pierres claires seulement, pas les
    joints ni les ombres portées), lissée ; le milieu et le rayon (px) de la silhouette sur ces rangs."""
    import numpy as np
    from scipy.ndimage import gaussian_filter1d
    y0, y1 = rows
    band, alpha = im[y0:y1, :, :3], im[y0:y1, :, 3] > 0.5
    ok = alpha & (band.mean(2) > 0.45)
    cols = np.array([np.median(band[ok[:, x], x], 0) if ok[:, x].sum() > 6 else [np.nan] * 3
                     for x in range(im.shape[1])])
    good = ~np.isnan(cols[:, 0])
    idx = np.arange(len(cols))
    for c in range(3):
        cols[:, c] = np.interp(idx, idx[good], cols[good, c])
    cols = gaussian_filter1d(cols, sigma, axis=0, mode="nearest")
    xs = np.nonzero(alpha.any(0))[0]
    return cols, (xs.min() + xs.max() + 1) / 2.0, (xs.max() + 1 - xs.min()) / 2.0, good


AZIMUT = {"face": 0.0, "cote": 90.0, "dos": 180.0}   # azimut (degrés, 0 devant, 90 à droite) du milieu de chaque vue


def face_light(im, view, spec, face):
    """Tour ronde (réglage vues.<v>.lumiere_face {rangs, rangs_face, sigma}) : chaque vue a peint sa
    propre lumière (venue du haut à gauche de la vue) ; aux raccords des vues, la même pierre serait
    claire d'un côté et sombre de l'autre. La lumière peinte de la face (couleur des pierres selon
    l'azimut de chaque colonne, ajustée en a + b cos + c sin, canal par canal : le chaud et le froid
    compris) est portée autour de l'axe et remplace, colonne par colonne, celle de la vue."""
    import numpy as np
    sigma = spec.get("sigma", 8)
    pf, cf, rf, good_f = _column_light(face, spec["rangs_face"], sigma)
    d = (np.arange(face.shape[1]) + 0.5 - cf) / rf
    use = good_f & (np.abs(d) < 0.92)
    az = np.arcsin(np.clip(d[use], -1, 1))
    A = np.stack([np.ones_like(az), np.cos(az), np.sin(az)], 1)
    coef, *_ = np.linalg.lstsq(A, pf[use], rcond=None)   # (3, 3) : a, b, c par canal
    lo, hi = pf[use].min(0), pf[use].max(0)
    pv, cv, rv, _ = _column_light(im, spec["rangs"], sigma)
    dv = np.clip((np.arange(im.shape[1]) + 0.5 - cv) / rv, -1, 1)
    azv = np.radians(AZIMUT[view]) + np.arcsin(dv)
    target = np.clip(np.stack([np.ones_like(azv), np.cos(azv), np.sin(azv)], 1) @ coef, lo, hi)
    gain = np.clip(target / np.maximum(pv, 1e-3), 0.55, 1.6)
    out = im.copy()
    out[..., :3] = np.clip(im[..., :3] * gain[None], 0.0, 1.0)
    print("lumière de la face portée sur", view, ": gain %.2f à %.2f" % (gain.min(), gain.max()))
    return out


def remodel(im, ops):
    """Vue dessinée aux mauvaises proportions (un dos plus étroit, un toit plus bas que la face) :
    bandes de colonnes ou de lignes répétées ou retirées, dans l'ordre. Opérations : ["colonnes",
    a, b, n] (colonnes a..b répétées n fois de plus, à la suite), ["lignes", a, b, n] (de même),
    n = 0 : la bande retirée ; 5e valeur facultative « fondu » (px) : à chaque couture, les
    lignes d'avant sont fondues vers celles qui précèdent la suite dans le dessin (pas de trait).
    Coordonnées : celles de l'image au moment de l'opération."""
    import numpy as np
    for op in ops:
        kind_, a, b, n = op[:4]
        fade = op[4] if len(op) > 4 else 0
        axis = 1 if kind_ == "colonnes" else 0
        size = im.shape[axis]
        if n > 0:
            idx = list(range(b)) + list(range(a, b)) * n + list(range(b, size))
        else:
            idx = list(range(a)) + list(range(b, size))
        out = np.moveaxis(np.take(im, idx, axis=axis), axis, 0).copy()
        src = np.moveaxis(im, axis, 0)
        for k in range(1, len(idx)):
            if idx[k] == idx[k - 1] + 1:
                continue
            for j in range(1, fade + 1):
                if k - j < 0 or idx[k] - j < 0:
                    break
                w = 1.0 - (j - 1) / fade
                out[k - j] = (1 - w) * out[k - j] + w * src[idx[k] - j]
        im = np.moveaxis(out, 0, axis)
    return im


def pil_vues(kind):
    """Vues de côté et de dos composées à partir de la vue de face (quand aucun dessin n'existe :
    maisons simples) : réglage "depuis_face" : {"cote"|"dos": {"cloner": rectangles comme
    toit_sans (la porte, la lanterne remplacées par le mur voisin, une fenêtre recopiée),
    "remodeler": bandes (largeur = profondeur), "miroir": vrai (le dos se voit de l'autre côté)}}.
    Écrit generated_imgs/vues/<sorte>_<vue>.png (RGBA, même échelle que la face)."""
    import numpy as np
    from PIL import Image
    cfg = config(kind)
    face = np.asarray(Image.open(os.path.join(VUES, kind + "_face.png")).convert("RGBA"), np.float32) / 255.0
    for v, ops in cfg.get("depuis_face", {}).items():
        im = even_light(face, ops["egaliser"]) if ops.get("egaliser") else face   # (d'abord : ce qui est
        im = clone_out(im, ops.get("cloner", []))                                  # recopié ou rempli est déjà égal)
        im = smooth_fill(im, ops.get("lisser", []))
        im = remodel(im, ops.get("remodeler", []))
        if ops.get("miroir"):
            im = im[:, ::-1]
        out = os.path.join(VUES, "%s_%s.png" % (kind, v))
        Image.fromarray(np.round(im * 255).astype(np.uint8), "RGBA").save(out)
        print("vue composée :", out, im.shape[1], "x", im.shape[0])


def smooth_fill(im, rects, tol=0.22, mask=None):
    """Rectangles [x0, y0, x1, y1] (réunis ; ou un masque) remplis en douceur depuis leur pourtour
    (enduit uni : la porte, la lanterne et son halo retirés d'un mur sans motif ; une corde
    devant la toile) : solution de Laplace ; seuls les pixels du pourtour proches de la couleur
    médiane du pourtour (l'enduit) la fixent, les autres (volet, trait du soubassement) ne
    comptent pas (bord libre)."""
    import numpy as np
    from scipy.sparse import coo_matrix
    from scipy.sparse.linalg import spsolve
    if not rects and mask is None:
        return im
    H, W = im.shape[:2]
    mask = np.zeros((H, W), bool) if mask is None else mask.copy()
    for r in rects:
        x0, y0, x1, y1 = r[:4]
        mask[y0:y1, x0:x1] = True
    ys, xs = np.nonzero(mask)
    index = -np.ones((H, W), np.int64)
    index[ys, xs] = np.arange(len(ys))
    ring = []
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ny, nx = ys + dy, xs + dx
        ok = (ny >= 0) & (ny < H) & (nx >= 0) & (nx < W)
        ring.append(np.where(ok, ny, 0) * W + np.where(ok, nx, 0))
    flat = im.reshape(-1, im.shape[2])
    known = ~mask.ravel()
    border = np.unique(np.concatenate([r[known[r]] for r in ring]))
    ref = np.median(flat[border, :3], 0)
    good = known & (np.abs(flat[:, :3] - ref).max(1) < tol)
    rows, cols, vals = [], [], []
    rhs = np.zeros((len(ys), im.shape[2]))
    diag = np.zeros(len(ys))
    for (dy, dx), r in zip(((1, 0), (-1, 0), (0, 1), (0, -1)), ring):
        ny, nx = ys + dy, xs + dx
        inside = (ny >= 0) & (ny < H) & (nx >= 0) & (nx < W)
        inner = inside & mask.ravel()[r]
        fixed = inside & good[r] & ~inner
        diag += inner | fixed
        rows.append(np.nonzero(inner)[0]); cols.append(index.ravel()[r[inner]]); vals.append(-np.ones(inner.sum()))
        rhs[fixed] += flat[r[fixed]]
    n = len(ys)
    A = coo_matrix((np.concatenate([diag + 1e-6] + vals), (np.concatenate([np.arange(n)] + rows),
                    np.concatenate([np.arange(n)] + cols))), shape=(n, n)).tocsr()
    out = im.copy()
    sol = spsolve(A, rhs + 1e-6 * ref.mean())
    out[ys, xs] = np.clip(sol, 0.0, 1.0)
    return out


def clone_out(rgb, rects):
    """Rectangles [x0, y0, x1, y1(, dx(, dy))] remplis par le dessin voisin, décalé de dx
    (défaut : la largeur du rectangle, vers la gauche) ou de dy (vers le bas si > 0), répété si
    la source est plus étroite : les rangs d'ardoises continuent sous la cheminée."""
    out = rgb.copy()
    for r in rects:
        x0, y0, x1, y1 = r[:4]
        dx = r[4] if len(r) > 4 else -(x1 - x0)
        dy = r[5] if len(r) > 5 else 0
        if dy:
            for y in (range(y1 - 1, y0 - 1, -1) if dy > 0 else range(y0, y1)):
                out[y, x0:x1] = out[y + dy, x0:x1]
        else:
            for x in (range(x1 - 1, x0 - 1, -1) if dx > 0 else range(x0, x1)):
                out[y0:y1, x] = out[y0:y1, x + dx]
    return out


def pil_planche(kind):
    from PIL import Image, ImageDraw, ImageFont
    work = work_dir(kind)
    rows = [[("dessin du jeu", os.path.join(GODOT, "assets", "art", "props", kind + ".png")),
             ("modèle calé sur la vue de face", os.path.join(work, "rendu_cale_face.png")),
             ("caméra du jeu 0°/40°", os.path.join(work, "rendu_jeu.png")),
             ("-45°/35°", os.path.join(work, "rendu_g45.png")),
             ("+45°/35°", os.path.join(work, "rendu_d45.png"))],
            [("vue de côté", os.path.join(work, "vue_cote.png")),
             ("modèle calé (côté)", os.path.join(work, "rendu_cale_cote.png")),
             ("vue de dos", os.path.join(work, "vue_dos.png")),
             ("modèle calé (dos)", os.path.join(work, "rendu_cale_dos.png")),
             ("90°/20°, 180°/30°", os.path.join(work, "rendu_cote_dos.png"))]]
    if not os.path.exists(os.path.join(work, "vue_cote.png")):   # le dessin seul (tente, palissade) : pas d'autre vue
        rows[0][1] = ("modèle calé sur le dessin", os.path.join(work, "rendu_cale_face.png"))
        rows[1] = [("jeu, bord gauche -30°/40°", os.path.join(work, "rendu_jeu_g30.png")),
                   ("jeu, bord droit +30°/40°", os.path.join(work, "rendu_jeu_d30.png")),
                   ("côté caché -90°/20°", os.path.join(work, "rendu_g90.png")),
                   ("90°/20°", os.path.join(work, "rendu_cote90.png")),
                   ("fond 180°/30°", os.path.join(work, "rendu_dos180.png"))]
    cell, pad = 340, 26
    board = Image.new("RGB", (cell * 5, (cell + pad) * len(rows)), (104, 128, 108))
    d = ImageDraw.Draw(board)
    try:
        font = ImageFont.truetype("arial.ttf", 16)
    except OSError:
        font = ImageFont.load_default()
    for r, row in enumerate(rows):
        for c, (label, path) in enumerate(row):
            x, y = c * cell, r * (cell + pad)
            d.text((x + 6, y + 4), label, fill=(255, 255, 255), font=font)
            if not os.path.exists(path):
                continue
            im = Image.open(path).convert("RGBA")
            im = im.crop(im.getbbox() or (0, 0, im.width, im.height))   # (rendus : au contenu)
            k = min((cell - 12) / im.width, (cell - 12) / im.height)
            im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
            board.paste(im, (x + (cell - im.width) // 2, y + pad + (cell - im.height) // 2), im)
    os.makedirs(CAPTURES, exist_ok=True)
    out = os.path.join(CAPTURES, "maisons_assemblees_%s.png" % kind)
    board.save(out)
    print("planche :", out)
    shots = [("porte fermée", "porte_fermee.png"), ("ouverte, de 3/4 gauche", "porte_ouverte_g.png"),
             ("ouverte, de 3/4 droite", "porte_ouverte_d.png")]
    if os.path.exists(os.path.join(work, shots[0][1])):   # la porte du contrat (variante animable)
        doors = Image.new("RGB", (480 * 3, 480 + pad), (104, 128, 108))
        d = ImageDraw.Draw(doors)
        for c, (label, f) in enumerate(shots):
            if os.path.exists(os.path.join(work, f)):
                doors.paste(Image.open(os.path.join(work, f)).convert("RGB"), (c * 480, pad))
            d.text((c * 480 + 6, 4), label, fill=(255, 255, 255), font=font)
        out = os.path.join(CAPTURES, "portes_%s.png" % kind)
        doors.save(out)
        print("planche :", out)


# ================================================================== Blender : géométrie
class Parts:
    """Noms des parties (attribut entier « part » des faces) et leur règle de peinture propre."""
    def __init__(self):
        self.names = []
        self.painters = {}

    def id(self, name, painter=None):
        if name not in self.names:
            self.names.append(name)
        if painter:
            self.painters[name] = painter
        return self.names.index(name)


def mesh_object(name, polys, part_id, weld=1e-4):
    """Un objet de polygones (listes de sommets), sommets soudés, faces de la partie part_id."""
    bm = bmesh.new()
    for poly in polys:
        bm.faces.new([bm.verts.new(p) for p in poly])
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=weld)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.attributes.new("part", 'INT', 'FACE').data.foreach_set("value", [part_id] * len(me.polygons))
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def jitter(obj, amp, freq=2.3, seed=0.0):
    """Sommets légèrement déplacés (bruit continu : deux sommets au même endroit bougent pareil)."""
    if amp <= 0:
        return
    for v in obj.data.vertices:
        p = Vector(v.co) * freq + Vector((seed, seed * 0.7, seed * 1.3))
        v.co += noise.noise_vector(p) * amp


def outline(W, D, r, step, arc_segs):
    """Tour des murs vu d'en haut (sens trigonométrique), coins arrondis : points et normales
    horizontales vers l'extérieur."""
    pts, nrm = [], []
    corners = [((W / 2 - r, r), -90.0), ((W / 2 - r, D - r), 0.0), ((-W / 2 + r, D - r), 90.0), ((-W / 2 + r, r), 180.0)]
    starts = [(-W / 2 + r, 0.0), (W / 2, r), (W / 2 - r, D), (-W / 2, D - r)]
    for k in range(4):
        (cx, cy), a0 = corners[k]
        sx, sy = starts[k]
        ex, ey = cx + r * math.cos(math.radians(a0)), cy + r * math.sin(math.radians(a0))
        n = max(1, math.ceil(math.hypot(ex - sx, ey - sy) / step))
        seg_n = (math.cos(math.radians(a0)), math.sin(math.radians(a0)))
        for i in range(n):
            t = i / n
            pts.append((sx + (ex - sx) * t, sy + (ey - sy) * t))
            nrm.append(seg_n)
        for i in range(arc_segs):
            a = math.radians(a0 + 90.0 * i / arc_segs)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
            nrm.append((math.cos(a), math.sin(a)))
    return pts, nrm


def rim_height(ru, angle):
    """Hauteur du bord cassé d'une ruine (murs.ruine) à l'angle donné (degrés, autour de l'axe du
    corps : -90 = devant, 0 = droite, 90 = fond) : points clés « haut » [[angle, z]…] interpolés en
    tour, plus des gradins « cassure » (m, pseudo-aléatoires, tous les « pas_cassure » degrés : les
    assises de pierre cassées)."""
    keys = sorted(((a % 360.0, z) for a, z in ru["haut"]))
    a = angle % 360.0
    ext = [(keys[-1][0] - 360.0, keys[-1][1])] + keys + [(keys[0][0] + 360.0, keys[0][1])]
    for (a0, z0), (a1, z1) in zip(ext, ext[1:]):
        if a0 <= a <= a1:
            z = z0 + (z1 - z0) * (a - a0) / max(a1 - a0, 1e-9)
            break
    amp, pas = ru.get("cassure", 0.0), ru.get("pas_cassure", 9.0)
    if amp:
        k = math.floor(a / pas)
        z += amp * (math.sin(k * 12.9898 + 78.233) * 43758.5453 % 1.0 - 0.5)
    return z


def walls(cfg, top, parts, fine):
    """Le corps : murs aux coins arrondis, du pied (murs.z0) au dessous du toit, bosselés.
    murs.segments : côtés de chaque coin arrondi (une tour ronde : coin = demi-largeur) ;
    murs.fruit : le mur rentre de tant de m par m de hauteur (tour légèrement conique) ;
    murs.ruine : sans toit, le haut suit un bord cassé (rim_height), le mur a une épaisseur
    (« epaisseur ») : dedans (murs_dedans), arase du bord (murs_arase) et fond (murs_fond, à la
    hauteur « fond »)."""
    m = cfg["murs"]
    W, D, r, z0 = m["largeur"], m["profondeur"], m.get("coin", 0.1), m.get("z0", 0.0)
    step = 0.28 if fine else 100.0
    segs = m.get("segments", 3)
    pts, nrm = outline(W, D, r, step, segs if fine else max(1, segs // 2))
    keep = [i for i in range(len(pts)) if math.dist(pts[i], pts[i - 1]) > 1e-6]   # (tour ronde : pas de côté droit,
    pts, nrm = [pts[i] for i in keep], [nrm[i] for i in keep]                    # son point en double retiré)
    pts = [(x, y + m.get("y0", 0.0)) for x, y in pts]   # (corps en retrait : la cabane sur son plancher)
    fruit = m.get("fruit", 0.0)
    ru = m.get("ruine")
    cy = m.get("y0", 0.0) + D / 2
    tops = [rim_height(ru, math.degrees(math.atan2(y - cy, x))) if ru else top for x, y in pts]
    if ru and not fine:   # (grossier : quelques rangs, le bord cassé suivi)
        step = 1.0

    def at(i, z, inset=0.0):   # point du tour i à la hauteur z, rentré du fruit (et de inset)
        k = fruit * (z - z0) + inset
        return (pts[i][0] - nrm[i][0] * k, pts[i][1] - nrm[i][1] * k, z)

    n = len(pts)
    nz = max(1, math.ceil((max(tops) - z0) / step))
    polys = []
    for i in range(n):
        j2 = (i + 1) % n
        za = [z0 + (tops[i] - z0) * j / nz for j in range(nz + 1)]
        zb = [z0 + (tops[j2] - z0) * j / nz for j in range(nz + 1)]
        for j in range(nz):
            polys.append([at(i, za[j]), at(j2, zb[j]), at(j2, zb[j + 1]), at(i, za[j + 1])])
    objs = [mesh_object("murs", polys, parts.id("murs"))]
    if ru:
        e, zf = ru.get("epaisseur", 0.4), ru.get("fond", z0)
        nzi = max(1, math.ceil((max(tops) - zf) / step))
        inner, rim = [], []
        for i in range(n):
            j2 = (i + 1) % n
            za = [zf + (tops[i] - zf) * j / nzi for j in range(nzi + 1)]
            zb = [zf + (tops[j2] - zf) * j / nzi for j in range(nzi + 1)]
            for j in range(nzi):   # (tourné vers l'axe)
                inner.append([at(i, za[j + 1], e), at(j2, zb[j + 1], e), at(j2, zb[j], e), at(i, za[j], e)])
            rim.append([at(i, tops[i]), at(j2, tops[j2]), at(j2, tops[j2], e), at(i, tops[i], e)])
        objs.append(mesh_object("murs_dedans", inner, parts.id("murs_dedans")))
        objs.append(mesh_object("murs_arase", rim, parts.id("murs_arase")))
        objs.append(mesh_object("murs_fond", [[at(i, zf, e) for i in range(n)]], parts.id("murs_fond")))
    if fine:   # murs bosselés (le long de leur normale), le pied et le haut à peine
        amp = m.get("bosses", 0.012)
        for obj in objs:
            for v in obj.data.vertices:
                x, y, z = v.co
                k = min(range(len(pts)), key=lambda i: (pts[i][0] - x) ** 2 + (pts[i][1] - y) ** 2)
                push = noise.noise(Vector((x * 1.7, y * 1.7, z * 1.7))) * amp * min(1.0, (z - z0) / 0.3 + 0.3)
                v.co.x += nrm[k][0] * push
                v.co.y += nrm[k][1] * push
    if len(objs) > 1:   # (ruine : un seul objet, les parties gardées)
        select_only(objs, objs[0])
        bpy.ops.object.join()
    return objs[0]


def roof_axes(t):
    """(a le long du faîte, b en travers) : bornes, et le passage (a, b) -> (x, y)."""
    if t.get("axe", "x") == "x":
        return t["x"], t["y"], (lambda a, b: (a, b)), False
    return t["y"], t["x"], (lambda a, b: (b, a)), True


def roof_profile(t, a, b):
    """Hauteur du dessus d'un toit en (a, b) (dans ses bornes)."""
    (a0, a1), (b0, b1), _, _ = roof_axes(t)
    ra, rb = t.get("croupes", [0.0, 0.0])
    br = t.get("faite_pos", (b0 + b1) / 2)
    f = min((b - b0) / (br - b0), (b1 - b) / (b1 - br))
    if ra > 0:
        f = min(f, (a - a0) / ra)
    if rb > 0:
        f = min(f, (a1 - a) / rb)
    return t["egout"] + t["faitage"] * max(0.0, min(1.0, f))


def roof_polys(t):
    """Toit plein (dessus : pans et croupes ; bords : chant vertical ; dessous plat) et les murs
    de ses pignons (bouts sans croupe, t["pignons"] : plan du mur à chaque bout, ou null)."""
    (a0, a1), (b0, b1), to_xy, flip = roof_axes(t)
    ze, H, th = t["egout"], t["faitage"], t.get("epaisseur", 0.12)
    ra, rb = t.get("croupes", [0.0, 0.0])
    br = t.get("faite_pos", (b0 + b1) / 2)

    def P(a, b, z):
        x, y = to_xy(a, b)
        return (x, y, z)

    E = [P(a0, b0, ze), P(a1, b0, ze), P(a1, b1, ze), P(a0, b1, ze)]
    B = [(p[0], p[1], p[2] - th) for p in E]
    R0, R1 = P(a0 + ra, br, ze + H), P(a1 - rb, br, ze + H)
    roof = [[E[0], E[1], R1, R0], [E[1], E[2], R1], [E[2], E[3], R0, R1], [E[3], E[0], R0]]
    for i in range(4):
        j = (i + 1) % 4
        roof.append([B[i], B[j], E[j], E[i]])
    roof.append([B[0], B[3], B[2], B[1]])
    gables = []
    side = t.get("debord_pignon", 0.2)
    for end, plane in enumerate(t.get("pignons", [None, None])):
        if plane is None:
            continue
        bw0, bw1 = b0 + side, b1 - side
        zu = lambda b: ze - th + H * min((b - b0) / (br - b0), (b1 - b) / (b1 - br)) + 0.03
        zb = t.get("pignon_bas", ze - th - 0.3)
        g = [P(plane, bw0, zb), P(plane, bw1, zb), P(plane, bw1, zu(bw1)), P(plane, br, zu(br)), P(plane, bw0, zu(bw0))]
        # (sens : normale +a, vers le bout a1 ; retourné pour le bout a0)
        gables.append(g if end == 1 else list(reversed(g)))
    if flip:
        roof = [list(reversed(p)) for p in roof]
        gables = [list(reversed(p)) for p in gables]
    return roof, gables


def roof_height(roofs, x, y):
    """Hauteur du dessus des toits en (x, y) (le plus haut ; -inf hors des toits)."""
    best = -math.inf
    for t in roofs:
        (a0, a1), (b0, b1), _, _ = roof_axes(t)
        a, b = (x, y) if t.get("axe", "x") == "x" else (y, x)
        if a0 <= a <= a1 and b0 <= b <= b1:
            best = max(best, roof_profile(t, a, b))
    return best


def apply_modifiers(obj):
    me = bpy.data.meshes.new_from_object(obj.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    old = obj.data
    obj.modifiers.clear()
    obj.data = me
    bpy.data.meshes.remove(old)


def roofs(cfg, parts, fine):
    """Les toits réunis (noues propres) ; les murs de leurs pignons (à part)."""
    objs, gable_polys = [], []
    if not cfg.get("toits"):   # (une ruine sans toit : murs.ruine)
        return []
    for i, t in enumerate(cfg["toits"]):
        roof, gables = roof_polys(t)
        objs.append(mesh_object("toit%d" % i, roof, parts.id("toit%d" % i)))
        gable_polys += gables
    main = objs[0]
    for o in objs[1:]:   # toits croisés : union
        mod = main.modifiers.new("union", 'BOOLEAN')
        mod.operation, mod.solver, mod.object = 'UNION', 'EXACT', o
        apply_modifiers(main)
        bpy.data.objects.remove(o)
    if fine:
        bm = bmesh.new(); bm.from_mesh(main.data)
        low = min(t["egout"] for t in cfg["toits"]) - 0.02
        sharp = [e for e in bm.edges if len(e.link_faces) == 2 and e.calc_face_angle(0) > math.radians(20)
                 and min(v.co.z for v in e.verts) > low]
        try:
            bmesh.ops.bevel(bm, geom=sharp, offset=cfg.get("biseau_toit", 0.035), segments=2, profile=0.5,
                            affect='EDGES', clamp_overlap=True)
        except Exception as err:   # (biseau impossible : arêtes vives)
            print("biseau du toit :", err)
        bm.to_mesh(main.data); bm.free()
        jitter(main, 0.012, 1.9, 3.0)
    out = [main]
    if gable_polys:
        out.append(mesh_object("pignons", gable_polys, parts.id("murs")))
    return out


def box_polys(x0, x1, y0, y1, z0, z1):
    v = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    idx = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    return [[v[i] for i in f] for f in idx]


def ring_polys(rings, n, axis_pt, axis="z", cap=True):
    """Solide de révolution à n côtés : rings = [(rayon, hauteur le long de l'axe)…] du bas vers le
    haut ; axis_pt = le point de l'axe à la hauteur 0 ; axe "z" (debout) ou "x" (couché)."""
    cx, cy, cz = axis_pt

    def pt(r, h, i):
        a = 2 * math.pi * (i + 0.5) / n
        u, v = r * math.cos(a), r * math.sin(a)
        return (cx + u, cy + v, cz + h) if axis == "z" else (cx + h, cy + u, cz + v)

    polys = []
    for (r0, h0), (r1, h1) in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            polys.append([pt(r0, h0, i), pt(r0, h0, j), pt(r1, h1, j), pt(r1, h1, i)])
    if cap:
        polys.append([pt(rings[-1][0], rings[-1][1], i) for i in range(n)])
        polys.append([pt(rings[0][0], rings[0][1], i) for i in reversed(range(n))])
    return polys


def _hash01(k):
    """Nombre pseudo-aléatoire stable dans [0, 1) (bords cassés)."""
    return math.sin(k * 12.9898 + 78.233) * 43758.5453 % 1.0


def tube_polys(points, r, n):
    """Tube de n côtés le long d'une ligne brisée (une tige de fer tordue), bouts fermés."""
    P = [Vector(p) for p in points]
    rings = []
    for i, p in enumerate(P):
        d = (P[min(i + 1, len(P) - 1)] - P[max(i - 1, 0)]).normalized()
        a = Vector((1.0, 0.0, 0.0)) if abs(d.x) < 0.9 else Vector((0.0, 1.0, 0.0))
        u = d.cross(a).normalized()
        w = d.cross(u)
        rings.append([tuple(p + (u * math.cos(2 * math.pi * k / n) + w * math.sin(2 * math.pi * k / n)) * r)
                      for k in range(n)])
    polys = []
    for ra, rb in zip(rings, rings[1:]):
        for k in range(n):
            polys.append([ra[k], ra[(k + 1) % n], rb[(k + 1) % n], rb[k]])
    polys.append(list(reversed(rings[0])))
    polys.append(rings[-1])
    return polys


def cone_polys(c):
    """Morceau de toit conique (une coupole de lanterne tombée) : secteur d'angles « angles »
    [a0, a1] (degrés) d'un cône de rayon « r » et de hauteur « h » posé en « centre » [x, y, z] ;
    bords cassés (« casse » : part du rayon rongée ; « casse_angle » : degrés rongés aux bords
    droits), épaisseur « epaisseur », puis tourné de « rotation » [rx, ry, rz] (degrés) autour de
    « pivot » (défaut : le centre)."""
    from mathutils import Euler
    cx, cy, cz = c["centre"]
    R, H, e = c["r"], c["h"], c.get("epaisseur", 0.05)
    a0, a1 = c["angles"]
    na = max(2, int(math.ceil(abs(a1 - a0) / c.get("pas_angle", 6.0))))
    nr = c.get("rangs", 4)
    casse, casse_a = c.get("casse", 0.12), c.get("casse_angle", 6.0)

    def top(j, k):   # rang j (0 : sommet … nr : bord), rayon k
        if j == 0:
            return Vector((cx, cy, cz + H))
        t = j / nr
        ja, jb = a0 + casse_a * _hash01(j * 7.1), a1 - casse_a * _hash01(j * 3.7 + 1.0)
        ang = math.radians(ja + (jb - ja) * k / na)
        f = t * (1.0 - casse * _hash01(k * 5.3 + 2.0) * t ** 2)   # (le bord rongé)
        return Vector((cx + R * f * math.cos(ang), cy + R * f * math.sin(ang), cz + H * (1.0 - f)))

    grid = [[top(j, k) for k in range(na + 1)] for j in range(nr + 1)]
    below = lambda p: p - Vector((0.0, 0.0, e))
    upper = []
    for j in range(nr):
        for k in range(na):
            if j == 0:
                upper.append([grid[0][0], grid[1][k], grid[1][k + 1]])
            else:
                upper.append([grid[j][k], grid[j + 1][k], grid[j + 1][k + 1], grid[j][k + 1]])
    polys = []
    for p in upper:   # dessus tourné vers le haut, dessous vers le bas
        nz = (p[1] - p[0]).cross(p[2] - p[0]).z
        up = p if nz > 0 else list(reversed(p))
        polys.append([tuple(v) for v in up])
        polys.append([tuple(below(v)) for v in reversed(up)])
    # chant : le tour du morceau (bord droit a0, bord rongé, bord droit a1), en bande
    loop = [grid[j][0] for j in range(nr + 1)] + [grid[nr][k] for k in range(1, na + 1)] + \
           [grid[j][na] for j in range(nr - 1, 0, -1)]
    mid = sum(loop, Vector()) / len(loop)
    for p, q in zip(loop, loop[1:] + loop[:1]):
        f = [p, q, below(q), below(p)]
        nrm = (f[1] - f[0]).cross(f[3] - f[0])
        polys.append([tuple(v) for v in (f if nrm.dot((p + q) / 2 - mid) > 0 else reversed(f))])
    rot = Euler([math.radians(a) for a in c.get("rotation", [0, 0, 0])]).to_matrix()
    piv = Vector(c.get("pivot", c["centre"]))
    return [[tuple(rot @ (Vector(v) - piv) + piv) for v in p] for p in polys]


def extras(cfg, parts, fine):
    """Cheminées, marches, boîtes, cylindres (poteaux, poutres ; « profil » [[r, h]…] : un solide de
    révolution, un nid), pignons à redans, cristaux, tiges (tubes le long d'une ligne brisée : fers
    tordus), coupoles (morceau de toit conique tombé) : chacun sa partie (peinte à part, « boîte
    dépliée » par défaut)."""
    objs = []

    def add(name, polys, amp, painter=None):
        o = mesh_object(name, polys, parts.id(name, painter))
        if fine:
            jitter(o, amp, 2.7, 5.0 + len(objs))
        objs.append(o)

    for i, c in enumerate(cfg.get("cheminees", [])):
        x, y, l, p = c["x"], c["y"], c["l"], c["p"]
        base = min(roof_height(cfg["toits"], x + dx * l / 2, y + dy * p / 2) for dx in (-1, 1) for dy in (-1, 1)) - 0.15
        cap = c.get("chapeau", 0.1)
        polys = box_polys(x - l / 2, x + l / 2, y - p / 2, y + p / 2, base, c["haut"] - cap)
        polys += box_polys(x - l / 2 - 0.05, x + l / 2 + 0.05, y - p / 2 - 0.05, y + p / 2 + 0.05, c["haut"] - cap, c["haut"])
        if c.get("pot", 0) > 0:
            polys += ring_polys([(0.1, 0.0), (0.1, c["pot"])], 8, (x, y, c["haut"]))
        add("cheminee%d" % i, polys, 0.01)
    for i, s in enumerate(cfg.get("marches", [])):
        z0 = s.get("z0", 0.0)
        add("marche%d" % i, box_polys(s["x"] - s["l"] / 2, s["x"] + s["l"] / 2, -s["p"], 0.05, z0, z0 + s["h"]), 0.01)
    for i, b in enumerate(cfg.get("boites", [])):
        add("%s%d" % (b.get("partie", "boite"), i), box_polys(*b["x"], *b["y"], *b["z"]), b.get("bosses", 0.006),
            b.get("peintre"))
    for i, c in enumerate(cfg.get("cylindres", [])):
        axis = c.get("axe", "z")
        if axis == "z":
            (h0, h1), at = c["z"], (c["x"], c["y"], c["z"][0])
        else:
            (h0, h1), at = c["x"], (c["x"][0], c["y"], c["z"])
        rings = [tuple(p) for p in c["profil"]] if c.get("profil") else [(c["r"], 0.0), (c["r"], h1 - h0)]
        add("%s%d" % (c.get("partie", "poteau"), i), ring_polys(rings, c.get("cotes", 10), at, axis),
            c.get("bosses", 0.008), c.get("peintre"))
    for i, t in enumerate(cfg.get("tiges", [])):   # fers tordus (restes d'une lanterne)
        add("%s%d" % (t.get("partie", "tige"), i), tube_polys(t["points"], t.get("r", 0.04), t.get("cotes", 6)),
            t.get("bosses", 0.0), t.get("peintre"))
    for i, c in enumerate(cfg.get("coupoles", [])):   # morceau de toit conique tombé
        add("%s%d" % (c.get("partie", "coupole"), i), cone_polys(c), c.get("bosses", 0.008), c.get("peintre"))
    for i, g in enumerate(cfg.get("redans", [])):   # pignon à redans : mur plein, marches jusqu'au faîte
        x, y, ep, demi, n = g["x"], g["y"], g.get("ep", 0.3), g["demi"], g.get("marches", 5)
        ze, z1 = g["egout"], g["haut"]
        polys = box_polys(x - demi, x + demi, y - ep / 2, y + ep / 2, g["z0"], ze)
        dz = (z1 - ze) / n
        for k in range(1, n + 1):
            hw = demi * (1 - (k - 0.5) / n)
            polys += box_polys(x - hw, x + hw, y - ep / 2, y + ep / 2, ze + (k - 1) * dz, ze + k * dz)
        add("redans%d" % i, polys, 0.008, g.get("peintre", "auto"))
    for i, c in enumerate(cfg.get("cristaux", [])):   # dôme taillé (le cristal du Cabinet)
        R, h = c["r"], c["h"]
        base = roof_height(cfg["toits"], c["x"], c["y"]) - 0.25
        rings = [(R, 0.0), (R, 0.25 + 0.25 * h), (0.8 * R, 0.25 + 0.62 * h), (0.5 * R, 0.25 + h)]
        add("cristal%d" % i, ring_polys(rings, c.get("cotes", 8), (c["x"], c["y"], base)), 0.004)
    return objs


TENT_PAINTERS = {"mat": "tuile:bois", "piquet": "tuile:bois", "corde": "tuile:corde", "dedans": "source"}
STAKE_PAINTERS = {"corde": "tube:corde"}


def build_drawn(cfg, fine, cal, work):
    """Une sorte dont le dessin du jeu est la seule vue : tente (tentes.py) ou palissade
    (pieux.py). Un objet « maison », ses parties, l'attribut « src » (point dont la projection
    sur le dessin peint chaque sommet : le côté caché prend le côté visible) et, pour les tubes
    (la corde de la palissade), « uvt » (px le long du tube et autour)."""
    sys.path.insert(0, HERE)
    import tentes, pieux
    if "tente" in cfg:
        curves = json.load(open(os.path.join(work, "courbes.json")))
        mesh, names, sk = tentes.build(cfg, cal["face"], curves, fine)
        own, uvt = dict(TENT_PAINTERS, **sk.get("peintres", {})), None   # (le dedans : interieurs.py)
        infos = sk.get("interieurs")
    else:
        prof = json.load(open(os.path.join(work, "pieux.json")))
        mesh, names = pieux.build(cfg, cal["face"], prof, fine)
        own, uvt, infos = STAKE_PAINTERS, mesh.uvt, None
    parts = Parts()
    for n in names:
        parts.id(n, own.get(n, "source"))
    me = bpy.data.meshes.new("tente")
    me.from_pydata([tuple(map(float, v)) for v in mesh.v], [], [list(f) for f in mesh.faces])
    me.update()
    me.attributes.new("part", 'INT', 'FACE').data.foreach_set("value", list(mesh.part))
    me.attributes.new("src", 'FLOAT_VECTOR', 'POINT').data.foreach_set("vector", np.array(mesh.src, np.float32).ravel())
    if uvt is not None:
        me.attributes.new("uvt", 'FLOAT_VECTOR', 'POINT').data.foreach_set("vector", np.array(uvt, np.float32).ravel())
    obj = bpy.data.objects.new("maison", me)
    bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new(); bm.from_mesh(me)   # le dessous (jamais vu : bouchons des piquets) retiré
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.normal.z < -0.9], context='FACES')
    bm.to_mesh(me); bm.free()
    obj["parts"] = parts.names
    obj["peintres"] = json.dumps(parts.painters)
    if infos:
        obj["interieurs"] = json.dumps(infos)
    return obj


def build(cfg, fine, cal=None, work=None):
    """Le modèle (un objet « maison ») ; ses parties (noms, règles de peinture propres)."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if "tente" in cfg or "pieux" in cfg:
        return build_drawn(cfg, fine, cal, work)
    parts = Parts()
    rf = roofs(cfg, parts, fine)
    top = cfg["murs"].get("hauteur") or (min(t["egout"] - t.get("epaisseur", 0.12) for t in cfg["toits"]) + 0.04
                                         if cfg.get("toits") else 0.0)   # (sans toit : une ruine, murs.ruine)
    objs = [walls(cfg, top, parts, fine)] + rf + extras(cfg, parts, fine)
    for o in bpy.context.scene.objects:
        o.select_set(o in objs)
    bpy.context.view_layer.objects.active = rf[0] if rf else objs[0]
    bpy.ops.object.join()
    house = bpy.context.active_object
    house.name = "maison"
    bm = bmesh.new(); bm.from_mesh(house.data)   # le dessous (jamais vu) retiré
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.normal.z < -0.9], context='FACES')
    bm.to_mesh(house.data); bm.free()
    house["parts"] = parts.names
    house["peintres"] = json.dumps(parts.painters)
    return house


# ================================================================== Blender : projections
def frame(view, theta, yaw=0.0):
    """(droite, haut, vers la caméra) de la vue, dans le monde ; yaw (lacet, radians) : la vue
    tournée autour du modèle vers sa droite (un dessin de 3/4 : la tente)."""
    s, c = math.sin(theta), math.cos(theta)
    if view == "face":
        R, U, D = np.array([1.0, 0, 0]), np.array([0, s, c]), np.array([0, -c, s])
    elif view == "cote":
        R, U, D = np.array([0, 1.0, 0]), np.array([-s, 0, c]), np.array([c, 0, s])
    else:
        R, U, D = np.array([-1.0, 0, 0]), np.array([0, -s, c]), np.array([0, c, s])
    if yaw:
        cy, sy = math.cos(yaw), math.sin(yaw)
        M = np.array([[cy, -sy, 0.0], [sy, cy, 0.0], [0.0, 0.0, 1.0]])
        R, U, D = M @ R, M @ U, M @ D
    return R, U, D


def project(cal, view, pts):
    """px de la vue (x, ligne) de points (n, 3)."""
    k = cal[view]
    R, U, _ = frame(view, k["theta"], k.get("lacet", 0.0))
    return np.stack([k["u0"] + k["s"] * (pts @ R), k["v0"] - k["s"] * (pts @ U)], 1)


def load_rgba(path):
    img = bpy.data.images.load(path)
    w, h = img.size
    a = np.empty(w * h * 4, np.float32)
    img.pixels.foreach_get(a)
    bpy.data.images.remove(img)
    return a.reshape(h, w, 4)[::-1].copy()


def save_rgba(path, arr):
    h, w = arr.shape[:2]
    img = bpy.data.images.new("out", w, h, alpha=True)
    img.pixels.foreach_set(np.ascontiguousarray(arr[::-1], np.float32).ravel())
    img.filepath_raw = path
    img.file_format = 'PNG'
    img.save()
    bpy.data.images.remove(img)


def triangles(obj):
    me = obj.data
    me.calc_loop_triangles()
    vi = np.empty(len(me.loop_triangles) * 3, np.int32)
    me.loop_triangles.foreach_get("vertices", vi)
    co = np.empty(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    return co.reshape(-1, 3)[vi.reshape(-1, 3)]


def raster(tris2d, w, h):
    """Silhouette (h, w) de triangles 2D (n, 3, 2) en px."""
    img = np.zeros((h, w), bool)
    for t in tris2d:
        x0, y0 = np.floor(t.min(0)).astype(int)
        x1, y1 = np.ceil(t.max(0)).astype(int)
        x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, w - 1), min(y1, h - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        e = [(xs - t[i][0]) * (t[(i + 1) % 3][1] - t[i][1]) - (ys - t[i][1]) * (t[(i + 1) % 3][0] - t[i][0]) for i in range(3)]
        inside = ((e[0] >= 0) & (e[1] >= 0) & (e[2] >= 0)) | ((e[0] <= 0) & (e[1] <= 0) & (e[2] <= 0))
        img[y0:y1 + 1, x0:x1 + 1] |= inside
    return img


def fit_view(tris, mask, view, s, theta_fixed):
    """Élévation et décalage d'une vue : la boîte du modèle projeté sur celle du dessin (largeur
    centrée, pied en bas), puis l'élévation (0..35°) et un petit décalage au meilleur IoU."""
    h, w = mask.shape
    ys, xs = np.nonzero(mask)
    k = 0.5   # (IoU à mi-résolution)
    small = mask[::2, ::2]
    pts = tris.reshape(-1, 3)

    def place(theta):
        R, U, _ = frame(view, theta)
        pr, pu = pts @ R, pts @ U
        u0 = (xs.min() + xs.max() + 1) / 2 - s * (pr.min() + pr.max()) / 2
        v0 = ys.max() + 1 + s * pu.min()
        return u0, v0

    def iou(theta, u0, v0):
        cal = {view: {"theta": theta, "s": s * k, "u0": u0 * k, "v0": v0 * k}}
        sil = raster(project(cal, view, pts).reshape(-1, 3, 2), small.shape[1], small.shape[0])
        return (sil & small).sum() / max((sil | small).sum(), 1)

    thetas = [math.radians(theta_fixed)] if theta_fixed is not None else [math.radians(t) for t in range(0, 36, 1)]
    scored = [(iou(t, *place(t)), t) for t in thetas]
    best, theta = max(scored)
    u0, v0 = place(theta)
    for _ in range(2):   # petit décalage (px)
        cands = [(iou(theta, u0 + du, v0 + dv), u0 + du, v0 + dv) for du in range(-8, 9, 2) for dv in range(-8, 9, 2)]
        best, u0, v0 = max(cands)
    return {"theta": theta, "theta_deg": round(math.degrees(theta), 1), "s": s, "u0": float(u0), "v0": float(v0),
            "w": w, "h": h, "iou": round(float(best), 3)}


def draw_edges(img, obj, cal, view, color):
    """Arêtes vives du modèle (grossier) tracées sur l'image de la vue."""
    me = obj.data
    bm = bmesh.new(); bm.from_mesh(me)
    segs = [(e.verts[0].co[:], e.verts[1].co[:]) for e in bm.edges
            if len(e.link_faces) != 2 or e.calc_face_angle(0) > math.radians(1)]
    bm.free()
    h, w = img.shape[:2]
    for a, b in segs:
        p = project(cal, view, np.array([a, b]))
        n = int(np.hypot(*(p[1] - p[0]))) * 2 + 2
        t = np.linspace(0, 1, n)[:, None]
        q = np.round(p[0] + (p[1] - p[0]) * t).astype(int)
        for dx, dy in ((0, 0), (1, 0), (0, 1)):
            ok = (q[:, 0] + dx >= 0) & (q[:, 0] + dx < w) & (q[:, 1] + dy >= 0) & (q[:, 1] + dy < h)
            img[q[ok, 1] + dy, q[ok, 0] + dx] = color


def calage_tent(kind, cfg, work):
    """Tente : le calage vient des coins du pied tracés sur le dessin (tentes.calage) ; contrôle
    calage_face.png : silhouette du modèle (rouge) et lignes relevées (jaune) sur le dessin."""
    sys.path.insert(0, HERE)
    import tentes
    img = load_rgba(os.path.join(work, "vue_face.png"))
    h, w = img.shape[:2]
    s = PX / kind_scale(kind) * cfg["vues"]["face"].get("echelle", 1.0)
    cal = {"face": tentes.calage(cfg, s, w, h)}
    house = build(cfg, fine=False, cal=cal, work=work)
    sil = raster(project(cal, "face", triangles(house).reshape(-1, 3)).reshape(-1, 3, 2), w, h)
    mask = img[..., 3] > 0.5
    cal["face"]["iou"] = round(float((sil & mask).sum() / max((sil | mask).sum(), 1)), 3)
    grey = np.array([0.55, 0.62, 0.55, 1.0], np.float32)
    over = img * img[..., 3:4] + grey * (1 - img[..., 3:4])
    edge = sil & ~(np.roll(sil, 1, 0) & np.roll(sil, -1, 0) & np.roll(sil, 1, 1) & np.roll(sil, -1, 1))
    over[edge, :3] = (1.0, 0.1, 0.1)
    curves = json.load(open(os.path.join(work, "courbes.json")))
    sk = tentes.skeleton(cfg, cal["face"], curves, True)
    for line in sk["lines"].values():
        p = np.round(project(cal, "face", tentes.resample(line, 200))).astype(int)
        ok = (p[:, 0] >= 0) & (p[:, 0] < w) & (p[:, 1] >= 0) & (p[:, 1] < h)
        over[p[ok, 1], p[ok, 0], :3] = (1.0, 0.9, 0.1)
    save_rgba(os.path.join(work, "calage_face.png"), over)
    P = sk["pts"]
    print("CALAGE face", json.dumps(cal["face"]))
    print("TENTE L %.2f m, pied %.2f m, faîte %.2f (avant) %.2f (fond) m, avancée %.2f / %.2f m" % (
        sk["L"], P["FR"][0] - P["FL"][0], P["A_f"][2], P["A_b"][2], P["E_fr"][0] - P["FR"][0], P["FL"][0] - P["E_fl"][0]))
    json.dump(cal, open(os.path.join(work, "calage.json"), "w"), indent=1)


def calage_stakes(kind, cfg, work):
    """Palissade : vue de face (élévation réglée), origine au milieu du bas du dessin ; contrôle
    calage_face.png : silhouette du modèle (rouge) sur le dessin."""
    sys.path.insert(0, HERE)
    import pieux
    img = load_rgba(os.path.join(work, "vue_face.png"))
    h, w = img.shape[:2]
    s = PX / kind_scale(kind)
    prof = json.load(open(os.path.join(work, "pieux.json")))
    cal = {"face": pieux.calage(cfg, s, w, h, prof)}
    house = build(cfg, fine=True, cal=cal, work=work)
    sil = raster(project(cal, "face", triangles(house).reshape(-1, 3)).reshape(-1, 3, 2), w, h)
    mask = img[..., 3] > 0.5
    cal["face"]["iou"] = round(float((sil & mask).sum() / max((sil | mask).sum(), 1)), 3)
    grey = np.array([0.55, 0.62, 0.55, 1.0], np.float32)
    over = img * img[..., 3:4] + grey * (1 - img[..., 3:4])
    edge = sil & ~(np.roll(sil, 1, 0) & np.roll(sil, -1, 0) & np.roll(sil, 1, 1) & np.roll(sil, -1, 1))
    over[edge, :3] = (1.0, 0.1, 0.1)
    save_rgba(os.path.join(work, "calage_face.png"), over)
    print("CALAGE face", json.dumps(cal["face"]))
    json.dump(cal, open(os.path.join(work, "calage.json"), "w"), indent=1)


def calage(kind):
    cfg, work = config(kind), work_dir(kind)
    if "tente" in cfg:
        return calage_tent(kind, cfg, work)
    if "pieux" in cfg:
        return calage_stakes(kind, cfg, work)
    house = build(cfg, fine=False)
    tris = triangles(house)
    s = PX / kind_scale(kind)
    cal = {}
    for v in VIEWS:
        path = os.path.join(work, "vue_%s.png" % v)
        if not os.path.exists(path):
            continue
        img = load_rgba(path)
        vc = cfg["vues"].get(v, {})
        cal[v] = fit_view(tris, img[..., 3] > 0.5, v, s * vc.get("echelle", 1.0), vc.get("theta"))
        over = img.copy()
        grey = np.array([0.55, 0.62, 0.55, 1.0], np.float32)
        over = over * over[..., 3:4] + grey * (1 - over[..., 3:4])
        draw_edges(over, house, cal, v, np.array([1.0, 0.1, 0.1, 1.0], np.float32))
        save_rgba(os.path.join(work, "calage_%s.png" % v), over)
        print("CALAGE", v, json.dumps(cal[v]))
    json.dump(cal, open(os.path.join(work, "calage.json"), "w"), indent=1)


# ================================================================== Blender : peinture et cuisson
ATLAS = 2048
UV_ANGLE = 60.0       # Smart UV Project : angle limite des îlots
UV_MARGIN = 12        # écart entre îlots (px)
BAKE_MARGIN = 16      # débord des couleurs cuites (px)
AO_DIST, AO_FORCE, AO_SAMPLES = 0.6, 0.35, 48   # occlusion légère (m, part, échantillons)
JPEG_QUALITY = 92
THREADS = max(1, (os.cpu_count() or 4) - 2)


def select_only(objs, active):
    for o in bpy.context.scene.objects:
        o.select_set(o in objs)
    bpy.context.view_layer.objects.active = active


def atlas_uvs(obj):
    me = obj.data
    while me.uv_layers:
        me.uv_layers.remove(me.uv_layers[0])
    me.uv_layers.new(name="atlas")
    select_only([obj], obj)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(UV_ANGLE), island_margin=0.0, area_weight=0.0,
                             correct_aspect=True, scale_to_bounds=False)
    bpy.ops.uv.select_all(action='SELECT')
    bpy.ops.uv.average_islands_scale()
    if obj.get("interieurs"):   # le dedans (sombre, vu en biais) : moins de place (interieurs.py)
        import interieurs
        bpy.ops.object.mode_set(mode='OBJECT')
        interieurs.shrink_uvs(obj)
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.select_all(action='SELECT')
    bpy.ops.uv.pack_islands(rotate=True, margin_method='FRACTION', margin=UV_MARGIN / ATLAS)
    bpy.ops.object.mode_set(mode='OBJECT')


def part_names(obj):
    return list(obj["parts"])


BOX_PARTS = ("cheminee", "marche", "cristal", "poteau", "boite", "poutre")
VARIANTS = {"toit": "_toit", "murs": "_murs"}   # partie -> variante de texture (si la vue l'a)
TOPS = {"marche": "bas"}   # dessus des marches : leur propre devant


def painter(cfg, own, part):
    """Règle de peinture d'une partie : "auto" (la vue qui la voit le mieux), "boite_face"
    (chaque côté pris sur la face de la vue de face, comme une boîte dépliée), "tourne_face"
    (chaque pan tourné vers l'avant, même incliné), "tuile:<nom>" (motif répété), ou une vue.
    Réglage de maisons.json (peintres, par nom ou par nom sans numéro), sinon de l'élément."""
    base = re.sub(r"\d+$", "", part)
    rules = cfg.get("peintres", {})
    return rules.get(part) or own.get(part) or rules.get(base) or ("boite_face" if base in BOX_PARTS else "auto")


def tile_uv(pts, n, s, w, h):
    """UV d'un motif répété (px de la vue -> taille du motif) : le plan de la face le plus proche."""
    ax = int(np.argmax(np.abs(n)))
    u, v = {2: (0, 1), 1: (0, 2), 0: (1, 2)}[ax]
    return np.stack([pts[:, u] * s / w, pts[:, v] * s / h], 1)


def roof_tile_uv(pts, n, s, w, h):
    """UV d'un motif de couverture sur un pan de toit : rangs parallèles à son égout, le haut du
    motif vers le faîte, à la longueur réelle de la pente (croupes comprises)."""
    k = math.hypot(n[0], n[1])
    hx, hy = n[0] / k, n[1] / k   # (vers le bas de la pente, à l'horizontale)
    along = -pts[:, 0] * hy + pts[:, 1] * hx
    up = -(pts[:, 0] * hx + pts[:, 1] * hy) / max(n[2], 0.3)
    return np.stack([along * s / w, up * s / h], 1)


def seen_from_face(poly, n, co, dirs, obj):
    """La face est-elle vue par la vue de face : tournée vers elle, et rien du modèle devant (rayon
    vers la caméra de la vue ; arbre BVH gardé sur l'objet le temps de la peinture) ?"""
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    d = dirs["face"]
    if n @ d < 0.1:
        return False
    tree = getattr(seen_from_face, "tree", None)
    if tree is None or seen_from_face.owner != obj.name:
        seen_from_face.tree = tree = BVHTree.FromPolygons([tuple(v) for v in co], [list(p.vertices) for p in obj.data.polygons])
        seen_from_face.owner = obj.name
    pts = co[list(poly.vertices)]   # (le centre et chaque coin : une face à moitié cachée ne l'est pas vue)
    for p in list(pts * 0.9 + pts.mean(0) * 0.1) + [pts.mean(0)]:
        if tree.ray_cast(Vector(p + n * 0.01 + d * 0.01), Vector(d))[0] is not None:
            return False
    return True


def paint_uvs(obj, cfg, cal, work, texinfo):
    """Couche UV « peinture » (px de la vue qui peint chaque face) et numéro de matériau (une
    image par vue et variante, ou un motif répété). Rend la liste des images (tex_<clé>)."""
    me = obj.data
    seen_from_face.tree = None   # (l'arbre des rayons de « face_sinon : » refait pour ce maillage)
    names = part_names(obj)
    own = json.loads(obj["peintres"])
    part = np.empty(len(me.polygons), np.int32)
    me.attributes["part"].data.foreach_get("value", part)
    co = np.empty(len(me.vertices) * 3); me.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
    centers, lows = {}, {}
    for i, name in enumerate(names):   # centre et coin bas-avant de chaque partie (boîtes dépliées)
        idx = np.nonzero(part == i)[0]
        vs = sorted({v for f in idx for v in me.polygons[f].vertices})
        centers[i] = (co[vs].min(0) + co[vs].max(0)) / 2 if vs else np.zeros(3)
        lows[i] = co[vs].min(0) if vs else np.zeros(3)
    shifts = cfg.get("decalages", {})   # partie -> [dx, dy] px ajoutés dans la vue (dessin décalé)
    thetas = cfg.get("theta_parties", {})   # partie -> élévation (degrés) propre à sa peinture
    tops = dict(TOPS, **cfg.get("dessus", {}))   # dessus d'une partie : "haut", "bas" ou "tuile:<nom>"
    dirs = {v: frame(v, cal[v]["theta"], cal[v].get("lacet", 0.0))[2] for v in cal}
    src = uvt = None   # (tente, palissade : le point dont la projection peint chaque sommet, côté caché
    for name in ("src", "uvt"):   # compris ; corde : px le long du tube et autour)
        if name in me.attributes:
            a = np.empty(len(me.vertices) * 3, np.float32)
            me.attributes[name].data.foreach_get("vector", a)
            if name == "src":
                src = a.reshape(-1, 3).astype(float)
            else:
                uvt = a.reshape(-1, 3).astype(float)
    images, mats = [], np.zeros(len(me.polygons), np.int32)
    uv = np.zeros((len(me.loops), 2))
    counts = {}
    for poly in me.polygons:
        n = np.array(poly.normal[:])
        pname = names[part[poly.index]]
        base = re.sub(r"\d+$", "", pname)
        rule = painter(cfg, own, pname)
        if n[2] > 0.7 and (tops.get(pname) or tops.get(base)):
            top = tops.get(pname) or tops.get(base)
            rule = top if top.startswith("tuile:") else rule
        else:
            top = "haut"
        pts = co[list(poly.vertices)].copy()
        li = list(poly.loop_indices)
        if rule.startswith("facade:"):   # le devant d'après le dessin, le reste (joues d'une lucarne) : un motif
            rule = "boite_face" if n[1] < -0.7 else "tuile:" + rule.split(":", 1)[1]
        if rule.startswith("toiture_arriere:"):   # le pan de devant d'après le dessin, les autres : le motif
            rule = "auto" if n[1] < -abs(n[0]) else "toiture:" + rule.split(":", 1)[1]
        if rule.startswith("toiture_joues:"):   # pans en rangs, bouts debout (joues d'un chien-assis) : le motif
            rule = ("toiture:" if n[2] >= 0.3 else "tuile:") + rule.split(":", 1)[1]
        if rule.startswith("toiture_flancs:"):   # seulement les pans tournés vers les côtés (croupes)
            rule = "toiture:" + rule.split(":", 1)[1] if abs(n[0]) > abs(n[1]) else "auto"
        if rule.startswith("toiture:") and n[2] < 0.3:   # bout de toit debout (pignon, chant) : le dessin
            rule = "auto"
        if rule.startswith("face_sinon:"):   # la vue de face là où elle voit vraiment la face (le dedans d'une
            rule = ("face" if seen_from_face(poly, n, co, dirs, obj)   # ruine : le fond visible par-dessus le
                    else "tuile:" + rule.split(":", 1)[1])            # bord), le motif ailleurs (caché)
        if rule.startswith("tube:") and uvt is not None:   # motif le long d'un tube (la corde : ses torons)
            key = "tuile_" + rule.split(":", 1)[1]
            t = texinfo[key]
            uv[li] = uvt[list(poly.vertices), :2] / np.array([t["w"], t["h"]])
        elif rule.startswith(("tuile:", "toiture:")):   # motif répété (toiture : rangs le long de l'égout de chaque pan)
            key = "tuile_" + rule.split(":", 1)[1]
            t = texinfo[key]
            s = cal.get(t["vue"], cal["face"])["s"]
            tw, th = (t["m"][0] * s, t["m"][1] * s) if "m" in t else (t["w"], t["h"])   # (image du jeu : en m)
            pts = pts - np.array(t.get("origine", [0.0, 0.0, 0.0]))
            if rule.startswith("toiture:") and math.hypot(n[0], n[1]) > 0.02:
                uv[li] = roof_tile_uv(pts, n, s, tw, th)
            else:
                uv[li] = tile_uv(pts, n, s, tw, th)
        else:
            if rule == "source" and src is not None:   # tente : peint par la projection de son point source
                pts = src[list(poly.vertices)]
                view, mirror = "face", False
            elif rule == "tourne_face":   # chaque pan tourné vers l'avant (toit : le chaume de face partout)
                c = centers[part[poly.index]]
                ang = math.atan2(n[0], -n[1]) if math.hypot(n[0], n[1]) > 0.2 else 0.0
                ca, sa = math.cos(-ang), math.sin(-ang)
                rel = pts - c
                pts = c + np.stack([rel[:, 0] * ca - rel[:, 1] * sa, rel[:, 0] * sa + rel[:, 1] * ca, rel[:, 2]], 1)
                view, mirror = "face", False
            elif rule == "boite_face":   # tourner le côté vers l'avant, autour du centre de la partie
                c, lo = centers[part[poly.index]], lows[part[poly.index]]
                if n[2] > 0.7:   # dessus : relevé au-dessus du bord avant (ou rabattu dessous : "bas")
                    k = -1.0 if top == "bas" else 1.0
                    z_edge = co[list(poly.vertices)][:, 2].max()
                    pts = np.stack([pts[:, 0], np.full(len(pts), lo[1]), z_edge + k * (pts[:, 1] - lo[1])], 1)
                else:
                    ang = math.atan2(n[0], -n[1])
                    ca, sa = math.cos(-ang), math.sin(-ang)
                    rel = pts - c
                    pts = c + np.stack([rel[:, 0] * ca - rel[:, 1] * sa, rel[:, 0] * sa + rel[:, 1] * ca, rel[:, 2]], 1)
                view, mirror = "face", False
            elif rule in ("face", "cote", "dos"):
                view, mirror = rule, rule == "cote" and n[0] < 0
            else:
                sc = {"face": n @ dirs["face"] if "face" in dirs else -9,
                      "dos": n @ dirs["dos"] if "dos" in dirs else -9,
                      "cote": abs(n[0]) * dirs["cote"][0] + n[2] * dirs["cote"][2] if "cote" in dirs else -9}
                if n[0] < 0 and cfg.get("cote_gauche") is False:   # (côté gauche différent du droit, une ruine :
                    sc["cote"] = -9                                  # peint par la face et le dos, pas en miroir)
                view = max(sc, key=sc.get)
                mirror = view == "cote" and n[0] < 0
            if mirror:
                pts[:, 0] = -pts[:, 0]
            variant = VARIANTS.get(base, "")
            if view + "_" + base in texinfo:   # peinture propre de la partie ("parties" de la vue)
                variant = "_" + base
            if base == "toit" and abs(n[2]) < 0.3:   # bout de toit debout (pignon d'une lucarne) : le dessin entier
                variant = ""
            if view + variant not in texinfo:   # (pas cette variante dans les textures en cours)
                variant = ""
            key = view + variant
            k = dict(cal[view])
            if pname in thetas or base in thetas:   # partie dessinée sous une autre élévation (toit vu de plus haut…)
                k["theta"] = math.radians(thetas.get(pname, thetas.get(base)))
            p = project({view: k}, view, pts) + np.array(shifts.get(pname, [0, 0]), float)
            uv[li, 0] = p[:, 0] / cal[view]["w"]
            uv[li, 1] = 1.0 - p[:, 1] / cal[view]["h"]
        if key not in images:
            images.append(key)
        mats[poly.index] = images.index(key)
        counts[key] = counts.get(key, 0) + 1
    layer = me.uv_layers.new(name="peinture")
    layer.data.foreach_set("uv", uv.ravel())
    me.uv_layers.active = me.uv_layers["atlas"]
    me.uv_layers["atlas"].active_render = True
    print("peinture :", counts)
    return images, mats


def new_image(name, fill, data):
    img = bpy.data.images.new(name, ATLAS, ATLAS, alpha=True, float_buffer=data)
    img.colorspace_settings.name = "Non-Color" if data else "sRGB"
    img.pixels.foreach_set(np.tile(np.array(fill[:3] + (0.0,), np.float32), ATLAS * ATLAS))
    return img


def bake_material(name, kind_, path, target, extra=None, repeat=False):
    """Matériau de cuisson : l'image d'une vue lue par la couche « peinture » ; kind_ "emit"
    (sa couleur) ou "bump" (son relief en bosselage d'un BSDF : pour la cuisson des normales).
    Motif répété : en miroir (ou tel quel : repeat)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    nodes.clear()
    uvn = nodes.new("ShaderNodeUVMap"); uvn.uv_map = "peinture"
    tex = nodes.new("ShaderNodeTexImage"); tex.image = bpy.data.images.load(path)
    tile = "tuile_" in os.path.basename(path)
    tex.extension = ('REPEAT' if repeat else 'MIRROR') if tile else 'EXTEND'
    out = nodes.new("ShaderNodeOutputMaterial")
    links.new(uvn.outputs["UV"], tex.inputs["Vector"])
    if kind_ == "emit":
        em = nodes.new("ShaderNodeEmission")
        links.new(tex.outputs["Color"], em.inputs["Color"])
        links.new(em.outputs["Emission"], out.inputs["Surface"])
    else:
        tex.image.colorspace_settings.name = "Non-Color"
        tex.interpolation = 'Cubic'
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Distance"].default_value = extra
        links.new(tex.outputs["Color"], bump.inputs["Height"])
        bsdf = nodes.new("ShaderNodeBsdfDiffuse")
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
        links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    t = nodes.new("ShaderNodeTexImage"); t.name = "cible"; t.image = target
    nodes.active = t
    return m


def set_materials(obj, mats, mat_index):
    me = obj.data
    me.materials.clear()
    for m in mats:
        me.materials.append(m)
    me.polygons.foreach_set("material_index", mat_index)
    me.update()


def pixels(img):
    a = np.empty(ATLAS * ATLAS * 4, np.float32)
    img.pixels.foreach_get(a)
    return a.reshape(-1, 4)


def save_atlas(name, arr, work, color):
    img = bpy.data.images.new(name, ATLAS, ATLAS, alpha=False)
    img.colorspace_settings.name = "sRGB" if color else "Non-Color"
    img.pixels.foreach_set(np.ascontiguousarray(arr, np.float32).ravel())
    img.filepath_raw = os.path.join(work, name + (".jpg" if color else ".png"))
    img.file_format = 'JPEG' if color else 'PNG'
    img.save(quality=JPEG_QUALITY) if color else img.save()
    img.filepath = img.filepath_raw
    img.source = 'FILE'
    img.reload()
    return img


def export_glb(obj, col, nrm, out):
    me = obj.data
    m = bpy.data.materials.new(os.path.basename(out)[:-4])
    m.use_nodes = True
    m.use_backface_culling = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    nodes.clear()
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Metallic"].default_value = 0.0
    o = nodes.new("ShaderNodeOutputMaterial")
    links.new(bsdf.outputs["BSDF"], o.inputs["Surface"])
    tc = nodes.new("ShaderNodeTexImage"); tc.image = col
    links.new(tc.outputs["Color"], bsdf.inputs["Base Color"])
    tn = nodes.new("ShaderNodeTexImage"); tn.image = nrm
    nm = nodes.new("ShaderNodeNormalMap"); nm.space = 'TANGENT'; nm.uv_map = "atlas"
    links.new(tn.outputs["Color"], nm.inputs["Color"])
    links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    set_materials(obj, [m], np.zeros(len(me.polygons), np.int32))
    if "peinture" in me.uv_layers:
        me.uv_layers.remove(me.uv_layers["peinture"])
    select_only([obj], obj)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', use_selection=True, export_tangents=True,
                              export_normals=True, export_texcoords=True, export_materials='EXPORT',
                              export_image_format='AUTO', export_attributes=False)


def convex_hull(P):
    """Enveloppe convexe (sens trigonométrique) de points 2D."""
    P = sorted(set(map(tuple, np.round(P, 4))))
    if len(P) < 3:
        return np.array(P)

    def half(pts):
        out = []
        for p in pts:
            while len(out) >= 2 and ((out[-1][0] - out[-2][0]) * (p[1] - out[-2][1])
                                     - (out[-1][1] - out[-2][1]) * (p[0] - out[-2][0])) <= 0:
                out.pop()
            out.append(p)
        return out
    lower, upper = half(P), half(P[::-1])
    return np.array(lower[:-1] + upper[:-1])


def simplify_hull(H, tol):
    """Sommets de l'enveloppe qui s'écartent de plus de tol (m) de la ligne de leurs voisins."""
    H = [np.asarray(p, float) for p in H]
    changed = True
    while changed and len(H) > 3:
        changed = False
        for i in range(len(H)):
            a, b, c = H[i - 1], H[i], H[(i + 1) % len(H)]
            d = abs((c[0] - a[0]) * (b[1] - a[1]) - (c[1] - a[1]) * (b[0] - a[0])) / max(np.linalg.norm(c - a), 1e-9)
            if d < tol:
                H.pop(i)
                changed = True
                break
    return H


def export_turn(obj, cal, work):
    """Modèle calé sur un dessin de 3/4 (lacet de la vue de face) : tourné pour que la caméra du
    jeu (droit devant) le voie comme le dessin, puis posé comme un décor (le pied de ses murs et
    pignons centré en x, son point le plus avancé en y = 0). Écrit export.json (lacet, décalage,
    emprise au sol en m) ; rien si la vue est de face."""
    yaw = cal.get("face", {}).get("lacet", 0.0)
    path = os.path.join(work, "export.json")
    if not yaw:
        if os.path.exists(path):
            os.remove(path)
        return None
    me = obj.data
    co = np.empty(len(me.vertices) * 3); me.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
    c, s = math.cos(-yaw), math.sin(-yaw)
    co = co @ np.array([[c, -s, 0.0], [s, c, 0.0], [0.0, 0.0, 1.0]]).T
    names = part_names(obj)
    part = np.empty(len(me.polygons), np.int32); me.attributes["part"].data.foreach_get("value", part)
    body = np.zeros(len(co), bool)
    for poly in me.polygons:
        if names[part[poly.index]].startswith(("mur", "pignon")):
            body[list(poly.vertices)] = True
    foot = co[body & (co[:, 2] < 0.05)]
    t = np.array([-(foot[:, 0].min() + foot[:, 0].max()) / 2.0, -foot[:, 1].min(), 0.0])
    co = co + t
    me.vertices.foreach_set("co", co.ravel())
    me.update()
    hull = convex_hull(foot[:, :2] + t[:2])
    info = {"lacet": yaw, "t": t.tolist(), "emprise": [float(np.ptp(foot[:, 0])), float(np.ptp(foot[:, 1]))],
            # (Prop.KINDS "solid_poly" : le pied en px du jeu, x à droite, y vers la caméra)
            "emprise_px": [[round(float(x) * PX), round(-float(y) * PX)] for x, y in simplify_hull(hull, 0.06)]}
    json.dump(info, open(path, "w"), indent=1)
    return info


def export_objects(objs, out):
    """Plusieurs objets (même matière) dans un glb, leurs propriétés en extras glTF."""
    select_only(objs, objs[0])
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', use_selection=True, export_tangents=True,
                              export_normals=True, export_texcoords=True, export_materials='EXPORT',
                              export_image_format='AUTO', export_attributes=False, export_extras=True)


def bake(kind):
    global ATLAS
    cfg, work = config(kind), work_dir(kind)
    ATLAS = cfg.get("atlas", 2048)   # (un petit décor : 1024 suffit)
    cal = json.load(open(os.path.join(work, "calage.json")))
    texinfo = json.load(open(os.path.join(work, "textures.json")))
    house = build(cfg, fine=True, cal=cal, work=work)
    sys.path.insert(0, HERE)
    import ajuste   # le maillage suit la silhouette et les lignes des dessins (ajuste.py)
    ajuste.fit(house, cfg, cal, work, frame, raster, load_rgba, save_rgba)
    import ouvertures   # les vraies ouvertures (embrasure, fond, sol ; battant des portes du contrat)
    doors = ouvertures.cut(house, cfg, cal)
    select_only([house], house)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35))
    atlas_uvs(house)
    images, mat_index = paint_uvs(house, cfg, cal, work, texinfo)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = THREADS
    scene.render.bake.margin = BAKE_MARGIN
    scene.render.bake.margin_type = 'EXTEND'
    scene.render.bake.use_clear = False
    scene.world = bpy.data.worlds.new("W")
    select_only([house], house)
    # la peinture
    col = new_image("couleur", (0.5, 0.5, 0.5, 1.0), False)
    rep = {k: bool(texinfo.get(k, {}).get("repete")) for k in images}
    set_materials(house, [bake_material("c_" + k, "emit", os.path.join(work, "tex_%s.png" % k), col, repeat=rep[k])
                          for k in images], mat_index)
    scene.cycles.samples = 4
    bpy.ops.object.bake(type='EMIT', target='IMAGE_TEXTURES', margin=BAKE_MARGIN, margin_type='EXTEND')
    # les normales : le relief de chaque vue en bosselage (hauteur en m = px / échelle de la vue)
    nrm = new_image("normales", (0.5, 0.5, 1.0, 1.0), True)
    bumps = []
    for k in images:
        view = texinfo[k].get("vue", k.split("_")[0])
        t = texinfo[k]
        dist = (t["relief_m"] if "relief_m" in t else t["relief_px"] / cal[view]["s"]) * cfg.get("normales", 1.0)
        bumps.append(bake_material("n_" + k, "bump", os.path.join(work, "haut_%s.png" % k), nrm, dist, rep[k]))
    set_materials(house, bumps, mat_index)
    scene.cycles.samples = 4
    bpy.ops.object.bake(type='NORMAL', target='IMAGE_TEXTURES', normal_space='TANGENT',
                        normal_r='POS_X', normal_g='POS_Y', normal_b='POS_Z', margin=BAKE_MARGIN, margin_type='EXTEND')
    # l'occlusion (légère : les recoins sous le toit, le pied de la cheminée)
    ao = new_image("ao", (1.0, 1.0, 1.0, 1.0), True)
    m = bpy.data.materials.new("ao"); m.use_nodes = True
    m.node_tree.nodes.clear()
    t = m.node_tree.nodes.new("ShaderNodeTexImage"); t.image = ao; m.node_tree.nodes.active = t
    o = m.node_tree.nodes.new("ShaderNodeOutputMaterial")
    d = m.node_tree.nodes.new("ShaderNodeBsdfDiffuse")
    m.node_tree.links.new(d.outputs["BSDF"], o.inputs["Surface"])
    set_materials(house, [m], np.zeros(len(house.data.polygons), np.int32))
    scene.world.light_settings.distance = AO_DIST
    scene.cycles.samples = AO_SAMPLES
    bpy.ops.object.bake(type='AO', target='IMAGE_TEXTURES', margin=BAKE_MARGIN, margin_type='EXTEND')
    c, a, n = pixels(col), pixels(ao), pixels(nrm)
    if house.get("interieurs"):   # le dedans : peinture ComfyUI, lumière qui entre (interieurs.py)
        import interieurs
        c = interieurs.light(house, cfg, work, c, ATLAS, BAKE_MARGIN, set_materials)
    occ = np.where(a[:, 3] > 0.5, np.clip(1.0 - a[:, 0], 0.0, 1.0), 0.0)
    c[:, :3] *= (1.0 - cfg.get("occlusion", AO_FORCE) * occ)[:, None]
    baked = c[:, 3] > 0.5
    c[~baked, :3] = c[baked, :3].mean(0)
    c[:, 3] = 1.0
    n[n[:, 3] <= 0.5, :3] = (0.5, 0.5, 1.0)
    n[:, 3] = 1.0
    col = save_atlas("atlas_couleur", c, work, True)
    nrm = save_atlas("atlas_normales", n, work, False)
    out = os.path.join(GODOT, "assets", "models", "volumes", kind + ".glb")
    turned = export_turn(house, cal, work)
    export_glb(house, col, nrm, out)   # (le jeu : un seul maillage, porte fermée)
    if doors:   # la variante du contrat des portes animées : corps et battants à part
        print("PORTES", ouvertures.export_doors(house, doors, kind, os.path.join(GODOT, "assets", "models", "volumes", "portes"),
                                                export_objects), json.dumps(doors))
    co = np.empty(len(house.data.vertices) * 3); house.data.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
    if turned:   # (emprise du pied tourné : boîte englobante, les coins du losange en plus)
        solid = [round(turned["emprise"][0] * PX), round((turned["emprise"][1] + FRONT_CLEAR) * PX)]
    elif "murs" in cfg:
        m = cfg["murs"]
        solid = [round(m["largeur"] * PX), round((m["profondeur"] + FRONT_CLEAR) * PX)]
    else:   # (palissade : le pied des pieux)
        foot = co[(co[:, 2] > -0.01) & (co[:, 2] < 0.1)]
        solid = [round(float(np.ptp(foot[:, 0])) * PX), round((float(foot[:, 1].max()) + FRONT_CLEAR) * PX)]
    poly = turned["emprise_px"] if turned else "-"
    if not turned and "murs" in cfg and cfg["murs"].get("coin", 0.0) >= min(cfg["murs"]["largeur"], cfg["murs"]["profondeur"]) / 2 - 1e-6:
        m = cfg["murs"]   # (tour ronde : son pied, un polygone à 12 côtés ; y vers la caméra)
        rr, cy = m["largeur"] / 2, m.get("y0", 0.0) + m["profondeur"] / 2
        poly = [[round(rr * math.cos(math.radians(a)) * PX), round(-(cy + rr * math.sin(math.radians(a))) * PX)]
                for a in range(-90, 270, 30)]
    print("BAKE_OK", kind, "faces", len(house.data.polygons), "taille %.2f x %.2f x %.2f m" % tuple(np.ptp(co, 0)),
          "solid_px", solid, "solid_poly", poly)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(work, "modele.blend"), compress=True)


# ================================================================== Blender : rendus de contrôle
def rendus(kind):
    cfg, work = config(kind), work_dir(kind)
    cal = json.load(open(os.path.join(work, "calage.json")))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(GODOT, "assets", "models", "volumes", kind + ".glb"))
    scene = bpy.context.scene
    obj = [o for o in scene.objects if o.type == 'MESH'][0]
    for mat in obj.data.materials:   # (après import : lumière douce, comme en jeu)
        b = [n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'][0]
        b.inputs["Roughness"].default_value = 1.0
    world = bpy.data.worlds.new("W"); scene.world = world
    world.use_nodes = True
    bg = [n for n in world.node_tree.nodes if n.type == 'BACKGROUND'][0]
    bg.inputs[0].default_value = (1, 1, 1, 1)
    bg.inputs[1].default_value = 0.9
    bpy.ops.object.light_add(type='SUN')
    sun = bpy.context.active_object
    sun.data.energy = 2.2
    sun.rotation_euler = (math.radians(50), 0, math.radians(-30))   # (glTF importé : Y en haut -> Z en haut)
    scene.render.engine = 'BLENDER_EEVEE'
    scene.view_settings.view_transform = 'Standard'
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = 'RGBA'
    co = np.array([obj.matrix_world @ v.co for v in obj.data.vertices])
    target = Vector(((co[:, 0].min() + co[:, 0].max()) / 2, (co[:, 1].min() + co[:, 1].max()) / 2, co[:, 2].max() * 0.45))

    def shoot(name, yaw, pitch, res=640, dist=18.0, fov=38.0):
        cam_data = bpy.data.cameras.new(name)
        cam_data.angle = math.radians(fov)
        cam = bpy.data.objects.new(name, cam_data)
        scene.collection.objects.link(cam)
        a, p = math.radians(yaw), math.radians(pitch)
        cam.location = target + Vector((math.sin(a) * math.cos(p), -math.cos(a) * math.cos(p), math.sin(p))) * dist
        cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
        scene.camera = cam
        scene.render.resolution_x = scene.render.resolution_y = res
        scene.render.filepath = os.path.join(work, "rendu_%s.png" % name)
        bpy.ops.render.render(write_still=True)

    shoot("jeu", 0, 40)
    shoot("g45", -45, 35)
    shoot("d45", 45, 35)
    shoot("cote90", 90, 20)
    shoot("dos180", 180, 30)
    turn = os.path.join(work, "export.json")
    turn = json.load(open(turn)) if os.path.exists(turn) else None
    if turn or not os.path.exists(os.path.join(work, "vue_cote.png")):   # (seul le dessin : la caméra du jeu
        shoot("jeu_g30", -30, 40)                                          # au bord de l'écran, le côté caché)
        shoot("jeu_d30", 30, 40)
        shoot("g90", -90, 20)
    yaw_e = turn["lacet"] if turn else 0.0
    ce, se = math.cos(-yaw_e), math.sin(-yaw_e)
    turn_m = np.array([[ce, -se, 0.0], [se, ce, 0.0], [0.0, 0.0, 1.0]])
    shift = np.array(turn["t"]) if turn else np.zeros(3)
    for v, k in cal.items():   # calé : caméra orthographique de la vue, à sa résolution
        R, U, D = frame(v, k["theta"], k.get("lacet", 0.0))
        center = turn_m @ (R * ((k["w"] / 2 - k["u0"]) / k["s"]) + U * ((k["v0"] - k["h"] / 2) / k["s"])) + shift
        R, U, D = Vector(turn_m @ R), Vector(turn_m @ U), Vector(turn_m @ D)
        center = Vector(center)
        cam_data = bpy.data.cameras.new("cal_" + v)
        cam_data.type = 'ORTHO'
        cam_data.ortho_scale = max(k["w"], k["h"]) / k["s"]
        cam = bpy.data.objects.new("cal_" + v, cam_data)
        scene.collection.objects.link(cam)
        cam.location = center + D * 30.0
        cam.rotation_euler = (-D).to_track_quat('-Z', 'Y').to_euler()
        scene.camera = cam
        scene.render.resolution_x, scene.render.resolution_y = k["w"], k["h"]
        scene.render.filepath = os.path.join(work, "rendu_cale_%s.png" % v)
        bpy.ops.render.render(write_still=True)
    a = load_rgba(os.path.join(work, "rendu_cote90.png"))   # côté et dos côte à côte
    b = load_rgba(os.path.join(work, "rendu_dos180.png"))
    save_rgba(os.path.join(work, "rendu_cote_dos.png"), np.concatenate([a[:, 100:540], b[:, 100:540]], 1))
    variant = os.path.join(GODOT, "assets", "models", "volumes", "portes", kind + ".glb")
    if cfg.get("ouvertures") and any(o.get("porte") for o in cfg["ouvertures"]) and os.path.exists(variant):
        rendus_portes(kind, work, variant)
    print("RENDUS_OK", kind)


def rendus_portes(kind, work, path):
    """Variante du contrat : la porte fermée, puis ouverte (angle « ouverture » autour de l'axe des
    gonds), de 3/4 des deux côtés : on doit voir le dedans. -> porte_fermee.png, porte_ouverte_g/d.png."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    scene = bpy.context.scene
    world = bpy.data.worlds.new("W"); scene.world = world
    world.use_nodes = True
    bg = [n for n in world.node_tree.nodes if n.type == 'BACKGROUND'][0]
    bg.inputs[0].default_value = (1, 1, 1, 1)
    bg.inputs[1].default_value = 0.9
    bpy.ops.object.light_add(type='SUN')
    sun = bpy.context.active_object
    sun.data.energy = 2.2
    sun.rotation_euler = (math.radians(50), 0, math.radians(-30))
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, -0.005))   # (un sol : le seuil, le dedans)
    ground = bpy.context.active_object
    gm = bpy.data.materials.new("sol"); gm.use_nodes = True
    [n for n in gm.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'][0].inputs["Base Color"].default_value = (0.42, 0.45, 0.36, 1)
    ground.data.materials.append(gm)
    scene.render.engine = 'BLENDER_EEVEE'
    scene.view_settings.view_transform = 'Standard'
    leaves = [o for o in scene.objects if o.type == 'MESH' and "ouverture" in o.keys()]
    target = sum((o.location for o in leaves), Vector()) / max(len(leaves), 1) + Vector((0, 0, 1.0))

    def shoot(name, yaw, pitch, dist=9.0):
        cam_data = bpy.data.cameras.new(name)
        cam_data.angle = math.radians(38)
        cam = bpy.data.objects.new(name, cam_data)
        scene.collection.objects.link(cam)
        a, p = math.radians(yaw), math.radians(pitch)
        cam.location = target + Vector((math.sin(a) * math.cos(p), -math.cos(a) * math.cos(p), math.sin(p))) * dist
        cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
        scene.camera = cam
        scene.render.resolution_x = scene.render.resolution_y = 480
        scene.render.filepath = os.path.join(work, "porte_%s.png" % name)
        bpy.ops.render.render(write_still=True)

    shoot("fermee", -35, 25)
    for o in leaves:   # (glTF : autour de Y ; Blender : autour de Z, même sens)
        o.rotation_mode = 'XYZ'
        o.rotation_euler.z += math.radians(float(o["ouverture"]))
    shoot("ouverte_g", -35, 25)
    shoot("ouverte_d", 35, 25)
    print("PORTES_RENDUS", kind, [(o.name, float(o["ouverture"]), list(o["seuil"])) for o in leaves])


def guide(kind):
    """Le guide de la peinture ComfyUI de chaque pièce (interieurs.py) : le modèle fin, ajusté,
    ses ouvertures et pièces, sans cuisson."""
    cfg, work = config(kind), work_dir(kind)
    cal = json.load(open(os.path.join(work, "calage.json")))
    texinfo = json.load(open(os.path.join(work, "textures.json")))
    house = build(cfg, fine=True, cal=cal, work=work)
    sys.path.insert(0, HERE)
    import ajuste, ouvertures, interieurs
    ajuste.fit(house, cfg, cal, work, frame, raster, load_rgba, save_rgba)
    ouvertures.cut(house, cfg, cal)
    interieurs.guides(house, cfg, work, kind, texinfo, cal, load_rgba, save_rgba)


def rendus_interieurs(kind):
    sys.path.insert(0, HERE)
    import interieurs
    interieurs.rendus(kind, work_dir(kind))


def essai_ajuste(kind):
    """Contrôle rapide de l'ajustement (sans cuisson) : contour du modèle ajusté (rouge) et bas de
    ses toits (jaune) tracés sur chaque vue -> ajuste_contour_<v>.png."""
    cfg, work = config(kind), work_dir(kind)
    cal = json.load(open(os.path.join(work, "calage.json")))
    house = build(cfg, fine=True)
    sys.path.insert(0, HERE)
    import ajuste
    ajuste.fit(house, cfg, cal, work, frame, raster, load_rgba, save_rgba)
    for v, prof in zip([v for v in ("face", "dos", "cote") if v in cal], ajuste.PROFILES):
        for key in ("haut", "egout", "bas"):
            print("PROFIL", v, key, " ".join("%.0f" % x if np.isfinite(x) else "." for x in prof[key][::20]))
    names = list(house["parts"])
    tri_v, tri_part = ajuste._tri_data(house)
    co = np.empty(len(house.data.vertices) * 3); house.data.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
    roof = np.array([names[p].startswith("toit") for p in tri_part])
    for v, k in cal.items():
        img = load_rgba(os.path.join(work, "vue_%s.png" % v))
        R, U, _ = frame(v, k["theta"])
        p = co.copy()
        if v == "cote":
            p[:, 0] = np.abs(p[:, 0])
        p2 = np.stack([k["u0"] + k["s"] * (p @ R), k["v0"] - k["s"] * (p @ U)], 1)
        out = img.copy()
        grey = np.array([0.55, 0.62, 0.55, 1.0], np.float32)
        out = out * out[..., 3:4] + grey * (1 - out[..., 3:4])
        for mask, col in ((raster(p2[tri_v], k["w"], k["h"]), (1, 0.1, 0.1)), (raster(p2[tri_v[roof]], k["w"], k["h"]), (1, 0.9, 0.1))):
            edge = mask & ~(np.roll(mask, 1, 0) & np.roll(mask, -1, 0) & np.roll(mask, 1, 1) & np.roll(mask, -1, 1))
            out[edge, :3] = col
        save_rgba(os.path.join(work, "ajuste_contour_%s.png" % v), out)
    print("ESSAI_OK", kind)


if __name__ == "__main__":
    if IN_BLENDER:
        mode, kind = sys.argv[sys.argv.index("--") + 1:][:2]
        for step in {"calage": [calage], "bake": [bake], "rendus": [rendus], "tout": [calage, bake, rendus],
                     "ajuste": [essai_ajuste], "guide": [guide], "rendus_interieurs": [rendus_interieurs]}[mode]:
            step(kind)
    else:
        sys.path.insert(0, HERE)
        import interieurs
        mode, args = sys.argv[1], sys.argv[2:]
        if mode == "planche_interieurs":   # (toutes les sortes à pièces, ou celles données)
            interieurs.planche(args or [k for k, v in json.load(open(os.path.join(HERE, "maisons.json"), encoding="utf-8")).items()
                                        if isinstance(v, dict) and (v.get("pieces") or v.get("ouvertures") or v.get("tente", {}).get("interieur"))])
        elif mode == "peindre":
            interieurs.peindre(args[0], config(args[0]), work_dir(args[0]), args[1] if len(args) > 1 else None)
        else:
            {"textures": pil_textures, "planche": pil_planche, "vues": pil_vues}[mode](args[0])
