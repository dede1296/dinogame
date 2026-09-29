"""Intérieurs des vraies ouvertures (maisons.py, ouvertures.py, tentes.py) : derrière une porte, une
embrasure sans battant, une fenêtre sans vitre, un étal ou l'entrée d'une tente, le début d'une
pièce, vue en biais par la caméra du jeu (vers le nord, plongée de 40°).

Pièce (maisons.json, « pieces » : boîtes x, y, z du repère du modèle, m ; une ouverture y mène par
« piece » : son embrasure va de la façade au devant de la boîte) : murs du fond et des côtés, sol,
plafond, peints de motifs répétés (« tuiles » : une image du jeu, "jeu": "ground/plancher.png",
ou un rectangle de la vue : l'enduit du bâtiment) ; pas de mur de façade (jamais vu du dehors).
Meubles (« meubles ») : boîtes et cylindres simples, chacun son motif (côtés) ; tente
(maisons.json, tente.interieur) : sa doublure peinte par la toile du dessin, un sol, des meubles.

Détails peints (ComfyUI, en repli de nano-banana) :
  blender -b -P maisons.py -- guide <sorte>
      guide de chaque pièce vue par son « projecteur » (orthographique, de face, élévation 35°) :
      volumes simples, motifs du jeu, « cartes » (images du jeu posées à plat sur un mur, un
      meuble ou le sol : seulement dans le guide), contours bruns -> guide_<clé>.png ; ce qui sera
      peint (meubles et cartes) -> masque_<clé>.png ; projecteur_<clé>.json
  python maisons.py peindre <sorte> [clé]
      img2img ComfyUI (SD 1.5 + LoRA ambrelune_style 0,8 + IPAdapter 0,6 sur une image du jeu
      voisine, « decor » : prompt, ref, denoise, seed) -> peint_<clé>.png, copié dans
      generated_imgs/interieurs/<sorte>_<clé>.png (liste « À refaire avec nano-banana »)
Cuisson (maisons.py bake, après la peinture des motifs) : position, normale et partie de chaque
texel du dedans cuites dans l'atlas ; la peinture ComfyUI posée par le projecteur (là où le masque
le dit, sur ce que le projecteur voit : lancer de rayons), puis l'éclairage : la lumière qui entre
par les ouvertures de la pièce (éclairement d'une source étendue : plus sombre au fond et dans les
coins), un fond, les ombres un peu chaudes ; l'occlusion de la cuisson ajoute les recoins. Le
dedans prend moins de place dans l'atlas (UV_DEDANS).
  blender -b -P maisons.py -- rendus_interieurs <sorte>   contrôles (couleur cuite, sans lumière :
      comme en jeu) : de face, de 3/4, caméra du jeu, et porte ouverte (variante des portes)
  python maisons.py planche_interieurs     generated_imgs/captures/interieurs_ouvertures.png
"""
import json
import math
import os
import shutil
import time

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.normpath(os.path.join(HERE, "..", ".."))
ART = os.path.join(GODOT, "assets", "art")
COMFY_URL = "http://127.0.0.1:8188"
COMFY_DIR = "C:/ComfyUI_windows_portable/ComfyUI"
PEINTS = "C:/Users/Greg/Dinogame/generated_imgs/interieurs"
CAPTURES = "C:/Users/Greg/Dinogame/generated_imgs/captures"
WORK_ROOT = "C:/ComfyUI_windows_portable/blender_tests/maisons"

ELEVATION = 35.0      # degrés : le projecteur (de face, un peu sous la caméra du jeu : les devants mieux vus)
GUIDE_PX = 640        # grand côté du guide (px, multiple de 64 : SD 1.5)
UV_DEDANS = 0.55      # densité du dedans dans l'atlas (part de celle du dehors : sombre, vu en biais)
LUMIERE = {"fond": 0.18, "gain": 2.5, "max": 0.92, "ombre": [0.84, 0.74, 0.72]}
MURS = {"murs": "tuile:enduit", "sol": "tuile:plancher", "plafond": "tuile:plancher"}
CONTOUR = (0.23, 0.14, 0.10)   # contours bruns du guide (le trait du jeu)
NEGATIF = ("photo, realistic, 3d render, cgi, flat grey shading, sketch, thin lines, pastel, washed out, "
           "blurry, low quality, deformed, people, person, character, animal, text, watermark, frame, border")
STYLE = ("ambrelune style, cute cartoon game asset, hand painted, bold thick dark brown outline, clean lineart, "
         "warm muted colors, soft shading")


# ================================================================== géométrie (Blender, bmesh)
def _orient(f, toward):
    f.normal_update()
    if f.normal.dot(toward - f.calc_center_median()) < 0:
        f.normal_flip()


def furniture_polys(m):
    """Polygones d'un meuble : boîte (x, y, z : bornes) sans son dessous, ou cylindre (debout :
    x, y, r, z = [bas, haut] ; couché, "axe": "x" : x = [début, fin], y, z, r), n côtés."""
    if "r" in m:
        n = m.get("cotes", 10)
        if m.get("axe", "z") == "z":
            cx, cy, (h0, h1) = m["x"], m["y"], m["z"]
            pt = lambda i, h: (cx + m["r"] * math.cos(2 * math.pi * (i + 0.5) / n),
                               cy + m["r"] * math.sin(2 * math.pi * (i + 0.5) / n), h)
            caps = [h1]
        else:
            (h0, h1), cy, cz = m["x"], m["y"], m["z"]
            pt = lambda i, h: (h, cy + m["r"] * math.cos(2 * math.pi * (i + 0.5) / n),
                               cz + m["r"] * math.sin(2 * math.pi * (i + 0.5) / n))
            caps = [h0, h1]
        polys = [[pt(i, h0), pt((i + 1) % n, h0), pt((i + 1) % n, h1), pt(i, h1)] for i in range(n)]
        polys += [[pt(i, h) for i in range(n)] for h in caps]
        return polys
    (x0, x1), (y0, y1), (z0, z1) = m["x"], m["y"], m["z"]
    v = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    return [[v[i] for i in f] for f in ((4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7))]


