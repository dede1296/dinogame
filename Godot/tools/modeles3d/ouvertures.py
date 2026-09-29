"""Vraies ouvertures des bâtiments assemblés (maisons.py, réglage « ouvertures » dans maisons.json) :
une embrasure sans battant, une fenêtre sans vitre, un étal ouvert, ou une porte dont le battant
s'ouvre (contrat des portes animées : scratchpad plan_portes.md, partie A).

Pour chaque ouverture (rectangle [x0, y0, x1, y1] en px de la vue de face) : le mur de façade est
coupé exactement au rectangle (bmesh bisect), le trou est prolongé vers l'intérieur (« profondeur »,
m) : embrasure (partie « ouverture<i> », motif sombre ou nommé), fond (« ouverture_fond<i> » : sombre,
ou « vue » : la vue de face projetée, un étal et ses marchandises) et sol (« ouverture_sol<i> ») ; ou,
avec « piece », l'embrasure jusqu'au devant d'une pièce (interieurs.py : murs, sol, plafond en
motifs du jeu, meubles, détails peints par ComfyUI, lumière cuite). Une porte
(« porte » : {"battants": 1 ou 2, "gonds": "gauche"|"droite", "ouverture": degrés, "epaisseur":
m}) pose son battant fermé dans le trou (parties « porte », ou « porte_g » et « porte_d »),
peint par la vue de face comme avant : fermée, rien ne change. L'export du jeu garde un seul
maillage (la porte fermée) ; export_doors écrit aussi la variante du contrat (corps + battants à
part, origine sur l'axe des gonds, extras « ouverture » et « seuil »).
"""
import json
import math
import os
import numpy as np

EPS = 1e-4


def rect_model(k, rect, yf):
    """Rectangle px de la vue de face -> (x0, x1, z0, z1) du modèle, dans le plan y = yf."""
    x0, y0, x1, y1 = rect
    th = k["theta"]
    xs = sorted(((x0 - k["u0"]) / k["s"], (x1 - k["u0"]) / k["s"]))
    z = lambda v: ((k["v0"] - v) / k["s"] - yf * math.sin(th)) / math.cos(th)
    zs = sorted((z(y0), z(y1)))
    return xs[0], xs[1], zs[0], zs[1]


def facade_faces(bm, layer, murs_id, x0, x1, z0, z1, margin=0.4):
    """Faces du mur de façade (tournées vers l'avant) autour du rectangle."""
    out = []
    for f in bm.faces:
        if f[layer] != murs_id or f.normal.y > -0.6:
            continue
        c = f.calc_center_median()
        if x0 - margin < c.x < x1 + margin and z0 - margin < c.z < z1 + margin:
            out.append(f)
    return out


