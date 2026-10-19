extends RefCounted
## La Terre des Apex (chapter 9): the checks the plans print when they are built (tools/zones/apex_terre.gd,
## apex_coeur.gd; the same rules as the Plaine Volcanique's, tools/zones/volcan_verif.gd, whose helpers
## serve here): each key place reached ON FOOT from the way in — over the relief, and again with the
## solid feet of the scenery as walls (a block of amber must not close the spiral) —; the places that
## must stay out of reach (the rim, the hole's floor, the Roi's perch) not reached; nothing of the story
## (a person, a dino, a page, a spawn) out of reach; no solid decor on a path; nothing floating
## (tools/zones/cieux_pieds.gd); and the FOOTPRINTS of the pictures still to be drawn (the blocks, the
## cairn): their proposed solid feet (docs/zones/apex.md, the patch of world/prop.gd) on level, walkable
## ground, off the paths, so that they fit once drawn.

const B := preload("res://tools/zone_builder.gd")
const V := preload("res://tools/zones/volcan_verif.gd")
const VD := preload("res://tools/zones/volcan_decor.gd")
## Chloé's body (actors/player.tscn: a circle of 11 px, a little margin).
const PLAYER_RADIUS := 13.0
## A footprint's ground may roll this much (m) and still hold a block.
const LEVEL := 0.35


## Every prop of zone `root` standing on the ground (volcan_verif.gd settle_all): what could not be.
static func settle_all(root: Region) -> Array[String]:
	return V.settle_all(root)


## Prints the checks of zone `root` (`label`), from tile `from`: `on_foot` (name -> tile point) reached on
## foot, also with the scenery's solid feet as walls; `opts`: « out » (name -> tile point: never reached),
## « footprints » (name -> [tile point, solid size in px]: the pictures to come), « may_block » (node
## names allowed on a path). Returns the count of failures (0: « tous les lieux sont bons »).
static func check(root: Region, label: String, from: Vector2i, on_foot: Dictionary, floating: Array[String], opts := {}) -> int:
	var foot := V.reach(root, from, {}, {}, false)
	var walls := solid_tiles(root)
	walls.erase(from)
	var around := V.reach(root, from, {}, walls, false)
	var failures := 0
	print("%s : vérifications" % label)
	for place: String in on_foot:
		var c := Vector2i((on_foot[place] as Vector2).floor())
		var ok := foot.has(c) and around.has(c)
		failures += 0 if ok else 1
		print("  %s %s %s (à pied%s) : %.2f m" % ["ok " if ok else "NON", place, c,
			"" if ok else (", bloqué par un décor" if foot.has(c) else ", injoignable"), root.tile_height(c)])
	var out: Dictionary = opts.get("out", {})
	for place: String in out:
		var c := Vector2i((out[place] as Vector2).floor())
		var ok := not foot.has(c)
		failures += 0 if ok else 1
		print("  %s %s %s hors d'atteinte : %.2f m" % ["ok " if ok else "NON", place, c, root.tile_height(c)])
	failures += _story_reached(root, foot, opts.get("unreached_ok", []))
	var prints: Dictionary = opts.get("footprints", {})
	for n: String in prints:
		failures += _footprint(root, n, prints[n][0], prints[n][1])
	var may_block: Array = opts.get("may_block", [])
	for s in V.on_paths(root):
		if not may_block.any(func(n: String) -> bool: return s.begins_with(n + " ")):
			print("  NON décor sur un chemin : ", s)
			failures += 1
	for s in floating:
		print("  NON décor qui flotte, impossible à poser : ", s)
		failures += 1
	print("  %d cases à pied ; %d avec les décors pour murs" % [foot.size(), around.size()])
	print("  %s" % ("tous les lieux sont bons" if failures == 0 else "%d DÉFAUT(S)" % failures))
	return failures


## The tiles under the solid feet of the zone's props (as prop.gd: a box centred solid.y / 2 - 6 px
## above the ground point, or a circle), grown by Chloé's radius: a set.
static func solid_tiles(root: Region) -> Dictionary:
	var out := {}
	for n in root.get_node("Entities").get_children():
		if not n is Prop:
			continue
		var box := solid_box((n as Prop).kind, (n as Node2D).position)
		if not box.has_area():
			continue
		box = box.grow(PLAYER_RADIUS)
		for y in range(floori(box.position.y / B.TILE), ceili(box.end.y / B.TILE)):
			for x in range(floori(box.position.x / B.TILE), ceili(box.end.x / B.TILE)):
				if box.has_point((Vector2(x, y) + Vector2(0.5, 0.5)) * B.TILE):
					out[Vector2i(x, y)] = true
	return out


## The solid foot (px) of a prop of `kind_` at ground point `at` (px); an empty Rect2 when none.
static func solid_box(kind_: String, at: Vector2, solid: Variant = null) -> Rect2:
	var s: Variant = solid if solid != null else VD.def(kind_).get("solid", 0.0)
	if s is Vector2:
		return Rect2(at + Vector2(-s.x / 2.0, -s.y + 6.0), s)
	if float(s) > 0.0:
		return Rect2(at - Vector2(s, s), Vector2(s, s) * 2.0)
	return Rect2()


## A picture to come at tile point `t`, its solid foot `solid` (px): every tile under it walkable, level
## within LEVEL, not a path. One line; 1 when it does not fit.
static func _footprint(root: Region, label: String, t: Vector2, solid: Vector2) -> int:
	var box := solid_box("", t * B.TILE, solid)
	var terrain: TileMapLayer = root.get_node("Terrain")
	var lo := INF
	var hi := -INF
	var bad := ""
	for y in range(floori(box.position.y / B.TILE), ceili(box.end.y / B.TILE)):
		for x in range(floori(box.position.x / B.TILE), ceili(box.end.x / B.TILE)):
			var c := Vector2i(x, y)
			var data := terrain.get_cell_tile_data(c)
			var ground := String(data.get_custom_data("terrain")) if data else ""
			if not ground in B.WALKABLE:
				bad = "sol %s en %s" % [ground, c]
			elif ground == "path":
				bad = "chemin en %s" % c
			lo = minf(lo, root.tile_height(c))
			hi = maxf(hi, root.tile_height(c))
	if bad == "" and hi - lo > LEVEL:
		bad = "pas de niveau (%.2f m d'écart)" % (hi - lo)
	print("  %s empreinte %s %s (%.0f × %.0f px) : %s" % ["ok " if bad == "" else "NON", label, Vector2i(t.floor()), solid.x, solid.y,
		"tient" if bad == "" else bad])
	return 0 if bad == "" else 1


## The story's things (people, dinos, pages, story props, spawns) standing where Chloé cannot walk to
## (but those named in `ok`: the ones meant to be out of reach). Failures.
static func _story_reached(root: Region, foot: Dictionary, ok: Array) -> int:
	var bad := 0
	var things: Array = root.get_node("Spawns").get_children()
	for n in root.get_node("Entities").get_children():
		var plain: bool = n.get_script() == Prop and (n as Prop).hidden_pebble == &""
		if n is Node2D and not plain and not n is TallGrass and not String(n.name) in ok:
			things.append(n)
	for n: Node2D in things:
		var t := Vector2i((n.position / B.TILE).floor())
		var near := false
		for d in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(0, 2)]:
			near = near or foot.has(t + d)
		if not near:
			print("  NON hors d'atteinte : %s %s" % [n.name, t])
			bad += 1
	return bad
