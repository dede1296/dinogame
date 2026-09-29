"""Vrais volumes 3D des grands décors (Blender) : le maillage sculpté par Hunyuan3D (ComfyUI) est
calé sur l'image du jeu, allégé, peint (l'image de face + deux flancs peints par ComfyUI) et
exporté pour Godot au format « Modèle 3D v2 » : une surface, un atlas UV, la peinture cuite dedans
(occlusion ambiante comprise) et une carte de normales qui rend au modèle allégé les détails du
maillage brut (tuiles, joints, volets). Voir docs/direction-artistique.md, « Grands décors en vraie 3D ».

  blender -b -P volumes_blender.py -- prep <sorte>
      maillage de ComfyUI (output/volumes/<sorte>_*.glb) -> orienté, mis à l'échelle du jeu, posé
      (pied de façade à l'origine) ; le « haut » (pour la cuisson) : ce brut refait en voxels fins
      (~1,5 cm : même détail, mais propre, sans les arêtes à 3-4 faces de Hunyuan3D) ; le « bas »
      (le modèle du jeu) : le haut allégé à FACES triangles ; angle de l'image ; rendus des flancs
      est/ouest (le haut) pour ComfyUI.
  blender -b -P volumes_blender.py -- maillages <sorte>
      refait seulement le haut et le bas (après un changement de FACES, ou un prep d'avant la v2),
      sans toucher à l'angle ni aux caméras des flancs déjà peints (info.json).
  blender -b -P volumes_blender.py -- bake <sorte>
      atlas UV du bas (îlots de Smart UV Project sans miettes, dépliés, rangés : 2048 px) ;
      cuisson Cycles (CPU, ~1 à 2 min) : la peinture (projections de l'image de face et des flancs
      peints), l'occlusion ambiante du haut (multipliée dans la couleur, modérément) et la carte
      de normales (espace tangent, OpenGL) du haut vers le bas ; export
      assets/models/volumes/<sorte>.glb (une surface, baseColor + normalTexture, tangentes).
      Refait le haut et le bas d'abord s'ils manquent (prep d'avant la v2).

Dossier de travail : C:/ComfyUI_windows_portable/blender_tests/volumes/<sorte>/ (hors dépôt) :
modele.blend (objets <sorte> = le bas, <sorte>_haut = le haut), info.json, tex_*.png (volumes.py),
atlas_couleur.jpg, atlas_normales.png, atlas_ao.png (contrôle).
Axes Blender : X à droite, Y vers le fond (la caméra du jeu est côté -Y), Z en haut.
"""
import bpy, bmesh, glob, json, math, os, re, sys, time
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ARGS = sys.argv[sys.argv.index("--") + 1:]
MODE, KIND = ARGS[0], ARGS[1]
HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.normpath(os.path.join(HERE, "..", ".."))
COMFY = "C:/ComfyUI_windows_portable/ComfyUI"
WORK = "C:/ComfyUI_windows_portable/blender_tests/volumes/" + KIND
OUT = os.path.join(GODOT, "assets", "models", "volumes", KIND + ".glb")
HIGH = KIND + "_haut"
PX = 48.0
PITCH = math.radians(40.0)            # caméra du jeu (CameraRig.PITCH_DEG)
FRONT_CLEAR = 6.0 / PX                # bord avant de la collision d'un décor (prop.gd)
SIDE_RES = 640
SIDE_TIE = 0.15       # faces vues presque autant des deux flancs : peintes par le flanc de leur côté
# Triangles du bas : assez pour la silhouette (galbe du toit, cheminée, volets) ; le détail fin
# passe par la carte de normales.
FACES = {"maison_blanche": 50000, "maison_jaune": 50000, "maison_port": 50000, "cabinet": 55000,
         "cabane_pilotis": 40000, "tente": 16000, "tente_nomade": 18000, "rocher_canyon": 18000, "rocher": 12000,
         "rocher_mousse": 14000, "arche_rocheuse": 20000, "squelette_geant": 40000, "crane_geant_desert": 28000,
         "statue_dino": 30000, "os_geant": 30000}