def add_furniture(bm, layer, pid, meubles, prefix):
    """Les meubles (parties <prefix>_meuble<j>, leur motif) : faces tournées vers le dehors."""
    from mathutils import Vector
    names = []
    for j, m in enumerate(meubles):
        name = "%s_meuble%d" % (prefix, j)
        pi = pid(name, m.get("peintre", "tuile:plancher"))
        names.append(name)
        polys = furniture_polys(m)
        c = Vector(np.mean([p for poly in polys for p in poly], 0).tolist())
        for poly in polys:
            f = bm.faces.new([bm.verts.new(p) for p in poly])
            f[layer] = pi
            _orient(f, c)
            f.normal_flip()   # (vers le dehors : à l'opposé du centre)
    return names


def build_room(bm, layer, pid, rc, r):
    """La boîte de la pièce r (fond, côtés, sol, plafond : faces tournées vers le dedans) et ses
    meubles ; rend les noms de ses parties."""
    from mathutils import Vector
    (x0, x1), (y0, y1), (z0, z1) = rc["x"], rc["y"], rc["z"]
    c = Vector(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    quads = {"murs": [[(x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1)],
                      [(x0, y0, z0), (x0, y1, z0), (x0, y1, z1), (x0, y0, z1)],
                      [(x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1)]],
             "sol": [[(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]],
             "plafond": [[(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]]}
    names = []
    for key, polys in quads.items():
        name = "piece%d_%s" % (r, key)
        pi = pid(name, rc.get(key, MURS[key]))
        names.append(name)
        for poly in polys:
            f = bm.faces.new([bm.verts.new(p) for p in poly])
            f[layer] = pi
            _orient(f, c)
    return names + add_furniture(bm, layer, pid, rc.get("meubles", []), "piece%d" % r)


def check_room(cfg, rc, r):
    """La pièce doit rester dans les murs (sinon elle perce la maison) : avertit."""
    m = cfg.get("murs")
    if not m:
        return
    hw, y0 = m["largeur"] / 2 - 0.08, m.get("y0", 0.0)
    top = m.get("hauteur") or min(t["egout"] - t.get("epaisseur", 0.12) for t in cfg["toits"])
    (x0, x1), (ya, yb), (_, z1) = rc["x"], rc["y"], rc["z"]
    if x0 < -hw or x1 > hw or yb > y0 + m["profondeur"] - 0.08 or z1 > top - 0.05:
        print("PIECE %d : hors des murs ? x %s y %s z1 %.2f (murs ±%.2f, fond %.2f, haut %.2f)"
              % (r, rc["x"], rc["y"], z1, hw, y0 + m["profondeur"], top))


# ================================================================== atlas, cuisson (Blender)
def inside_parts(obj):
    """Noms des parties du dedans (toutes les pièces)."""
    infos = json.loads(obj.get("interieurs", "[]"))
    return sorted({p for i in infos for p in i["parts"]})


def shrink_uvs(obj, k=UV_DEDANS):
    """Îlots du dedans réduits (avant l'empaquetage) : moins de place dans l'atlas."""
    inner = inside_parts(obj)
    if not inner:
        return
    names = list(obj["parts"])
    ids = np.array([names.index(p) for p in inner if p in names])
    me = obj.data
    part = np.empty(len(me.polygons), np.int32)
    me.attributes["part"].data.foreach_get("value", part)
    loops = np.empty(len(me.loops), np.int32)
    me.loops.foreach_get("vertex_index", loops)   # (seulement pour la taille)
    loop_face = np.repeat(np.arange(len(me.polygons)), [p.loop_total for p in me.polygons])
    uv = np.empty(len(me.loops) * 2, np.float32)
    me.uv_layers["atlas"].data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)
    sel = np.isin(part[loop_face], ids)
    uv[sel] *= k
    me.uv_layers["atlas"].data.foreach_set("uv", uv.ravel())


def _emit_material(name, target, color=None, node_fn=None):
    import bpy
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    nodes.clear()
    em = nodes.new("ShaderNodeEmission")
    out = nodes.new("ShaderNodeOutputMaterial")
    links.new(em.outputs["Emission"], out.inputs["Surface"])
    if color is not None:
        em.inputs["Color"].default_value = tuple(color) + (1.0,)
    if node_fn:
        links.new(node_fn(nodes, links), em.inputs["Color"])
    t = nodes.new("ShaderNodeTexImage"); t.name = "cible"; t.image = target
    nodes.active = t
    return m


def bake_info(house, atlas, margin, set_materials):
    """Position (bornes du modèle -> 0..1), normale (vraie normale de la face) et partie de chaque
    texel : trois cuissons « émission » à un échantillon. Rend (P, N, partie ; -1 : rien)."""
    import bpy
    me = house.data
    co = np.empty(len(me.vertices) * 3); me.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
    lo, hi = co.min(0) - 0.01, co.max(0) + 0.01
    part = np.empty(len(me.polygons), np.int32)
    me.attributes["part"].data.foreach_get("value", part)
    n_parts = len(list(house["parts"]))
    scene = bpy.context.scene
    scene.cycles.samples = 1
    out = []
    for what in ("position", "normale", "partie"):
        img = bpy.data.images.new("info_" + what, atlas, atlas, alpha=True, float_buffer=True)
        img.colorspace_settings.name = "Non-Color"
        img.pixels.foreach_set(np.zeros(atlas * atlas * 4, np.float32))
        if what == "partie":
            mats = [_emit_material("id%d" % i, img, color=((i + 0.5) / 256.0,) * 3) for i in range(n_parts)]
            set_materials(house, mats, part)
        else:
            def chain(nodes, links, what=what):
                geo = nodes.new("ShaderNodeNewGeometry")
                a = nodes.new("ShaderNodeVectorMath"); a.operation = 'SUBTRACT'
                b = nodes.new("ShaderNodeVectorMath"); b.operation = 'MULTIPLY'
                if what == "position":
                    links.new(geo.outputs["Position"], a.inputs[0])
                    a.inputs[1].default_value = tuple(lo)
                    b.inputs[1].default_value = tuple(1.0 / (hi - lo))
                else:
                    links.new(geo.outputs["True Normal"], a.inputs[0])
                    a.inputs[1].default_value = (-1.0, -1.0, -1.0)
                    b.inputs[1].default_value = (0.5, 0.5, 0.5)
                links.new(a.outputs["Vector"], b.inputs[0])
                return b.outputs["Vector"]
            set_materials(house, [_emit_material("info_" + what, img, node_fn=chain)], np.zeros(len(me.polygons), np.int32))
        bpy.ops.object.bake(type='EMIT', target='IMAGE_TEXTURES', margin=margin, margin_type='EXTEND')
        a = np.empty(atlas * atlas * 4, np.float32)
        img.pixels.foreach_get(a)
        out.append(a.reshape(-1, 4))
        bpy.data.images.remove(img)
    P = lo + out[0][:, :3] * (hi - lo)
    N = out[1][:, :3] * 2.0 - 1.0
    N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-6)
    pid = np.where(out[2][:, 3] > 0.5, np.floor(out[2][:, 0] * 256.0).astype(np.int32), -1)
    return P, N, pid


def opening_samples(op, step=0.12):
    """Points d'une ouverture (poly [[x, z]…] dans le plan y, lumière vers +y * sens) et l'aire
    de chacun : grille sur sa boîte, gardés dans le polygone."""
    poly = np.array(op["poly"], float)
    (xa, za), (xb, zb) = poly.min(0), poly.max(0)
    nx, nz = max(3, int(math.ceil((xb - xa) / step))), max(3, int(math.ceil((zb - za) / step)))
    xs = xa + (np.arange(nx) + 0.5) * (xb - xa) / nx
    zs = za + (np.arange(nz) + 0.5) * (zb - za) / nz
    X, Z = np.meshgrid(xs, zs)
    pts = np.stack([X.ravel(), Z.ravel()], 1)
    inside = np.zeros(len(pts), bool)   # (pair-impair)
    for (x1, z1), (x2, z2) in zip(poly, np.roll(poly, -1, 0)):
        cross = ((z1 > pts[:, 1]) != (z2 > pts[:, 1]))
        xi = x1 + (pts[:, 1] - z1) * (x2 - x1) / np.where(z2 != z1, z2 - z1, 1e-9)
        inside ^= cross & (pts[:, 0] < xi)
    pts = pts[inside]
    S = np.stack([pts[:, 0], np.full(len(pts), op["y"]), pts[:, 1]], 1)
    return S, (xb - xa) / nx * (zb - za) / nz


def irradiance(P, N, openings):
    """Éclairement (0..~0,5) de points (P, N) par des ouvertures de luminance 1 (source étendue :
    cos au point × cos à l'ouverture / (pi r²) dA), sans ombres (l'occlusion les ajoute)."""
    E = np.zeros(len(P))
    for op in openings:
        S, dA = opening_samples(op)
        m = np.array([0.0, float(op.get("sens", 1.0)), 0.0])
        for a in range(0, len(P), 20000):
            d = S[None, :, :] - P[a:a + 20000, None, :]
            r2 = np.maximum((d * d).sum(2), 0.02)
            r = np.sqrt(r2)
            cp = np.clip((d * N[a:a + 20000, None, :]).sum(2) / r, 0.0, None)
            cs = np.clip(-(d @ m) / r, 0.0, None)
            E[a:a + 20000] += (cp * cs / r2).sum(1) * dA / math.pi
    return E


def load_image(path):
    import bpy
    img = bpy.data.images.load(path)
    w, h = img.size
    a = np.empty(w * h * 4, np.float32)
    img.pixels.foreach_get(a)
    bpy.data.images.remove(img)
    return a.reshape(h, w, 4)[::-1].copy()   # (ligne 0 en haut)


def bilinear(img, u, v):
    h, w = img.shape[:2]
    u = np.clip(u - 0.5, 0, w - 1.001)
    v = np.clip(v - 0.5, 0, h - 1.001)
    i0, j0 = np.floor(v).astype(int), np.floor(u).astype(int)
    fv, fu = (v - i0)[:, None], (u - j0)[:, None]
    return ((img[i0, j0] * (1 - fu) + img[i0, j0 + 1] * fu) * (1 - fv)
            + (img[i0 + 1, j0] * (1 - fu) + img[i0 + 1, j0 + 1] * fu) * fv)


def projector_uv(pj, P):
    R, U, C = np.array(pj["R"]), np.array(pj["U"]), np.array(pj["C"])
    rel = P - C
    return pj["w"] / 2 + pj["s"] * (rel @ R), pj["h"] / 2 - pj["s"] * (rel @ U)


def guide_parts(info):
    """Les parties que le projecteur voit (la pièce, ses meubles : pas les embrasures, ni la
    doublure d'une tente, qui ferait peindre une tente à ComfyUI au lieu de ce qu'il y a dedans)."""
    return [p for p in info["parts"] if not p.startswith("ouverture") and p != "dedans"]


def paint_decor(house, info, work, c, P, N, sel):
    """La peinture ComfyUI de la pièce posée par son projecteur sur les texels sel qu'il voit,
    là où le masque le dit (meubles, cartes)."""
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    key = info["cle"]
    paths = [os.path.join(work, f % key) for f in ("peint_%s.png", "masque_%s.png", "projecteur_%s.json")]
    if not all(os.path.exists(p) for p in paths):
        print("INTERIEUR %s : pas de peinture (guide, peindre)" % key)
        return 0
    paint, mask = load_image(paths[0]), load_image(paths[1])
    pj = json.load(open(paths[2]))
    idx = np.nonzero(sel)[0]
    u, v = projector_uv(pj, P[idx])
    D = np.array(pj["D"])
    facing = np.clip((N[idx] @ D - 0.12) / 0.25, 0.0, 1.0)
    inside = (u > 1) & (u < pj["w"] - 2) & (v > 1) & (v < pj["h"] - 2)
    w = np.zeros(len(idx))
    w[inside] = bilinear(mask, u[inside], v[inside])[:, 0] * facing[inside]
    cand = np.nonzero(w > 0.01)[0]
    # vu du projecteur ? (rayon vers lui, contre les faces de la pièce seulement, embrasures
    # exceptées ; une face vue de dos ne cache rien : le guide les écarte aussi)
    me = house.data
    names = list(house["parts"])
    ids = {names.index(p) for p in guide_parts(info) if p in names}
    part = np.empty(len(me.polygons), np.int32)
    me.attributes["part"].data.foreach_get("value", part)
    verts = [v_.co.copy() for v_ in me.vertices]
    polys = [list(p.vertices) for p in me.polygons if part[p.index] in ids]
    bvh = BVHTree.FromPolygons(verts, polys)
    Dv = Vector(D.tolist())
    for k in cand:
        o = Vector((P[idx[k]] + N[idx[k]] * 0.01).tolist())
        for _ in range(8):
            loc, nrm, _, _ = bvh.ray_cast(o, Dv, 20.0)
            if loc is None:
                break
            if nrm.dot(Dv) > 0.01:
                w[k] = 0.0
                break
            o = loc + Dv * 0.002
    col = bilinear(paint, u[cand], v[cand])[:, :3]
    c[idx[cand], :3] = c[idx[cand], :3] * (1 - w[cand, None]) + col * w[cand, None]
    return int((w > 0.5).sum())


def light(house, cfg, work, c, atlas, margin, set_materials):
    """Le dedans de chaque pièce : peinture ComfyUI (si faite), puis éclairage cuit dans la
    couleur c (texels de l'atlas, (n, 4)). Écrit interieurs.json (pour les rendus)."""
    infos = json.loads(house.get("interieurs", "[]"))
    if not infos:
        return c
    P, N, pid = bake_info(house, atlas, margin, set_materials)
    names = list(house["parts"])
    for info in infos:
        ids = [names.index(p) for p in info["parts"] if p in names]
        sel = np.isin(pid, ids)
        painted = paint_decor(house, info, work, c, P, N, sel) if info.get("decor") else 0
        lu = dict(LUMIERE, **info.get("lumiere", {}))
        E = irradiance(P[sel], N[sel], info["ouvertures"])
        L = np.clip(lu["fond"] + lu["gain"] * E, 0.0, lu["max"])
        tint = np.array(lu["ombre"])[None, :] * (1 - L[:, None]) + L[:, None]
        c[sel, :3] *= L[:, None] * tint
        print("INTERIEUR", info["cle"], "texels", int(sel.sum()), "peints", painted,
              "lumière %.2f..%.2f (moy. %.2f)" % (L.min(), L.max(), L.mean()) if sel.any() else "")
    json.dump(infos, open(os.path.join(work, "interieurs.json"), "w"), indent=1)
    return c


# ================================================================== guide (Blender)
def _tile_material(name, path, size_m, color=None, origin=(0.0, 0.0, 0.0)):
    """Motif répété posé en boîte (coordonnées de l'objet - origine, / taille en m), ou couleur unie."""
    import bpy
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.use_backface_culling = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    bsdf = [n for n in nodes if n.type == 'BSDF_PRINCIPLED'][0]
    bsdf.inputs["Roughness"].default_value = 1.0
    if path:
        tc = nodes.new("ShaderNodeTexCoord")
        mp = nodes.new("ShaderNodeMapping")
        mp.inputs["Scale"].default_value = (1.0 / size_m[0], 1.0 / size_m[0], 1.0 / size_m[1])
        mp.inputs["Location"].default_value = (-origin[0] / size_m[0], -origin[1] / size_m[0], -origin[2] / size_m[1])
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(path)
        tex.projection = 'BOX'
        tex.projection_blend = 0.15
        links.new(tc.outputs["Object"], mp.inputs["Vector"])
        links.new(mp.outputs["Vector"], tex.inputs["Vector"])
        links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = tuple(color) + (1.0,)
    return m


def _card(scene, cfg, card, i, kind):
    """Une carte : une image du jeu (assets/art/…, ou "vue:face" + "rect" : un morceau du dessin
    de la sorte) sur un plan : debout face au dehors (y), ou à plat ("plan": "sol")."""
    import bpy
    src = card["image"]
    if src.startswith("vue:"):
        from_view = os.path.join(WORK_ROOT, kind, "vue_%s.png" % src.split(":", 1)[1])
        img = bpy.data.images.load(from_view)
    else:
        img = bpy.data.images.load(os.path.join(ART, src))
    iw, ih = img.size
    x0, y0, x1, y1 = card.get("rect", [0, 0, iw, ih])
    (a, b) = card["x"]
    hgt = (b - a) * (y1 - y0) / max(x1 - x0, 1)
    me = bpy.data.meshes.new("carte%d" % i)
    if card.get("plan") == "sol":
        z = card["z"]
        yb = card["y"]
        verts = [(a, yb, z), (b, yb, z), (b, yb + hgt, z), (a, yb + hgt, z)]
        uvs = [(x0, ih - y1), (x1, ih - y1), (x1, ih - y0), (x0, ih - y0)]
    else:
        y, z = card["y"], card["z"]
        verts = [(a, y, z), (b, y, z), (b, y, z + hgt), (a, y, z + hgt)]
        uvs = [(x0, ih - y1), (x1, ih - y1), (x1, ih - y0), (x0, ih - y0)]
    me.from_pydata(verts, [], [(0, 1, 2, 3)])
    me.update()
    uvl = me.uv_layers.new(name="UV")
    for li, (u, v) in enumerate(uvs):
        uvl.data[li].uv = (u / iw, v / ih)
    obj = bpy.data.objects.new("carte%d" % i, me)
    scene.collection.objects.link(obj)
    m = bpy.data.materials.new("carte%d" % i)
    m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    nodes.clear()
    tex = nodes.new("ShaderNodeTexImage"); tex.image = img
    bsdf = nodes.new("ShaderNodeBsdfPrincipled"); bsdf.inputs["Roughness"].default_value = 1.0
    tr = nodes.new("ShaderNodeBsdfTransparent")
    mix = nodes.new("ShaderNodeMixShader")
    out = nodes.new("ShaderNodeOutputMaterial")
    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(tex.outputs["Alpha"], mix.inputs["Fac"])
    links.new(tr.outputs["BSDF"], mix.inputs[1])
    links.new(bsdf.outputs["BSDF"], mix.inputs[2])
    links.new(mix.outputs["Shader"], out.inputs["Surface"])
    obj.data.materials.append(m)
    return obj


def _id_material(name, color, card_img=None):
    """Couleur d'identité (partie + direction de la face) : les contours du guide."""
    import bpy
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.use_backface_culling = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    nodes.clear()
    geo = nodes.new("ShaderNodeNewGeometry")
    mix = nodes.new("ShaderNodeMix"); mix.data_type = 'RGBA'
    mix.inputs["Factor"].default_value = 0.45
    mix.inputs["A"].default_value = tuple(color) + (1.0,)
    links.new(geo.outputs["True Normal"], mix.inputs["B"])
    em = nodes.new("ShaderNodeEmission")
    links.new(mix.outputs["Result"], em.inputs["Color"])
    out = nodes.new("ShaderNodeOutputMaterial")
    if card_img is not None:
        tex = nodes.new("ShaderNodeTexImage"); tex.image = card_img
        tr = nodes.new("ShaderNodeBsdfTransparent")
        mx = nodes.new("ShaderNodeMixShader")
        links.new(tex.outputs["Alpha"], mx.inputs["Fac"])
        links.new(tr.outputs["BSDF"], mx.inputs[1])
        links.new(em.outputs["Emission"], mx.inputs[2])
        links.new(mx.outputs["Shader"], out.inputs["Surface"])
    else:
        links.new(em.outputs["Emission"], out.inputs["Surface"])
    return m


def projector(box, elevation, lacet=0.0):
    """Projecteur orthographique de face (lacet : tourné vers la droite du modèle), cadré sur la
    boîte de la pièce : (R, U, D vers la caméra, centre, px/m, w, h)."""
    e, l = math.radians(elevation), math.radians(lacet)
    R = np.array([math.cos(l), math.sin(l), 0.0])
    D = np.array([math.sin(l) * math.cos(e), -math.cos(l) * math.cos(e), math.sin(e)])
    U = np.cross(D, R)
    corners = np.array([[x, y, z] for x in box[0] for y in box[1] for z in box[2]])
    pu, pv = corners @ R, corners @ U
    C = R * (pu.min() + pu.max()) / 2 + U * (pv.min() + pv.max()) / 2
    ew, eh = (pu.max() - pu.min()) * 1.04, (pv.max() - pv.min()) * 1.04
    s = GUIDE_PX / max(ew, eh)
    w, h = (int(math.ceil(ew * s / 64.0)) * 64, int(math.ceil(eh * s / 64.0)) * 64)
    return {"R": R.tolist(), "U": U.tolist(), "D": D.tolist(), "C": C.tolist(), "s": s, "w": w, "h": h}


def _render(scene, pj, path, transparent, samples, filt):
    import bpy
    from mathutils import Vector
    cam_data = bpy.data.cameras.new("projecteur")
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = max(pj["w"], pj["h"]) / pj["s"]
    cam = bpy.data.objects.new("projecteur", cam_data)
    scene.collection.objects.link(cam)
    D = Vector(pj["D"])
    cam.location = Vector(pj["C"]) + D * 30.0
    cam.rotation_euler = (-D).to_track_quat('-Z', 'Y').to_euler()
    cam_data.clip_end = 100.0
    scene.camera = cam
    scene.render.resolution_x, scene.render.resolution_y = pj["w"], pj["h"]
    scene.render.film_transparent = transparent
    scene.render.filter_size = filt
    scene.eevee.taa_render_samples = samples
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam)


