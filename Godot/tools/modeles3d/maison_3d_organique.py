"""La maison de pierre en vrai 3D pour Ambrelune, version « organique » : murs bosseles aux
coins arrondis, vraies pierres irregulieres (chaines d'angle, encadrements, soubassement),
ardoises posees rang par rang, faitage de tuiles, cheminee de pierres.
  blender --background --python maison_3d_organique.py -- render
      deux vues sous l'angle de la camera du jeu (40 deg) : face et cote -> ComfyUI
  blender --background --python maison_3d_organique.py -- bake <peinture_face> <peinture_cote> <sortie.glb>
      chaque face prend la vue qui la voit le mieux sans obstacle (rayon), l'arriere et l'ouest
      en miroir ; origine au pied de la facade (porte), echelle du jeu, export glTF.
"""
import bpy, bmesh, math, sys, random
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from bpy_extras.object_utils import world_to_camera_view

HERE = "C:/ComfyUI_windows_portable/blender_tests"
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["render"]
W, D, H = 4.0, 3.0, 1.8
ROOF_H = 1.3
EAVE = 0.3                       # debord du toit
GAME_SCALE = 1.6
PITCH = math.radians(40.0)
TARGET = Vector((0.0, 0.0, 1.4))
DIST = 10.0
RES = 640
rng = random.Random(7)

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def mat(name, rgb):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*rgb, 1.0)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    return m


WALL, STONE = mat("wall", (0.86, 0.83, 0.76)), mat("stone", (0.72, 0.66, 0.55))
SLATE, DOOR = mat("slate", (0.30, 0.37, 0.46)), mat("door", (0.28, 0.44, 0.60))
GLASS, CHIM = mat("glass", (0.55, 0.68, 0.78)), mat("chimney", (0.58, 0.44, 0.34))
BUMPS = bpy.data.textures.new("bosses", 'CLOUDS')
BUMPS.noise_scale = 0.45


def box(size, loc, m, rot=(0.0, 0.0, 0.0), bevel=0.0, segs=2, jitter=0.0, name="bloc"):
    """Pave de `size` (m), sommets un peu deplaces (`jitter`), aretes arrondies (`bevel`)."""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0] + rng.uniform(-jitter, jitter),
                       v.co.y * size[1] + rng.uniform(-jitter, jitter),
                       v.co.z * size[2] + rng.uniform(-jitter, jitter)))
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    scene.collection.objects.link(ob)
    ob.location = loc
    ob.rotation_euler = rot
    me.materials.append(m)
    if bevel > 0.0:
        md = ob.modifiers.new("bevel", 'BEVEL')
        md.width, md.segments, md.limit_method = bevel, segs, 'NONE'
    return ob


def lumpy(ob, levels=3, strength=0.05):
    sub = ob.modifiers.new("sub", 'SUBSURF')
    sub.subdivision_type, sub.levels, sub.render_levels = 'SIMPLE', levels, levels
    d = ob.modifiers.new("bosses", 'DISPLACE')
    d.texture, d.strength, d.mid_level = BUMPS, strength, 0.5


def stone(size, loc, rot_z=0.0):
    """Une pierre : taille un peu variee, sommets deplaces, aretes rondes, legerement tournee."""
    s = (size[0] * rng.uniform(0.9, 1.1), size[1] * rng.uniform(0.9, 1.1), size[2] * rng.uniform(0.9, 1.1))
    rot = (rng.uniform(-0.04, 0.04), rng.uniform(-0.04, 0.04), rot_z + rng.uniform(-0.05, 0.05))
    return box(s, loc, STONE, rot, bevel=min(s) * 0.3, segs=2, jitter=min(s) * 0.12, name="pierre")