ATLAS = {"tente": 1024, "rocher": 1024, "rocher_mousse": 1024}   # côté de l'atlas en px (2048 sinon)
CRUMBS = 0.001        # morceaux flottants du brut plus petits que ça (part des sommets) : jetés
VOXEL_DIV = 420       # le haut refait en voxels de (plus grande dimension / VOXEL_DIV) : ~1,5 cm pour une maison
UV_ANGLE = 66.0       # Smart UV Project : angle limite des îlots (degrés)
UV_MIN_PART = 1 / 3000   # îlot plus petit que ça (part de la surface) : fondu dans son voisin
UV_MARGIN = 12        # écart entre îlots de l'atlas (px) : les mipmaps ne mélangent pas deux îlots
BAKE_MARGIN = 16      # débord des couleurs cuites autour des îlots (px)
AO_DIST = 0.35        # portée de l'occlusion ambiante (m) : les cavités, pas l'ombre des grands volumes
AO_FORCE = 0.6        # part de l'occlusion multipliée dans la couleur (0 : aucune, 1 : entière)
AO_SAMPLES = 64
JPEG_QUALITY = 92     # la couleur de l'atlas (les normales : PNG)
CAGE_MIN = 0.03       # la cage (bas gonflé) d'où partent les rayons vers le haut, en m : au moins ça,
CAGE_MAX = 0.12       # au plus ça (au-delà, les rayons attrapent les volumes voisins)
THREADS = max(1, (os.cpu_count() or 4) - 2)   # laisser un peu de CPU (ComfyUI, l'éditeur)
os.makedirs(WORK, exist_ok=True)


def kind_def():
    src = open(os.path.join(GODOT, "world", "prop.gd"), encoding="utf-8").read()
    body = re.search(r'^\t"%s": \{([^}]*)\}' % KIND, src, re.M).group(1)
    return {"scale": float(re.search(r'"scale": ([\d.]+)', body).group(1)),
            "foot": float(re.search(r'"foot": ([\d.]+)', body).group(1))}


def picture_mask():
    """Masque de l'image du jeu (haut en haut), sa taille en px."""
    img = bpy.data.images.load(os.path.join(GODOT, "assets", "art", "props", KIND + ".png"))
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    return px[..., 3] > 0.5, w, h