def guides(house, cfg, work, kind, texinfo, cal, load_rgba, save_rgba):
    """Guide, masque et projecteur de chaque pièce qui a un « decor »."""
    import bpy
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.view_settings.view_transform = 'Standard'
    scene.render.image_settings.color_mode = 'RGBA'
    world = bpy.data.worlds.new("W"); scene.world = world
    world.use_nodes = True
    bg = [n for n in world.node_tree.nodes if n.type == 'BACKGROUND'][0]
    bg.inputs[0].default_value = (1, 1, 1, 1)
    bg.inputs[1].default_value = 0.75
    bpy.ops.object.light_add(type='SUN')
    sun = bpy.context.active_object
    sun.data.energy = 2.0
    sun.rotation_euler = (math.radians(55), 0, math.radians(-25))
    names = list(house["parts"])
    painters = json.loads(house["peintres"])
    infos = json.loads(house.get("interieurs", "[]"))
    rooms = cfg.get("pieces", [])
    house.hide_render = True
    for info in infos:
        dec = info.get("decor")
        if not dec:
            continue
        key = info["cle"]
        spec = cfg["tente"]["interieur"] if "tente" in cfg else rooms[int(key[5:])]
        obj = house.copy(); obj.data = house.data.copy()
        scene.collection.objects.link(obj)
        obj.hide_render = False
        import bmesh
        bm = bmesh.new(); bm.from_mesh(obj.data)
        layer = bm.faces.layers.int.get("part")
        keep = {names.index(p) for p in guide_parts(info) if p in names}
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f[layer] not in keep], context='FACES')
        bm.to_mesh(obj.data); bm.free()
        me = obj.data
        part = np.empty(len(me.polygons), np.int32)
        me.attributes["part"].data.foreach_get("value", part)
        used = sorted(set(part.tolist()))
        rng = np.random.default_rng(7)
        mats, idc = [], []
        for pi in used:   # (motif du jeu, ou couleur du guide)
            pname = names[pi]
            rule = painters.get(pname, "")
            furn = "_meuble" in pname
            j = int(pname.split("_meuble")[1]) if furn else -1
            m_spec = spec.get("meubles", [])[j] if furn else {}
            col = m_spec.get("guide") or spec.get("guide", {}).get(pname.split("_")[-1])
            path, size, origin = None, (1.0, 1.0), (0.0, 0.0, 0.0)
            if rule.startswith("tuile:") and not col:
                t = texinfo.get("tuile_" + rule[6:])
                if t:
                    path = os.path.join(work, "tex_tuile_%s.png" % rule[6:])
                    s = cal.get(t.get("vue", "face"), cal["face"])["s"]
                    size = tuple(t["m"]) if "m" in t else (t["w"] / s, t["h"] / s)
                    origin = tuple(t.get("origine", (0.0, 0.0, 0.0)))
            if not path and not col:
                col = [0.42, 0.33, 0.28]
            mats.append(_tile_material("g_" + pname, path, size, [(x / 255.0 if max(col) > 1 else x) ** 2.2 for x in col] if col else None,   # (sRGB -> linéaire)
                                       origin))
            idc.append(rng.random(3))
        me.materials.clear()
        for m in mats:
            me.materials.append(m)
        me.polygons.foreach_set("material_index", np.searchsorted(used, part).astype(np.int32))
        me.update()
        cards = [_card(scene, cfg, cd, i, kind) for i, cd in enumerate(spec.get("cartes", []))]
        pj = projector(info["boite"], dec.get("elevation", ELEVATION), dec.get("lacet", 0.0))
        g = os.path.join(work, "guide_%s.png" % key)
        _render(scene, pj, g, True, 32, 1.2)
        # contours : identité (partie + direction de la face), cartes comprises
        for k, m in enumerate(mats):
            me.materials[k] = _id_material("id_%d" % k, idc[k])
        card_mats = []
        for i, cd in enumerate(cards):
            card_mats.append(cd.data.materials[0])
            img = [n for n in cd.data.materials[0].node_tree.nodes if n.type == 'TEX_IMAGE'][0].image
            cd.data.materials[0] = _id_material("idc_%d" % i, rng.random(3), img)
        ids = os.path.join(work, "ids_%s.png" % key)
        _render(scene, pj, ids, True, 1, 0.0)
        # masque : meubles et cartes (murs, sol, plafond cachés)
        furn_ids = [k for k, pi in enumerate(used) if "_meuble" in names[pi]]
        for k in range(len(mats)):
            if k not in furn_ids:
                me.materials[k] = _hidden_material()
        mk = os.path.join(work, "masque_%s.png" % key)
        _render(scene, pj, mk, True, 16, 1.2)
        _outline(g, ids, mk, load_rgba, save_rgba)
        json.dump(pj, open(os.path.join(work, "projecteur_%s.json" % key), "w"), indent=1)
        for o in cards + [obj]:
            bpy.data.objects.remove(o)
        print("GUIDE", key, pj["w"], "x", pj["h"], "px, %.0f px/m" % pj["s"])
    house.hide_render = False