def cut(house, cfg, cal):
    """Découpe les ouvertures de cfg["ouvertures"] dans le maillage fin (après ajuste) ; ajoute
    embrasure, fond, sol et battants (parties nouvelles, avec leur peintre), et les pièces où elles
    mènent (« piece » : interieurs.py). Rend la liste des portes : [{nom, gond (x, y, z),
    ouverture, seuil (x, y)}] ; house["interieurs"] : le dedans de chaque pièce ou ouverture
    (parties, ouvertures qui l'éclairent, boîte, peinture ComfyUI)."""
    import bmesh
    from mathutils import Vector
    import interieurs
    ops = cfg.get("ouvertures", [])
    if not ops:
        return []
    names = list(house["parts"])
    painters = json.loads(house["peintres"])

    def pid(name, painter):
        if name not in names:
            names.append(name)
        painters.setdefault(name, painter)
        return names.index(name)

    me = house.data
    bm = bmesh.new()
    bm.from_mesh(me)
    layer = bm.faces.layers.int.get("part")
    murs_id = names.index("murs")
    k = cal["face"]
    rooms = cfg.get("pieces", [])
    doors, infos, into = [], [], {}
    for i, op in enumerate(ops):
        yf0 = cfg["murs"].get("y0", 0.0)
        # (« m » : [x0, x1, z0, z1] en m du modèle, au lieu d'un rectangle de la vue de face)
        x0, x1, z0, z1 = op["m"] if op.get("m") else rect_model(k, op["rect"], yf0)
        z0 = max(z0, cfg["murs"].get("z0", 0.0))
        depth = op.get("profondeur", 0.6)
        faces = facade_faces(bm, layer, murs_id, x0, x1, z0, z1)
        if not faces:
            print("OUVERTURE : pas de mur de façade pour", op["rect"])
            continue
        yf = float(np.median([f.calc_center_median().y for f in faces]))
        for co, no in (((x0, 0, 0), (1, 0, 0)), ((x1, 0, 0), (1, 0, 0)), ((0, 0, z0), (0, 0, 1)), ((0, 0, z1), (0, 0, 1))):
            faces = facade_faces(bm, layer, murs_id, x0, x1, z0, z1)
            edges = list({e for f in faces for e in f.edges})
            verts = list({v for f in faces for v in f.verts})
            bmesh.ops.bisect_plane(bm, geom=faces + edges + verts, plane_co=Vector(co), plane_no=Vector(no), dist=EPS)
        faces = facade_faces(bm, layer, murs_id, x0, x1, z0, z1)
        inside = [f for f in faces if x0 + EPS < f.calc_center_median().x < x1 - EPS and z0 + EPS < f.calc_center_median().z < z1 - EPS]
        bmesh.ops.delete(bm, geom=inside, context='FACES')   # (et les arêtes, sommets du dedans du trou)
        # le bord du trou : arêtes libres dont les deux bouts sont sur le rectangle
        on_rect = lambda v: (abs(v.co.x - x0) < 2e-3 or abs(v.co.x - x1) < 2e-3 or abs(v.co.z - z0) < 2e-3 or abs(v.co.z - z1) < 2e-3)             and x0 - 2e-3 <= v.co.x <= x1 + 2e-3 and z0 - 2e-3 <= v.co.z <= z1 + 2e-3
        rim = [e for e in bm.edges if e.is_boundary and all(on_rect(v) for v in e.verts)
               and abs(e.verts[0].co.y - yf) < 0.35]
        # (le bas d'une porte au pied du mur : le trou y est ouvert, il n'a pas d'arête)
        bottom_open = not any(abs(e.verts[0].co.z - z0) < 2e-3 and abs(e.verts[1].co.z - z0) < 2e-3 for e in rim)
        r = op.get("piece")
        jamb_d = rooms[r]["y"][0] - yf if r is not None else depth   # (vers une pièce : jusqu'à son devant)
        ret = bmesh.ops.extrude_edge_only(bm, edges=rim)
        new_v = [g for g in ret["geom"] if isinstance(g, bmesh.types.BMVert)]
        new_f = [g for g in ret["geom"] if isinstance(g, bmesh.types.BMFace)]
        for v in new_v:
            v.co.y = yf + jamb_d
        own = ["ouverture%d" % i]
        jamb = pid(own[0], "tuile:" + op.get("embrasure", "dedans"))
        for f in new_f:
            f[layer] = jamb
        if r is None:   # le fond : les sommets du bord repoussé, en tour (sans pièce derrière)
            back = list(new_v)
            ang = lambda v: math.atan2(v.co.z - (z0 + z1) / 2, v.co.x - (x0 + x1) / 2)
            back.sort(key=ang)   # (rectangle : le tour dans l'ordre des angles)
            fond = bm.faces.new(back)
            own.append("ouverture_fond%d" % i)
            fond[layer] = pid(own[-1], "face" if op.get("fond") == "vue" else "tuile:" + op.get("embrasure", "dedans"))
            if fond.normal.y > 0:
                fond.normal_flip()
        if bottom_open:   # (une porte au pied du mur : son seuil, le sol du dedans ; sinon l'appui est l'embrasure)
            sol = bm.faces.new([bm.verts.new((x0, yf, z0)), bm.verts.new((x1, yf, z0)),
                                bm.verts.new((x1, yf + jamb_d, z0)), bm.verts.new((x0, yf + jamb_d, z0))])
            own.append("ouverture_sol%d" % i)
            sol[layer] = pid(own[-1], "tuile:" + op.get("sol", "dedans_sol"))
            if sol.normal.z < 0:
                sol.normal_flip()
        for f in new_f:   # l'embrasure regarde vers le trou
            c = f.calc_center_median()
            inward = Vector(((x0 + x1) / 2 - c.x, 0.0, (z0 + z1) / 2 - c.z))
            if f.normal.dot(inward) < 0:
                f.normal_flip()
        light = {"poly": [[x0, z0], [x1, z0], [x1, z1], [x0, z1]], "y": yf, "sens": 1.0}
        if r is None:
            infos.append({"cle": "ouverture%d" % i, "parts": own, "ouvertures": [light],
                          "boite": [[x0, x1], [yf, yf + depth], [z0, z1]], "lumiere": op.get("lumiere", {})})
        else:
            into.setdefault(r, {"parts": [], "ouvertures": [], "yf": yf})
            into[r]["parts"] += own
            into[r]["ouvertures"].append(light)
            into[r]["yf"] = min(into[r]["yf"], yf)
        door = op.get("porte")
        if door:   # (le seuil du contrat : « profondeur », comme avant les pièces)
            doors += leaves(bm, layer, pid, door, x0, x1, z0, z1, yf, depth)
    for r, got in sorted(into.items()):   # les pièces derrière (interieurs.py)
        rc = rooms[r]
        interieurs.check_room(cfg, rc, r)
        parts = interieurs.build_room(bm, layer, pid, rc, r)
        infos.append({"cle": "piece%d" % r, "parts": got["parts"] + parts, "ouvertures": got["ouvertures"],
                      "boite": [rc["x"], [got["yf"], rc["y"][1]], rc["z"]], "decor": rc.get("decor"),
                      "lumiere": rc.get("lumiere", {})})
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    me.update()
    house["parts"] = names
    house["peintres"] = json.dumps(painters)
    house["interieurs"] = json.dumps(infos)
    return doors