# --- les murs et les pignons (plein, bosseles, coins arrondis) --------------------------------
def walls():
    lumpy(box((W, D, H), (0, 0, H / 2), WALL, bevel=0.12, segs=3, name="murs"), levels=3, strength=0.06)
    for sx in (-1, 1):   # pignon : prisme triangulaire de mur sous le toit
        me = bpy.data.meshes.new("pignon")
        x0, x1 = sx * (W / 2 - 0.02), sx * 0.2
        verts = [(x0, -D / 2, H), (x0, D / 2, H), (x0, 0, H + ROOF_H - 0.12),
                 (x1, -D / 2, H), (x1, D / 2, H), (x1, 0, H + ROOF_H - 0.12)]
        faces = [(0, 1, 2), (3, 5, 4), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)] if sx > 0 else \
                [(0, 2, 1), (3, 4, 5), (0, 1, 4, 3), (1, 2, 5, 4), (2, 0, 3, 5)]
        me.from_pydata(verts, [], faces)
        me.update()
        ob = bpy.data.objects.new("pignon", me)
        scene.collection.objects.link(ob)
        me.materials.append(WALL)
        lumpy(ob, levels=3, strength=0.04)


# --- les pierres ----------------------------------------------------------------------------------
def quoins():
    """Chaines d'angle : pierres longues et courtes alternees, qui enveloppent chaque coin."""
    for sx in (-1, 1):
        for sy in (-1, 1):
            z, i = 0.0, 0
            while z < H - 0.1:
                h = rng.uniform(0.22, 0.3)
                long_front = (i % 2 == 0)
                lx, ly = (0.55, 0.3) if long_front else (0.3, 0.55)
                cx = sx * (W / 2 + 0.05 - lx / 2)
                cy = sy * (D / 2 + 0.05 - ly / 2)
                stone((lx, ly, h - 0.03), (cx, cy, z + h / 2))
                z += h
                i += 1


def frame(cx, bottom, width, height, lintel=True):
    """Encadrement d'une ouverture de la facade (y = -D/2) : piedroits, linteau, appui."""
    y = -D / 2 - 0.03
    z = bottom
    while z < bottom + height - 0.05:
        h = rng.uniform(0.17, 0.24)
        for side in (-1, 1):
            w = rng.choice((0.2, 0.28))
            stone((w, 0.14, h - 0.025), (cx + side * (width / 2 + w / 2 - 0.02), y, z + h / 2))
        z += h
    if lintel:
        stone((width + 0.34, 0.16, 0.18), (cx, y - 0.01, bottom + height + 0.08))


def base_and_scattered():
    for sy in (-1, 1):   # soubassement devant et derriere
        x = -W / 2 + 0.2
        while x < W / 2 - 0.2:
            w = rng.uniform(0.3, 0.45)
            if not (sy < 0 and abs(x + w / 2) < 0.55):   # pas devant la porte
                stone((w - 0.03, 0.12, rng.uniform(0.14, 0.2)), (x + w / 2, sy * (D / 2 + 0.02), 0.08))
            x += w
    for sx in (-1, 1):   # soubassement des pignons
        y = -D / 2 + 0.3
        while y < D / 2 - 0.3:
            w = rng.uniform(0.3, 0.45)
            stone((0.12, w - 0.03, rng.uniform(0.14, 0.2)), (sx * (W / 2 + 0.02), y + w / 2, 0.08))
            y += w
    # quelques pierres apparentes dans l'enduit
    for (x, z) in ((-1.9 + 0.25, 1.45), (-0.75, 1.55), (0.8, 1.5), (1.75, 0.55), (-1.75, 0.5), (0.55, 0.3)):
        stone((rng.uniform(0.14, 0.24), 0.06, rng.uniform(0.1, 0.15)), (x, -D / 2 - 0.02, z))
    for (y, z) in ((-0.6, 1.2), (0.7, 0.6), (0.1, 1.6)):
        for sx in (-1, 1):
            stone((0.06, rng.uniform(0.14, 0.24), rng.uniform(0.1, 0.15)), (sx * (W / 2 + 0.02), y, z))