def _hidden_material():
    import bpy
    m = bpy.data.materials.get("cache") or bpy.data.materials.new("cache")
    m.use_nodes = True
    m.use_backface_culling = True   # (le plafond vu de dessus ne cache rien)
    nodes, links = m.node_tree.nodes, m.node_tree.links
    nodes.clear()
    tr = nodes.new("ShaderNodeHoldout")
    out = nodes.new("ShaderNodeOutputMaterial")
    links.new(tr.outputs[0], out.inputs["Surface"])
    return m


def _outline(guide, ids, mask, load_rgba, save_rgba):
    """Contours bruns (le trait du jeu) là où l'identité change, sur fond brun sombre ; masque
    adouci (un peu élargi)."""
    g, i, m = load_rgba(guide), load_rgba(ids), load_rgba(mask)
    a = i[..., 3] > 0.5
    col = i[..., :3] * a[..., None]
    diff = np.zeros(a.shape, bool)
    for dy, dx in ((0, 1), (1, 0), (1, 1), (1, -1)):
        sh = np.roll(np.roll(col, dy, 0), dx, 1)
        sa = np.roll(np.roll(a, dy, 0), dx, 1)
        diff |= (np.abs(col - sh).sum(2) > 0.06) & (a | sa)
    edge = diff | np.roll(diff, 1, 0) | np.roll(diff, 1, 1)
    bgc = np.array([0.16, 0.11, 0.09], np.float32)
    rgb = g[..., :3] * g[..., 3:4] + bgc * (1 - g[..., 3:4])
    rgb[edge] = rgb[edge] * 0.25 + np.array(CONTOUR, np.float32) * 0.75
    out = np.concatenate([rgb, np.ones(a.shape + (1,), np.float32)], 2)
    save_rgba(guide, out)
    k = m[..., 3]
    grow = np.maximum.reduce([np.roll(np.roll(k, dy, 0), dx, 1) for dy in (-1, 0, 1) for dx in (-1, 0, 1)])
    soft = (grow + np.roll(grow, 1, 0) + np.roll(grow, -1, 0) + np.roll(grow, 1, 1) + np.roll(grow, -1, 1)) / 5
    save_rgba(mask, np.stack([soft, soft, soft, np.ones_like(soft)], 2))