def mesh_co(me):
    co = np.empty(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    return co.reshape(-1, 3)


def loop_co(me):
    """Position du sommet de chaque coin de face."""
    vi = np.empty(len(me.loops), np.int32)
    me.loops.foreach_get("vertex_index", vi)
    return mesh_co(me)[vi]


def front_coords(pts, theta):
    """Coordonnées d'image d'une projection orthographique vue d'en face, d'un angle theta
    au-dessus de l'horizontale : (x, hauteur apparente)."""
    return np.stack([pts[:, 0], pts[:, 2] + pts[:, 1] * math.tan(theta)], 1)


def fit(coords, mask):
    """Cale la boîte des coordonnées sur la boîte du masque : coords -> px de l'image."""
    ys, xs = np.nonzero(mask)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    c0, c1 = coords.min(0), coords.max(0)
    u = x0 + (coords[:, 0] - c0[0]) / max(c1[0] - c0[0], 1e-6) * (x1 - x0)
    v = y1 - (coords[:, 1] - c0[1]) / max(c1[1] - c0[1], 1e-6) * (y1 - y0)
    return np.stack([u, v], 1), (float(c0[0]), float(c0[1]), float(c1[0]), float(c1[1])), (int(x0), int(x1), int(y0), int(y1))


def silhouette_iou(pts, mask, theta):
    uv, _, _ = fit(front_coords(pts, theta), mask)
    h, w = mask.shape
    k = 128.0 / max(w, h)
    gw, gh = int(w * k) + 2, int(h * k) + 2
    grid = np.zeros((gh, gw), bool)
    grid[np.clip((uv[:, 1] * k).astype(int), 0, gh - 1), np.clip((uv[:, 0] * k).astype(int), 0, gw - 1)] = True
    for _ in range(2):   # les points de surface -> une silhouette pleine
        g = grid.copy(); g[1:] |= grid[:-1]; g[:-1] |= grid[1:]; g[:, 1:] |= grid[:, :-1]; g[:, :-1] |= grid[:, 1:]; grid = g
    ref = np.zeros((gh, gw), bool)
    ys, xs = np.nonzero(mask)
    ref[(ys * k).astype(int), (xs * k).astype(int)] = True
    return (grid & ref).sum() / max((grid | ref).sum(), 1)


def ortho_camera(name, azimuth_deg, target, size):
    az = math.radians(azimuth_deg)
    d = Vector((math.sin(az) * math.cos(PITCH), -math.cos(az) * math.cos(PITCH), math.sin(PITCH)))
    cam_data = bpy.data.cameras.new(name)
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = size
    cam = bpy.data.objects.new(name, cam_data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = target + d * 30.0
    cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
    return cam


def ortho_uvs(cam, pts):
    """Coordonnées (0..1) des points dans l'image carrée d'une caméra orthographique."""
    m = cam.matrix_world.inverted()
    p = pts @ np.array(m.to_3x3()).T + np.array(m.translation)
    s = cam.data.ortho_scale
    return np.stack([p[:, 0] / s + 0.5, p[:, 1] / s + 0.5], 1)


def image_material(name, path):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nodes = m.node_tree.nodes
    nodes.clear()   # (après réouverture d'un .blend, le nœud par défaut peut manquer)
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 1.0
    out = nodes.new("ShaderNodeOutputMaterial")
    m.node_tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(path)
    m.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return m


def front_uvs(me, info):
    """UV de l'image de face pour chaque coin de face (la projection calée au prep)."""
    c = front_coords(loop_co(me), info["theta"])
    c0x, c0y, c1x, c1y = info["box"]
    x0, x1, y0, y1 = info["mask_box"]
    u = x0 + (c[:, 0] - c0x) / (c1x - c0x) * (x1 - x0)
    v = y1 - (c[:, 1] - c0y) / (c1y - c0y) * (y1 - y0)
    return np.stack([u / info["w"], 1.0 - v / info["h"]], 1)


# ------------------------------------------------------------------ maillages (haut et bas)
def drop_crumbs(me):
    """Retire les morceaux flottants (miettes de Hunyuan3D) : composantes connexes minuscules."""
    n = len(me.vertices)
    ev = np.empty(len(me.edges) * 2, np.int64)
    me.edges.foreach_get("vertices", ev)
    a, b = ev[0::2], ev[1::2]
    lab = np.arange(n)
    while True:   # étiquette = plus petit indice de la composante (propagation + raccourcis)
        new = lab.copy()
        m = np.minimum(lab[a], lab[b])
        np.minimum.at(new, a, m)
        np.minimum.at(new, b, m)
        new = new[new]
        if np.array_equal(new, lab):
            break
        lab = new
    count = np.bincount(lab, minlength=n)
    small = np.nonzero(count[lab] < CRUMBS * n)[0]
    if len(small):
        bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table()
        bmesh.ops.delete(bm, geom=[bm.verts[i] for i in small], context='VERTS')
        bm.to_mesh(me); bm.free()
    return len(small)


def evaluated_mesh(obj):
    """Applique les modificateurs de obj à son maillage."""
    me = bpy.data.meshes.new_from_object(obj.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    old = obj.data
    obj.modifiers.clear()
    obj.data = me
    bpy.data.meshes.remove(old)
    me.name = obj.name
    return me


def raw_mesh(width_m):
    """Le haut : le maillage de ComfyUI en un objet, calé (place), refait en voxels fins (le brut
    de Hunyuan3D a des arêtes à 3 ou 4 faces aux parties minces, qui bloquent l'allègement et
    tachent l'occlusion), sans miettes, lissé."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    # <sorte>_00001_.glb, ou <sorte>_b_00001_.glb (une autre graine) : le plus récent ; pas rocher_canyon pour rocher.
    src = max((f for f in glob.glob(COMFY + "/output/volumes/%s_*.glb" % KIND)
               if re.fullmatch(r"%s(_[a-z])?_\d+_\.glb" % KIND, os.path.basename(f))), key=os.path.getmtime)
    bpy.ops.import_scene.gltf(filepath=src)
    meshes = [o for o in scene.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.active_object
    for o in list(scene.objects):
        if o != obj:
            bpy.data.objects.remove(o)
    obj.name = HIGH
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.data.materials.clear()
    place(obj.data, width_m)
    rem = obj.modifiers.new("voxels", 'REMESH')
    rem.mode = 'VOXEL'
    rem.voxel_size = float(np.ptp(mesh_co(obj.data), 0).max()) / VOXEL_DIV
    rem.adaptivity = 0.0
    me = evaluated_mesh(obj)
    print("miettes retirées :", drop_crumbs(me), "sommets")
    me.shade_smooth()
    return obj


def place(me, width_m):
    """Échelle du jeu (la largeur de l'image), pied de façade à l'origine, posé au sol."""
    co = mesh_co(me)
    co *= width_m / (co[:, 0].max() - co[:, 0].min())
    co[:, 0] -= (co[:, 0].max() + co[:, 0].min()) / 2
    co[:, 2] -= co[:, 2].min()
    co[:, 1] -= co[:, 1].min() + FRONT_CLEAR
    me.vertices.foreach_set("co", co.ravel())
    me.update()


def make_low(high):
    """Le bas : le haut allégé (Decimate par fusion d'arêtes, qui garde les formes), sans son
    dessous posé au sol (jamais vu)."""
    low = bpy.data.objects.new(KIND, high.data.copy())
    bpy.context.scene.collection.objects.link(low)
    dec = low.modifiers.new("allege", 'DECIMATE')
    dec.ratio = min(1.0, FACES.get(KIND, 20000) / tri_count(high.data))
    dec.use_collapse_triangulate = True
    me = evaluated_mesh(low)
    bm = bmesh.new(); bm.from_mesh(me)
    bottom = [f for f in bm.faces if f.normal.z < -0.5 and max(v.co.z for v in f.verts) < 0.03]
    bmesh.ops.delete(bm, geom=bottom, context='FACES')
    bm.to_mesh(me); bm.free()
    me.shade_smooth()
    return low


def tri_count(me):
    return len(me.loops) - 2 * len(me.polygons)


def build_meshes():
    """Le haut (le brut calé) et le bas (allégé), dans la scène vide ; mesures pour info.json."""
    mask, W, H = picture_mask()
    high = raw_mesh(W * kind_def()["scale"] / PX)
    low = make_low(high)
    co = mesh_co(low.data)
    foot = co[co[:, 2] < 0.4]
    stats = {"faces_avant": tri_count(high.data), "faces": len(low.data.polygons),
             "largeur_m": round(float(np.ptp(co[:, 0])), 2), "profondeur_m": round(float(np.ptp(co[:, 1])), 2),
             "hauteur_m": round(float(co[:, 2].max()), 2),
             "solid_px": [round(float(np.ptp(foot[:, 0])) * PX), round(float(np.ptp(foot[:, 1])) * PX)]}
    return high, low, mask, W, H, stats


def calibrate(low, mask, W, H, best=None):
    """L'angle sous lequel Hunyuan3D a lu l'image (celui dont la silhouette colle le mieux, ou
    best, en degrés, s'il est déjà connu) et le calage de l'image de face sur le modèle."""
    me = low.data
    pts = np.concatenate([mesh_co(me), np.array([p.center[:] for p in me.polygons])])
    if best is None:
        scores = {t: silhouette_iou(pts, mask, math.radians(t)) for t in range(0, 46, 5)}
        best = max(scores, key=scores.get)
        for t in (best - 2, best - 1, best + 1, best + 2):
            if 0 <= t <= 50:
                scores[t] = silhouette_iou(pts, mask, math.radians(t))
        best = max(scores, key=scores.get)
    else:
        scores = {best: silhouette_iou(pts, mask, math.radians(best))}
    _, box, mask_box = fit(front_coords(pts, math.radians(best)), mask)
    return {"theta": math.radians(best), "theta_deg": best, "iou": round(float(scores[best]), 3), "box": box,
            "mask_box": mask_box, "w": W, "h": H}


def render_sides(high, low, info):
    """Rendus des flancs pour ComfyUI (le haut : tout son relief) : l'image de face étirée donne
    les couleurs, la lumière le relief."""
    scene = bpy.context.scene
    me = high.data
    uv = me.uv_layers.new(name="face")
    uv.data.foreach_set("uv", front_uvs(me, info).ravel())
    me.materials.append(image_material("face", WORK + "/tex_face_guide.png"))
    low.hide_render = True
    world = bpy.data.worlds.new("W"); scene.world = world; world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.55
    for energy, rot in ((2.6, (55, 0, -35)), (1.0, (60, 0, 140))):
        bpy.ops.object.light_add(type='SUN')
        sun = bpy.context.active_object
        sun.data.energy = energy
        sun.rotation_euler = tuple(math.radians(a) for a in rot)
    scene.view_settings.view_transform = 'Standard'
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = scene.render.resolution_y = SIDE_RES
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = 'RGBA'
    co = mesh_co(low.data)
    target = Vector((0.0, float(co[:, 1].mean()), float(co[:, 2].max()) * 0.45))
    size = float(max(np.ptp(co[:, 0]), np.ptp(co[:, 1]), np.ptp(co[:, 2]))) * 1.35
    for name, az in (("face40", 0.0), ("est", 90.0), ("ouest", -90.0)):
        scene.camera = ortho_camera("cam_" + name, az, target, size)
        scene.render.filepath = WORK + "/rendu_%s.png" % name
        bpy.ops.render.render(write_still=True)
    low.hide_render = False
    info["cam_target"] = list(target)
    info["cam_size"] = size


def meshes_step(calibrate_too):
    high, low, mask, W, H, stats = build_meshes()
    if calibrate_too:
        info = calibrate(low, mask, W, H)
    else:   # garder l'angle et les caméras des flancs déjà peints ; recaler l'image de face
        info = json.load(open(WORK + "/info.json"))
        info.update(calibrate(low, mask, W, H, info["theta_deg"]))
    info.update(stats)
    if calibrate_too:
        render_sides(high, low, info)
    json.dump(info, open(WORK + "/info.json", "w"), indent=1)
    print("INFO", json.dumps(info))
    bpy.ops.wm.save_as_mainfile(filepath=WORK + "/modele.blend", compress=True)
    return high, low


# ------------------------------------------------------------------ cuisson
def setup_cycles(scene):
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = THREADS
    scene.render.bake.margin = BAKE_MARGIN
    scene.render.bake.margin_type = 'EXTEND'
    scene.render.bake.use_clear = False   # garder le remplissage de new_image (alpha 0 = pas cuit)
    if scene.world is None:
        scene.world = bpy.data.worlds.new("W")


def select_only(objs, active):
    for o in bpy.context.scene.objects:
        o.select_set(o in objs)
    bpy.context.view_layer.objects.active = active


def face_islands(bm):
    """Numéro d'îlot de chaque face (faces reliées par des arêtes qui ne sont pas des coutures)."""
    fid = [-1] * len(bm.faces)
    k = 0
    for f in bm.faces:
        if fid[f.index] >= 0:
            continue
        fid[f.index] = k
        stack = [f]
        while stack:
            for e in stack.pop().edges:
                if e.seam:
                    continue
                for g in e.link_faces:
                    if fid[g.index] < 0:
                        fid[g.index] = k
                        stack.append(g)
        k += 1
    return fid, k


def merge_small_islands(me):
    """Les petits îlots de Smart UV Project (miettes aux arêtes vives et aux bosses) fondus dans le
    voisin avec lequel ils partagent le plus de couture : moins de coutures, un atlas mieux rempli."""
    bm = bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table()
    fid, n = face_islands(bm)
    area = np.zeros(n)
    np.add.at(area, fid, [f.calc_area() for f in bm.faces])
    small = area.sum() * UV_MIN_PART
    root = list(range(n))

    def find(i):
        while root[i] != i:
            root[i] = root[root[i]]
            i = root[i]
        return i

    for _ in range(10):
        border = {}
        for e in bm.edges:
            if e.seam and len(e.link_faces) == 2:
                a, b = find(fid[e.link_faces[0].index]), find(fid[e.link_faces[1].index])
                if a != b:
                    for i, j in ((a, b), (b, a)):
                        border.setdefault(i, {}).setdefault(j, 0.0)
                        border[i][j] += e.calc_length()
        merged = 0
        for a in sorted(border, key=lambda i: area[i]):
            if find(a) != a or area[a] >= small:
                continue
            nb = {}
            for b, length in border[a].items():
                if find(b) != a:
                    nb[find(b)] = nb.get(find(b), 0.0) + length
            if nb:
                b = max(nb, key=nb.get)
                root[a] = b
                area[b] += area[a]
                merged += 1
        if not merged:
            break
    for e in bm.edges:
        if e.seam and len(e.link_faces) == 2 and find(fid[e.link_faces[0].index]) == find(fid[e.link_faces[1].index]):
            e.seam = False
    bm.to_mesh(me); bm.free()


def atlas_uvs(low, size):
    """Dépliage du bas : îlots de Smart UV Project (sans les miettes) marqués en coutures, dépliés
    (angle-based), mis à la même échelle et rangés dans le carré avec des marges."""
    me = low.data
    while me.uv_layers:
        me.uv_layers.remove(me.uv_layers[0])
    me.uv_layers.new(name="atlas")
    select_only([low], low)
    bpy.context.scene.tool_settings.use_uv_select_sync = True
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(UV_ANGLE), island_margin=0.0, area_weight=0.0,
                             correct_aspect=True, scale_to_bounds=False)
    bpy.ops.uv.seams_from_islands(mark_seams=True, mark_sharp=False)
    bpy.ops.object.mode_set(mode='OBJECT')
    merge_small_islands(me)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.unwrap(method='ANGLE_BASED', fill_holes=True, correct_aspect=True, margin=0.0)
    bpy.ops.uv.select_all(action='SELECT')
    bpy.ops.uv.average_islands_scale()
    bpy.ops.uv.pack_islands(rotate=True, margin_method='FRACTION', margin=UV_MARGIN / size)
    bpy.ops.object.mode_set(mode='OBJECT')


def new_image(name, size, fill, data):
    """Image cible d'une cuisson, remplie de fill (alpha 0 : pas encore cuit) ; data : valeurs
    brutes (normales, occlusion), pas des couleurs."""
    img = bpy.data.images.new(name, size, size, alpha=True, float_buffer=data)
    img.colorspace_settings.name = "Non-Color" if data else "sRGB"
    img.pixels.foreach_set(np.tile(np.array(fill[:3] + (0.0,), np.float32), size * size))
    return img


def target_node(mat, img):
    """Nœud image actif d'un matériau : c'est là que Cycles écrit la cuisson."""
    nodes = mat.node_tree.nodes
    for n in [n for n in nodes if n.name == "cible"]:
        nodes.remove(n)
    n = nodes.new("ShaderNodeTexImage")
    n.name = "cible"
    n.image = img
    nodes.active = n


def emit_material(name, path):
    """Émission de l'image de peinture lue par la couche UV « peinture »."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    nodes.clear()
    uvn = nodes.new("ShaderNodeUVMap"); uvn.uv_map = "peinture"
    tex = nodes.new("ShaderNodeTexImage"); tex.image = bpy.data.images.load(path)
    tex.extension = 'EXTEND'
    em = nodes.new("ShaderNodeEmission")
    out = nodes.new("ShaderNodeOutputMaterial")
    links.new(uvn.outputs["UV"], tex.inputs["Vector"])
    links.new(tex.outputs["Color"], em.inputs["Color"])
    links.new(em.outputs["Emission"], out.inputs["Surface"])
    return m


def paint_uvs(low, info):
    """Couche UV « peinture » et matériau de chaque face : l'image de face (0) si la face la voit
    assez, sinon le flanc peint (1 : est, 2 : ouest) qui la voit le mieux."""
    me = low.data
    uv = me.uv_layers.new(name="peinture")
    front = front_uvs(me, info)
    lco = loop_co(me)
    target = Vector(info["cam_target"])
    cams = {"est": ortho_camera("cam_est", 90.0, target, info["cam_size"]),
            "ouest": ortho_camera("cam_ouest", -90.0, target, info["cam_size"])}
    bpy.context.view_layer.update()   # (matrix_world des caméras)
    sides = {k: ortho_uvs(c, lco) for k, c in cams.items()}
    theta = info["theta"]
    dir_front = Vector((0.0, -math.cos(theta), math.sin(theta)))   # vers la caméra de l'image
    dirs = {k: (c.location - target).normalized() for k, c in cams.items()}
    bvh = BVHTree.FromObject(low, bpy.context.evaluated_depsgraph_get())
    uvd = front.copy()
    mat = np.zeros(len(me.polygons), np.int32)
    counts = {"face": 0, "est": 0, "ouest": 0, "cachees": 0}

    def visible(c, n, d):
        if n.dot(d) <= 0.05:
            return -1.0
        return n.dot(d) if bvh.ray_cast(c + n * 0.01, d, 60.0)[0] is None else -1.0

    for poly in me.polygons:
        c, n = poly.center, poly.normal
        sf = visible(c, n, dir_front)
        se, so = visible(c, n, dirs["est"]), visible(c, n, dirs["ouest"])
        if sf >= 0.3 or (sf > 0 and sf >= max(se, so)):
            counts["face"] += 1
            continue
        side = "est" if se >= so else "ouest"
        if abs(se - so) < SIDE_TIE:   # vue autant des deux flancs (dessus) : le flanc de son côté
            side = "est" if c.x >= 0 else "ouest"
        if max(se, so) <= 0:
            counts["cachees"] += 1   # jamais vue par la caméra du jeu (dessous, arrière) : la face
            side = "est" if n.x >= 0 else "ouest"
            if n.y > 0.3 or n.z < -0.3:
                continue
        mat[poly.index] = 1 if side == "est" else 2
        li = list(poly.loop_indices)
        uvd[li] = sides[side][li]
        counts[side] += 1
    uv.data.foreach_set("uv", uvd.ravel())
    me.polygons.foreach_set("material_index", mat)
    for c in cams.values():
        bpy.data.objects.remove(c)
    return counts


def bake_paint(low, info, size):
    """La peinture (3 projections) cuite dans l'atlas : émission, sans lumière."""
    me = low.data
    img = new_image("couleur", size, (0.5, 0.5, 0.5, 1.0), False)
    me.materials.clear()   # (remet les numéros de matériau à 0 : avant paint_uvs)
    for name in ("face", "est", "ouest"):
        m = emit_material(name, WORK + "/tex_%s.png" % name)
        target_node(m, img)
        me.materials.append(m)
    counts = paint_uvs(low, info)
    me.uv_layers.active = me.uv_layers["atlas"]
    me.uv_layers["atlas"].active_render = True
    scene = bpy.context.scene
    scene.cycles.samples = 4
    select_only([low], low)
    bpy.ops.object.bake(type='EMIT', target='IMAGE_TEXTURES', use_selected_to_active=False,
                        margin=BAKE_MARGIN, margin_type='EXTEND')
    me.uv_layers.remove(me.uv_layers["peinture"])
    return img, counts


def bake_ao(high, low, size):
    """Occlusion ambiante du haut (ses cavités : joints, dessous des tuiles, embrasures), cuite
    d'abord à ses sommets (le bas retiré de la scène, pour ne pas faire d'ombre), puis transférée
    dans l'atlas du bas."""
    scene = bpy.context.scene
    me = high.data
    ca = me.color_attributes.new("ao", 'FLOAT_COLOR', 'POINT')
    me.color_attributes.active_color = ca
    colls = list(low.users_collection)
    for c in colls:
        c.objects.unlink(low)
    scene.world.light_settings.distance = AO_DIST
    scene.cycles.samples = AO_SAMPLES
    select_only([high], high)
    bpy.ops.object.bake(type='AO', target='VERTEX_COLORS', use_selected_to_active=False)
    for c in colls:
        c.objects.link(low)
    m = bpy.data.materials.new("ao")
    m.use_nodes = True
    nodes, links = m.node_tree.nodes, m.node_tree.links
    nodes.clear()
    attr = nodes.new("ShaderNodeAttribute"); attr.attribute_name = "ao"
    em = nodes.new("ShaderNodeEmission")
    out = nodes.new("ShaderNodeOutputMaterial")
    links.new(attr.outputs["Color"], em.inputs["Color"])
    links.new(em.outputs["Emission"], out.inputs["Surface"])
    me.materials.clear()
    me.materials.append(m)
    img = new_image("ao", size, (1.0, 1.0, 1.0, 1.0), True)
    transfer(high, low, img, 'EMIT')
    return img


def cage_distance(high, low):
    """Écart du haut hors du bas (m, vers l'extérieur) : la cage doit l'englober."""
    bvh = BVHTree.FromObject(low, bpy.context.evaluated_depsgraph_get())
    co = mesh_co(high.data)
    co = co[co[:, 2] > 0.05]   # (pas le dessous, retiré du bas)
    co = co[np.random.default_rng(0).choice(len(co), min(len(co), 60000), replace=False)]
    out = []
    for p in co:
        q, n, _, _ = bvh.find_nearest(Vector(p))
        if q is not None:
            out.append((Vector(p) - q).dot(n))
    out = np.array(out)
    return float(np.clip(np.percentile(out, 99.5) * 1.3, CAGE_MIN, CAGE_MAX)), float(np.percentile(-out, 99.5))


def transfer(high, low, img, kind, **kw):
    """Cuisson du haut vers le bas (sélection vers actif) dans l'image img de l'atlas."""
    scene = bpy.context.scene
    low.data.materials.clear()
    m = bpy.data.materials.new("cible_" + img.name)
    m.use_nodes = True
    target_node(m, img)
    low.data.materials.append(m)
    scene.cycles.samples = 1
    ext, depth = scene["cage"]
    select_only([high, low], low)
    bpy.ops.object.bake(type=kind, target='IMAGE_TEXTURES', use_selected_to_active=True,
                        cage_extrusion=ext, max_ray_distance=ext + depth + 0.02,
                        margin=BAKE_MARGIN, margin_type='EXTEND', **kw)


def bake_normals(high, low, size):
    img = new_image("normales", size, (0.5, 0.5, 1.0, 1.0), True)
    transfer(high, low, img, 'NORMAL', normal_space='TANGENT',
             normal_r='POS_X', normal_g='POS_Y', normal_b='POS_Z')
    return img


def pixels(img):
    a = np.empty(img.size[0] * img.size[1] * 4, np.float32)
    img.pixels.foreach_get(a)
    return a.reshape(-1, 4)


def save_image(name, arr, size, color):
    """Enregistre une image 8 bits (arr : valeurs 0..1 telles qu'écrites dans le fichier) : la
    couleur en JPEG (le glb 3 fois plus léger ; Godot la recompresse de toute façon), le reste en
    PNG (sans perte : les normales)."""
    img = bpy.data.images.new(name, size, size, alpha=False)
    img.colorspace_settings.name = "sRGB" if color else "Non-Color"
    img.pixels.foreach_set(np.ascontiguousarray(arr, np.float32).ravel())
    img.filepath_raw = WORK + "/%s.%s" % (name, "jpg" if color else "png")
    img.file_format = 'JPEG' if color else 'PNG'
    if color:
        img.save(quality=JPEG_QUALITY)
    else:
        img.save()
    img.filepath = img.filepath_raw
    img.source = 'FILE'
    img.reload()
    return img


def final_images(col, ao, nrm, size):
    """Couleur x occlusion (modérée : les cavités s'assombrissent, pas les surfaces dégagées) ;
    hors des îlots, la couleur moyenne (pas de noir qui remonte dans les mipmaps aux coutures)."""
    c = pixels(col)                     # (déjà en sRGB : image 8 bits sRGB)
    a = pixels(ao)
    occ = np.where(a[:, 3] > 0.5, np.clip(1.0 - a[:, 0], 0.0, 1.0), 0.0)
    c[:, :3] *= (1.0 - AO_FORCE * occ)[:, None]
    baked = c[:, 3] > 0.5
    c[~baked, :3] = c[baked, :3].mean(0)
    c[:, 3] = 1.0
    n = pixels(nrm)
    n[n[:, 3] <= 0.5, :3] = (0.5, 0.5, 1.0)
    n[:, 3] = 1.0
    save_image("atlas_ao", np.repeat(1.0 - occ[:, None], 4, 1), size, False)   # (pour contrôle)
    return save_image("atlas_couleur", c, size, True), save_image("atlas_normales", n, size, False)


def export_glb(low, col, nrm):
    """Une surface : baseColor (col) + normalTexture (nrm, tangentes), UV « atlas »."""
    me = low.data
    m = bpy.data.materials.new(KIND)
    m.use_nodes = True
    m.use_backface_culling = True   # (glTF : pas doubleSided, le modèle est fermé)
    nodes, links = m.node_tree.nodes, m.node_tree.links
    nodes.clear()
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Metallic"].default_value = 0.0
    out = nodes.new("ShaderNodeOutputMaterial")
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    tc = nodes.new("ShaderNodeTexImage"); tc.image = col
    links.new(tc.outputs["Color"], bsdf.inputs["Base Color"])
    tn = nodes.new("ShaderNodeTexImage"); tn.image = nrm
    nm = nodes.new("ShaderNodeNormalMap"); nm.space = 'TANGENT'; nm.uv_map = "atlas"
    links.new(tn.outputs["Color"], nm.inputs["Color"])
    links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    me.materials.clear()
    me.materials.append(m)
    me.polygons.foreach_set("material_index", np.zeros(len(me.polygons), np.int32))
    me.update()
    select_only([low], low)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=True, export_tangents=True,
                              export_normals=True, export_texcoords=True, export_materials='EXPORT',
                              export_image_format='AUTO')


def bake_step():
    t0 = time.time()
    bpy.ops.wm.open_mainfile(filepath=WORK + "/modele.blend")
    if HIGH not in bpy.data.objects:   # prep d'avant la v2 : pas de haut gardé
        meshes_step(False)
    scene = bpy.context.scene
    info = json.load(open(WORK + "/info.json"))
    high, low = bpy.data.objects[HIGH], bpy.data.objects[KIND]
    for o in list(scene.objects):
        if o not in (high, low):
            bpy.data.objects.remove(o)
    high.hide_render = low.hide_render = False
    setup_cycles(scene)
    size = ATLAS.get(KIND, 2048)
    atlas_uvs(low, size)
    t1 = time.time()
    col, counts = bake_paint(low, info, size)
    t2 = time.time()
    scene["cage"] = cage_distance(high, low)
    ao = bake_ao(high, low, size)
    t3 = time.time()
    nrm = bake_normals(high, low, size)
    t4 = time.time()
    col, nrm = final_images(col, ao, nrm, size)
    export_glb(low, col, nrm)
    print("TEMPS atlas %.0fs peinture %.0fs ao %.0fs normales %.0fs total %.0fs" %
          (t1 - t0, t2 - t1, t3 - t2, t4 - t3, time.time() - t0))
    print("BAKE_OK", KIND, json.dumps(counts), "cage", list(scene["cage"]), "faces", len(low.data.polygons))


if MODE == "prep":
    meshes_step(True)
    print("PREP_OK", KIND)
elif MODE == "maillages":
    meshes_step(False)
    print("MAILLAGES_OK", KIND)
elif MODE == "bake":
    bake_step()