def openings():
    # porte, un peu en retrait entre ses pierres
    box((0.66, 0.08, 1.12), (0, -D / 2 + 0.01, 0.58), DOOR, bevel=0.02, name="porte")
    frame(0.0, 0.05, 0.7, 1.12)
    stone((0.9, 0.3, 0.07), (0, -D / 2 - 0.12, 0.035))   # seuil
    # fenetres : vitre, encadrement, appui, volets entrouverts
    for cx in (-1.3, 1.3):
        box((0.5, 0.06, 0.56), (cx, -D / 2 + 0.01, 0.9), GLASS, name="vitre")
        box((0.06, 0.07, 0.56), (cx, -D / 2 - 0.0, 0.9), DOOR, name="croisillon")
        box((0.5, 0.07, 0.05), (cx, -D / 2 - 0.0, 0.9), DOOR, name="croisillon")
        frame(cx, 0.62, 0.54, 0.56)
        stone((0.78, 0.2, 0.08), (cx, -D / 2 - 0.08, 0.6))   # appui
        for side in (-1, 1):
            box((0.26, 0.04, 0.6), (cx + side * 0.56, -D / 2 - 0.12, 0.92), DOOR,
                rot=(0, 0, side * math.radians(12)), bevel=0.012, jitter=0.01, name="volet")
    # une petite fenetre sur chaque pignon
    for sx in (-1, 1):
        box((0.06, 0.34, 0.36), (sx * (W / 2 - 0.01), 0.3, 1.0), GLASS, name="vitre")
        for dz in (-0.24, 0.24):
            stone((0.14, 0.52, 0.12), (sx * (W / 2 + 0.03), 0.3, 1.0 + dz))


# --- le toit ----------------------------------------------------------------------------------------
SLOPE = math.atan2(ROOF_H, D / 2 + EAVE)
SLOPE_LEN = math.hypot(ROOF_H, D / 2 + EAVE)


def on_slope(sy, u, v, lift):
    """Point du pan (sy = -1 devant, +1 derriere) : u le long du faitage, v de l'egout vers le faitage."""
    y = sy * (D / 2 + EAVE) - sy * v * math.cos(SLOPE)
    z = H - 0.02 + v * math.sin(SLOPE)
    ny, nz = sy * math.sin(SLOPE), math.cos(SLOPE)
    return Vector((u, y + ny * lift, z + nz * lift))


def roof():
    for sy in (-1, 1):
        # le support du pan (cache sous les ardoises)
        c = on_slope(sy, 0.0, SLOPE_LEN / 2, -0.05)
        box((W + 2 * EAVE, SLOPE_LEN, 0.08), c, SLATE, rot=(-sy * SLOPE, 0, 0), name="volige")
        rows = 8
        step = SLOPE_LEN / rows
        for r in range(rows):
            u = -(W / 2 + EAVE) + rng.uniform(0.0, 0.15)
            while u < W / 2 + EAVE - 0.08:
                w = min(rng.uniform(0.28, 0.42), W / 2 + EAVE - u)
                v = r * step + step * 0.6 + rng.uniform(-0.02, 0.02)
                c = on_slope(sy, u + w / 2, v, 0.02 + r * 0.004)
                rot = (-sy * SLOPE + rng.uniform(-0.05, 0.05), rng.uniform(-0.04, 0.04), rng.uniform(-0.05, 0.05))
                box((w - 0.025, step * 1.35, 0.035), c, SLATE, rot=rot, bevel=0.012, segs=1, jitter=0.012, name="ardoise")
                u += w
    # faitage : tuiles rondes irregulieres
    u = -(W / 2 + EAVE) - 0.05
    while u < W / 2 + EAVE:
        w = rng.uniform(0.34, 0.44)
        box((w, 0.3, 0.16), (u + w / 2, 0, H + ROOF_H + 0.02), STONE,
            rot=(rng.uniform(-0.05, 0.05), 0, rng.uniform(-0.05, 0.05)), bevel=0.07, segs=3, jitter=0.02, name="faitiere")
        u += w - 0.03


def chimney():
    cx, cy = W / 2 - 0.55, 0.35
    z = H + 0.6
    while z < H + ROOF_H + 0.45:
        h = rng.uniform(0.14, 0.2)
        for dx in (-0.12, 0.12):
            box((0.26, 0.5, h - 0.02), (cx + dx, cy, z + h / 2), CHIM, bevel=0.03, segs=2, jitter=0.015, name="chem")
        z += h
    box((0.62, 0.62, 0.07), (cx, cy, z + 0.03), STONE, bevel=0.02, jitter=0.01, name="chapeau")


def build():
    walls()
    quoins()
    base_and_scattered()
    openings()
    roof()
    chimney()