# ================================================================== ComfyUI (hors Blender)
def _comfy(path, data=None):
    import urllib.request
    req = urllib.request.Request(COMFY_URL + path, data=json.dumps(data).encode() if data is not None else None,
                                 headers={"Content-Type": "application/json"} if data is not None else {})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())


def _workflow(guide, ref, prompt, denoise, seed, prefix, w, h):
    wf = json.load(open(os.path.join(HERE, "peinture_comfyui.json"), encoding="utf-8"))
    wf = {k: v for k, v in wf.items() if k in ("1", "2", "3", "4", "40", "5", "6", "7", "8", "9", "10", "11", "12", "13")}
    wf["3"]["inputs"]["image"] = ref
    wf["8"]["inputs"]["image"] = guide
    wf["7"]["inputs"]["text"] = NEGATIF
    wf["10"]["inputs"]["text"] = STYLE + ", " + prompt
    wf["11"]["inputs"].update({"seed": seed, "denoise": denoise})
    wf["13"]["inputs"]["filename_prefix"] = prefix
    return wf


def _ref_image(src, out):
    """L'image de référence de l'IPAdapter (une image du jeu) sur un fond brun sombre."""
    from PIL import Image
    im = Image.open(os.path.join(ART, src)).convert("RGBA")
    im = im.crop(im.getbbox())
    bg = Image.new("RGBA", im.size, (52, 38, 32, 255))
    bg.alpha_composite(im)
    bg.convert("RGB").save(out)