def leaves(bm, layer, pid, door, x0, x1, z0, z1, yf, depth):
    """Battant(s) fermé(s) dans le trou (boîtes minces au nu de la façade, peints par la vue de
    face) ; rend les portes du contrat (gond, angle, seuil)."""
    ep = door.get("epaisseur", 0.06)
    gap = 0.004
    n = door.get("battants", 1)
    out = []
    spans = [(x0, x1)] if n == 1 else [(x0, (x0 + x1) / 2), ((x0 + x1) / 2, x1)]
    for i, (a, b) in enumerate(spans):
        name = "porte" if n == 1 else ("porte_g", "porte_d")[i]
        hinge_left = (door.get("gonds", "gauche") == "gauche") if n == 1 else (i == 0)
        pi = pid(name, "boite_face")
        xa, xb = a + gap, b - gap
        ya, yb = yf + 0.01, yf + 0.01 + ep
        za, zb = z0 + gap, z1 - gap
        v = [bm.verts.new(p) for p in ((xa, ya, za), (xb, ya, za), (xb, yb, za), (xa, yb, za),
                                          (xa, ya, zb), (xb, ya, zb), (xb, yb, zb), (xa, yb, zb))]
        for idx in ((0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 6, 7), (3, 2, 1, 0)):
            f = bm.faces.new([v[j] for j in idx])
            f[layer] = pi
        angle = abs(door.get("ouverture", 100.0))
        out.append({"nom": name, "gond": [xa if hinge_left else xb, ya, za],
                    # (glTF : Y en haut, façade vers +Z ; une rotation positive autour de Y pousse vers -Z, l'intérieur,
                    # un battant qui s'étend vers +x : gond à gauche)
                    "ouverture": angle if hinge_left else -angle,
                    "seuil": [(x0 + x1) / 2, yf + min(0.45, depth * 0.6)]})
    return out


def export_doors(house, doors, kind, out_dir, export_glb_fn):
    """Variante du contrat (partie A) : corps et battants en objets séparés (même matière), origine
    des battants sur l'axe des gonds, extras « ouverture » et « seuil » (x, z du repère glTF)."""
    import bpy
    import bmesh
    if not doors:
        return None
    names = list(house["parts"])
    body = house.copy()
    body.data = house.data.copy()
    bpy.context.scene.collection.objects.link(body)
    body.name = kind
    objs = [body]
    for d in doors:
        pi = names.index(d["nom"])
        leaf = house.copy()
        leaf.data = house.data.copy()
        bpy.context.scene.collection.objects.link(leaf)
        bm = bmesh.new(); bm.from_mesh(leaf.data)
        layer = bm.faces.layers.int.get("part")
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f[layer] != pi], context='FACES')
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
        g = d["gond"]
        for v in bm.verts:   # origine sur l'axe des gonds, au pied
            v.co.x -= g[0]; v.co.y -= g[1]; v.co.z -= g[2]
        bm.to_mesh(leaf.data); bm.free()
        leaf.location = (g[0], g[1], g[2])
        leaf.name = d["nom"]
        leaf["ouverture"] = d["ouverture"]
        leaf["seuil"] = [round(d["seuil"][0], 3), round(-d["seuil"][1], 3)]
        objs.append(leaf)
    bm = bmesh.new(); bm.from_mesh(body.data)
    layer = bm.faces.layers.int.get("part")
    ids = {names.index(d["nom"]) for d in doors}
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f[layer] in ids], context='FACES')
    bm.to_mesh(body.data); bm.free()
    for o in objs:   # (seules « ouverture » et « seuil » en extras)
        for key in ("parts", "peintres", "interieurs"):
            if key in o:
                del o[key]
    out = os.path.join(out_dir, kind + ".glb")
    export_glb_fn(objs, out)
    for o in objs:
        bpy.data.objects.remove(o)
    return out