def camera(name, azimuth_deg):
    az = math.radians(azimuth_deg)
    d = Vector((math.sin(az) * math.cos(PITCH), -math.cos(az) * math.cos(PITCH), math.sin(PITCH)))
    cam = bpy.data.objects.new(name, bpy.data.cameras.new(name))
    scene.collection.objects.link(cam)
    cam.location = TARGET + d * DIST
    cam.rotation_euler = (TARGET - cam.location).to_track_quat('-Z', 'Y').to_euler()
    return cam


build()
CAMS = {"face": camera("cam_face", 0.0), "cote": camera("cam_cote", 90.0)}
scene.render.resolution_x = scene.render.resolution_y = RES

if ARGS[0] == "render":
    for energy, rot in ((3.0, (55, 0, -35)), (1.2, (60, 0, 140))):
        bpy.ops.object.light_add(type='SUN')
        sun = bpy.context.active_object
        sun.data.energy = energy
        sun.rotation_euler = tuple(math.radians(a) for a in rot)
    world = bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.35
    scene.view_settings.view_transform = 'Standard'
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.film_transparent = True
    scene.render.image_settings.color_mode = 'RGBA'
    for name, cam in CAMS.items():
        scene.camera = cam
        scene.render.filepath = f"{HERE}/renders/organique40_{name}.png"
        bpy.ops.render.render(write_still=True)
        print("rendu:", scene.render.filepath)

elif ARGS[0] == "bake":
    face_png, side_png, out_glb = ARGS[1], ARGS[2], ARGS[3]
    meshes = [o for o in scene.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.convert(target='MESH')          # applique biseaux, subdivisions, bosses
    bpy.ops.object.join()
    house = bpy.context.active_object
    house.name = "maison_3d"
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    me = house.data
    me.materials.clear()
    for key, png in (("face", face_png), ("cote", side_png)):
        m = bpy.data.materials.new("peint_" + key)
        m.use_nodes = True
        bsdf = m.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Roughness"].default_value = 1.0
        tex = m.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(png)
        m.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        me.materials.append(m)
    while me.uv_layers:
        me.uv_layers.remove(me.uv_layers[0])
    uv = me.uv_layers.new(name="peinture")
    me.uv_layers.active = uv
    bvh = BVHTree.FromObject(house, bpy.context.evaluated_depsgraph_get())
    # (camera, miroir, materiau) : la face, l'arriere = la face en miroir, l'est, l'ouest = l'est en miroir
    options = [(CAMS["face"], Vector((1, 1, 1)), 0), (CAMS["face"], Vector((1, -1, 1)), 0),
               (CAMS["cote"], Vector((1, 1, 1)), 1), (CAMS["cote"], Vector((-1, 1, 1)), 1)]
    hidden = 0
    for poly in me.polygons:
        best, best_score = options[0], -9.0
        for cam, mirror, index in options:
            c = poly.center * mirror
            n = poly.normal * mirror
            to_cam = cam.location - c
            dist = to_cam.length
            to_cam.normalize()
            score = n.dot(to_cam)
            if score > 0.05:
                hit = bvh.ray_cast(c + n * 0.01, to_cam, dist)
                if hit[0] is not None:          # quelque chose la cache a cette camera
                    score -= 1.0
            if score > best_score:
                best, best_score = (cam, mirror, index), score
        if best_score < 0.05:
            hidden += 1
        cam, mirror, index = best
        poly.material_index = index
        for li in poly.loop_indices:
            p = world_to_camera_view(scene, cam, me.vertices[me.loops[li].vertex_index].co * mirror)
            uv.data[li].uv = (p.x, p.y)
    for v in me.vertices:            # origine au pied de la facade (la porte), echelle du jeu
        v.co.y += D / 2
        v.co *= GAME_SCALE
    me.update()
    bpy.ops.object.select_all(action='DESELECT')
    house.select_set(True)
    for c in CAMS.values():
        bpy.data.objects.remove(c)
    bpy.ops.export_scene.gltf(filepath=out_glb, export_format='GLB', use_selection=True)
    print("export:", out_glb, "faces:", len(me.polygons), "faces vues par aucune camera:", hidden)