def peindre(kind, cfg, work, only=None):
    """Chaque guide repeint par ComfyUI (img2img) -> peint_<clé>.png et generated_imgs/interieurs."""
    from PIL import Image
    specs = []
    if "tente" in cfg:
        if cfg["tente"].get("interieur", {}).get("decor"):
            specs.append(("piece0", cfg["tente"]["interieur"]["decor"]))
    for r, rc in enumerate(cfg.get("pieces", [])):
        if rc.get("decor"):
            specs.append(("piece%d" % r, rc["decor"]))
    os.makedirs(PEINTS, exist_ok=True)
    for key, dec in specs:
        if only and key != only:
            continue
        guide = os.path.join(work, "guide_%s.png" % key)
        if not os.path.exists(guide):
            print("pas de guide :", guide)
            continue
        gname, rname = "interieur_%s_%s.png" % (kind, key), "interieur_ref_%s_%s.png" % (kind, key)
        Image.open(guide).convert("RGB").save(os.path.join(COMFY_DIR, "input", gname))
        _ref_image(dec["ref"], os.path.join(COMFY_DIR, "input", rname))
        w, h = Image.open(guide).size
        prefix = "interieur_%s_%s" % (kind, key)
        wf = _workflow(gname, rname, dec["prompt"], dec.get("denoise", 0.5), dec.get("seed", 7), prefix, w, h)
        pid = _comfy("/prompt", {"prompt": wf})["prompt_id"]
        t0 = time.time()
        while True:
            hist = _comfy("/history/" + pid)
            if pid in hist and hist[pid].get("outputs"):
                break
            if pid in hist and hist[pid].get("status", {}).get("status_str") == "error":
                raise RuntimeError("ComfyUI : " + json.dumps(hist[pid]["status"])[:600])
            if time.time() - t0 > 3600:   # (le GPU est partagé : ComfyUI peut avoir une file)
                raise RuntimeError("ComfyUI : trop long")
            time.sleep(2)
        im = hist[pid]["outputs"]["13"]["images"][0]
        src = os.path.join(COMFY_DIR, "output", im.get("subfolder", ""), im["filename"])
        out = Image.open(src).convert("RGB").resize((w, h), Image.LANCZOS)
        out.save(os.path.join(work, "peint_%s.png" % key))
        out.save(os.path.join(PEINTS, "%s_%s.png" % (kind, key)))
        shutil.copyfile(guide, os.path.join(PEINTS, "%s_%s_guide.png" % (kind, key)))
        print("PEINT", kind, key, "%.0f s" % (time.time() - t0), os.path.join(PEINTS, "%s_%s.png" % (kind, key)))


# ================================================================== contrôles (Blender, PIL)
def _shadeless(obj):
    """Matériaux importés -> leur couleur cuite seule (le jeu éclaire presque à plat)."""
    for mat in obj.data.materials:
        nt = mat.node_tree
        bsdf = [n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'][0]
        link = bsdf.inputs["Base Color"].links[0]
        em = nt.nodes.new("ShaderNodeEmission")
        nt.links.new(link.from_socket, em.inputs["Color"])
        out = [n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL'][0]
        nt.links.new(em.outputs["Emission"], out.inputs["Surface"])


def _scene_for(path):
    import bpy
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    scene = bpy.context.scene
    for o in scene.objects:
        if o.type == 'MESH':
            _shadeless(o)
    world = bpy.data.worlds.new("W"); scene.world = world
    world.use_nodes = True
    bg = [n for n in world.node_tree.nodes if n.type == 'BACKGROUND'][0]
    bg.inputs[0].default_value = (0.62, 0.68, 0.6, 1)
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, -0.003))
    ground = bpy.context.active_object
    gm = bpy.data.materials.new("sol"); gm.use_nodes = True
    nt = gm.node_tree
    nt.nodes.clear()
    em = nt.nodes.new("ShaderNodeEmission"); em.inputs["Color"].default_value = (0.36, 0.40, 0.31, 1)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    ground.data.materials.append(gm)
    scene.render.engine = 'BLENDER_EEVEE'
    scene.view_settings.view_transform = 'Standard'
    scene.eevee.taa_render_samples = 16
    return scene


def _shoot(scene, target, yaw, pitch, dist, path, res=360, fov=40.0):
    import bpy
    from mathutils import Vector
    cam_data = bpy.data.cameras.new("c")
    cam_data.angle = math.radians(fov)
    cam = bpy.data.objects.new("c", cam_data)
    scene.collection.objects.link(cam)
    a, p = math.radians(yaw), math.radians(pitch)
    cam.location = target + Vector((math.sin(a) * math.cos(p), -math.cos(a) * math.cos(p), math.sin(p))) * dist
    cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
    scene.camera = cam
    scene.render.resolution_x = scene.render.resolution_y = res
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam)


def rendus(kind, work):
    """De face, de 3/4, caméra du jeu, pour chaque ouverture du dedans ; porte ouverte (variante
    des portes) -> int_<clé>_<i>_<vue>.png."""
    from mathutils import Vector
    infos = json.load(open(os.path.join(work, "interieurs.json")))
    turn = os.path.join(work, "export.json")
    turn = json.load(open(turn)) if os.path.exists(turn) else None
    yaw_t = turn["lacet"] if turn else 0.0
    c_, s_ = math.cos(-yaw_t), math.sin(-yaw_t)
    M = np.array([[c_, -s_, 0.0], [s_, c_, 0.0], [0.0, 0.0, 1.0]])
    shift = np.array(turn["t"]) if turn else np.zeros(3)
    base = -math.degrees(yaw_t)   # (l'axe de l'entrée d'une tente tournée à l'export)
    shots = []
    for info in infos:
        for i, op in enumerate(info["ouvertures"]):
            poly = np.array(op["poly"], float)
            c = np.array([(poly[:, 0].min() + poly[:, 0].max()) / 2, op["y"], (poly[:, 1].min() + poly[:, 1].max()) / 2])
            size = max(np.ptp(poly[:, 0]), np.ptp(poly[:, 1]))
            shots.append(("%s_%d" % (info["cle"], i), Vector((M @ c + shift).tolist()), 1.3 + 1.6 * size))
    # (une sorte à porte : la variante des portes, battants ouverts : le dedans ne se voit que porte ouverte)
    variant = os.path.join(GODOT, "assets", "models", "volumes", "portes", kind + ".glb")
    door = os.path.exists(variant)
    scene = _scene_for(variant if door else os.path.join(GODOT, "assets", "models", "volumes", kind + ".glb"))
    for o in scene.objects:
        if door and o.type == 'MESH' and "ouverture" in o.keys():
            o.rotation_mode = 'XYZ'
            o.rotation_euler.z += math.radians(float(o["ouverture"]))
    for name, target, dist in shots:   # de face, de 3/4 ; la caméra du jeu, droit devant et en biais
        for vue, yaw, pitch, k in (("face", base, 8, 1.0), ("g35", base - 35, 20, 1.0), ("d35", base + 35, 20, 1.0),
                                   ("jeu", 0, 40, 1.2), ("jeu_g", -25, 40, 1.2), ("jeu_d", 25, 40, 1.2)):
            _shoot(scene, target, yaw, pitch, dist * k, os.path.join(work, "int_%s_%s.png" % (name, vue)), res=420)
    json.dump({"porte": door}, open(os.path.join(work, "interieurs_rendus.json"), "w"))
    print("RENDUS_INTERIEURS_OK", kind, [s[0] for s in shots], "porte ouverte" if door else "")


def planche(kinds):
    """generated_imgs/captures/interieurs_ouvertures.png : par ouverture, guide et peinture
    ComfyUI, rendus de face, de 3/4, caméra du jeu, porte ouverte."""
    from PIL import Image, ImageDraw, ImageFont
    cols = [("guide (Blender)", "guide_{c}.png"), ("peinture ComfyUI", "peint_{c}.png"), ("de face", "int_{n}_face.png"),
            ("3/4 gauche", "int_{n}_g35.png"), ("3/4 droite", "int_{n}_d35.png"), ("caméra du jeu 0°/40°", "int_{n}_jeu.png"),
            ("jeu, en biais -25°", "int_{n}_jeu_g.png"), ("jeu, en biais +25°", "int_{n}_jeu_d.png")]
    rows = []
    for kind in kinds:
        work = os.path.join(WORK_ROOT, kind)
        path = os.path.join(work, "interieurs.json")
        if not os.path.exists(path):
            continue
        for info in json.load(open(path)):
            for i in range(len(info["ouvertures"])):
                rows.append((kind, work, info["cle"], "%s_%d" % (info["cle"], i)))
    cell, pad = 250, 22
    board = Image.new("RGB", (cell * len(cols) + 170, (cell + pad) * len(rows) + pad), (104, 128, 108))
    d = ImageDraw.Draw(board)
    try:
        font = ImageFont.truetype("arial.ttf", 14)
    except OSError:
        font = ImageFont.load_default()
    for c, (label, _) in enumerate(cols):
        d.text((170 + c * cell + 6, 4), label, fill=(255, 255, 255), font=font)
    for r, (kind, work, key, name) in enumerate(rows):
        y = pad + r * (cell + pad)
        rj = os.path.join(work, "interieurs_rendus.json")
        door = os.path.exists(rj) and json.load(open(rj)).get("porte")
        d.text((6, y + cell // 2 - 18), "%s\n%s%s" % (kind, name, "\n(porte ouverte)" if door else ""),
               fill=(255, 255, 255), font=font)
        for c, (_, pat) in enumerate(cols):
            for p in (pat if isinstance(pat, tuple) else (pat,)):
                f = os.path.join(work, p.format(c=key, n=name))
                if os.path.exists(f):
                    im = Image.open(f).convert("RGB")
                    k = min((cell - 6) / im.width, (cell - 6) / im.height)
                    im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
                    board.paste(im, (170 + c * cell + (cell - im.width) // 2, y + (cell - im.height) // 2))
                    break
    os.makedirs(CAPTURES, exist_ok=True)
    out = os.path.join(CAPTURES, "interieurs_ouvertures.png")
    board.save(out)
    print("planche :", out, board.size)
