extends RefCounted
## La Plaine Volcanique (chapter 8): the checks the five zone plans print when they are built
## (tools/zones/volcan_*.gd). The lava (the Region meta « lave », tools/zones/volcan_canvas.gd) keeps
## Chloé out on foot: each key place must be reached ON FOOT from the way in without stepping on it, or,
## for those beyond a flow, only ON THE BACK of a stone or fire dino (lava crossed); the lava that goes
## back (meta « lave_retrait ») stops everyone until « lave_retiree ». Then: nothing of the story (a
## person, a dino, a page, a sign, a spawn, an amber pebble) on the lava; no solid decor on a path (but
## the obstacles that are meant to close one: the barricade); nothing floating (tools/zones/
## cieux_pieds.gd, the Cieux' measure).

const B := preload("res://tools/zone_builder.gd")
const C := preload("res://tools/zones/volcan_canvas.gd")
const D := preload("res://tools/zones/volcan_decor.gd")
const F := preload("res://tools/zones/cieux_pieds.gd")
## Chloé's body (actors/player.tscn: a circle of 11 px, a little margin).
const PLAYER_RADIUS := 13.0


## Every prop of zone `root` standing on the ground, as cieux_pieds.gd settle_all (moved where it floats;
## plain scenery that cannot be, removed), but the things hung up or laid on furniture (a negative foot:
## the gloves on Dame Suie's bench). Returns what could not be settled.
static func settle_all(root: Region) -> Array[String]:
	var hm := HeightMap.new(root, 2)
	var left: Array[String] = []
	for n in root.get_node("Entities").get_children():
		if not n is Prop or float(D.def((n as Prop).kind).get("foot", 0.0)) < 0.0:
			continue
		var plain: bool = n.get_script() == Prop and (n as Prop).hidden_pebble == &""
		var name_ := "%s %s" % [n.name, ((n as Node2D).position / B.TILE).snapped(Vector2(0.1, 0.1))]
		if not F.settle(hm, root, n, plain) and not plain:
			left.append(name_)
	return left


## The tiles of a dose image of zone `root` (its meta `meta`: white = in), as a set.
static func tiles_of(root: Region, meta: StringName) -> Dictionary:
	var out := {}
	if not root.has_meta(meta):
		return out
	var img: Image = root.get_meta(meta)
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).r >= 0.5:
				out[Vector2i(x, y)] = true
	return out


## Tiles Chloé walks to from `from`: walkable ground, no cliff between two of them, never on `walls`,
## on `lava` only when `mounted` (on a stone or fire dino).
static func reach(root: Region, from: Vector2i, lava: Dictionary, walls: Dictionary, mounted: bool) -> Dictionary:
	var terrain: TileMapLayer = root.get_node("Terrain")
	var seen := {from: true}
	var low := root.floor_height()
	var queue: Array[Vector2i] = [from]
	var i := 0
	while i < queue.size():
		var c := queue[i]
		i += 1
		var h := root.tile_height(c)
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n := c + d
			if seen.has(n) or walls.has(n) or (lava.has(n) and not mounted):
				continue
			var data := terrain.get_cell_tile_data(n)
			if data == null or not String(data.get_custom_data("terrain")) in B.WALKABLE:
				continue
			if root.cliff_between(root.tile_height(n), h, low):
				continue
			seen[n] = true
			queue.append(n)
	return seen


## Prints the checks of zone `root` (`label`): each place of `on_foot` reached on foot from tile
## `from`, each of `mounted` only on a stone or fire dino; the rest (see the header). `floating`: what
## cieux_pieds.gd could not settle. `opts`: « may_block » (node names allowed to close a path),
## « closed » (node name -> the places it must cut off while it stands: the barricade, its solid foot,
## Chloé's width round it), « after_retreat » (places reached, on such a dino, only once the lava has
## gone back). Returns the count of failures (0: « tous les lieux sont bons »).
static func check(root: Region, label: String, from: Vector2i, on_foot: Dictionary, mounted: Dictionary,
		floating: Array[String], opts := {}) -> int:
	var lava := tiles_of(root, C.LAVA_META)
	var going := tiles_of(root, C.RETREAT_META)
	var foot := reach(root, from, lava, going, false)
	var ride := reach(root, from, lava, going, true)
	var failures := 0
	print("%s : vérifications" % label)
	failures += _closed(root, from, lava, going, opts.get("closed", {}))
	failures += _places(root, on_foot, func(c: Vector2i) -> bool: return foot.has(c), "à pied, sans lave", foot)
	failures += _places(root, mounted, func(c: Vector2i) -> bool: return ride.has(c) and not foot.has(c),
		"seulement sur un dino de pierre ou de feu", foot)
	var later: Dictionary = opts.get("after_retreat", {})
	if not later.is_empty():
		var after := reach(root, from, lava, {}, true)
		failures += _places(root, later, func(c: Vector2i) -> bool: return after.has(c) and not ride.has(c),
			"seulement une fois la lave retirée, sur un dino de pierre ou de feu", foot)
	failures += _on_lava(root, lava.merged(going))
	var may_block: Array = opts.get("may_block", [])
	for s in on_paths(root):
		if not may_block.any(func(n: String) -> bool: return s.begins_with(n + " ")):
			print("  NON décor sur un chemin : ", s)
			failures += 1
	for s in floating:
		print("  NON décor qui flotte, impossible à poser : ", s)
		failures += 1
	print("  lave : %d cases (+ %d qui se retirent) ; sol injoignable même sur un dino de pierre ou de feu : %d cases" % [
		lava.size(), going.size(), _lost(root, reach(root, from, lava, {}, true), lava)])
	print("  %s" % ("tous les lieux sont bons" if failures == 0 else "%d DÉFAUT(S)" % failures))
	return failures


## One line a place of `places` (name -> tile point): ok when `test` (tile) says so. Failures.
static func _places(root: Region, places: Dictionary, test: Callable, how: String, foot: Dictionary) -> int:
	var bad := 0
	for place: String in places:
		var c := Vector2i((places[place] as Vector2).floor())
		var ok: bool = test.call(c)
		bad += 0 if ok else 1
		print("  %s %s %s (%s) : %.2f m%s" % ["ok " if ok else "NON", place, c, how, root.tile_height(c),
			"" if how.begins_with("à pied") else ", à pied %s" % ("oui" if foot.has(c) else "non")])
	return bad


## The places each obstacle of `closed` (node name -> tile points) must cut off on foot. Failures.
static func _closed(root: Region, from: Vector2i, lava: Dictionary, going: Dictionary, closed: Dictionary) -> int:
	var bad := 0
	for node_name: String in closed:
		var foot_of: Dictionary = covered(root, node_name)
		var cut := reach(root, from, lava, going.merged(foot_of), false)
		for t: Vector2 in closed[node_name]:
			var c := Vector2i(t.floor())
			var ok: bool = not cut.has(c) and not foot_of.is_empty()
			bad += 0 if ok else 1
			print("  %s %s fermé par %s tant qu'il est là" % ["ok " if ok else "NON", c, node_name])
	return bad


## The tiles whose middle the solid foot of Entities/`node_name` covers (prop.gd: a box centred
## solid.y / 2 - 6 px above the ground point, or a circle), grown by Chloé's radius.
static func covered(root: Region, node_name: String) -> Dictionary:
	var out := {}
	var n := root.get_node_or_null("Entities/" + node_name) as Prop
	if n == null:
		return out
	var solid: Variant = D.def(n.kind).get("solid", 0.0)
	var box := Rect2()
	if solid is Vector2:
		box = Rect2(n.position + Vector2(-solid.x / 2.0, -solid.y + 6.0), solid)
	elif float(solid) > 0.0:
		box = Rect2(n.position - Vector2(solid, solid), Vector2(solid, solid) * 2.0)
	else:
		return out
	box = box.grow(PLAYER_RADIUS)
	for y in range(floori(box.position.y / B.TILE), ceili(box.end.y / B.TILE)):
		for x in range(floori(box.position.x / B.TILE), ceili(box.end.x / B.TILE)):
			if box.has_point((Vector2(x, y) + Vector2(0.5, 0.5)) * B.TILE):
				out[Vector2i(x, y)] = true
	return out


## Every solid prop whose foot stands on a path (it would block the way; as cieux_decor.gd on_paths,
## the kinds read through volcan_decor.gd def): their names and tiles.
static func on_paths(root: Region) -> Array[String]:
	var terrain: TileMapLayer = root.get_node("Terrain")
	var out: Array[String] = []
	for n in root.get_node("Entities").get_children():
		if not n is Prop or n is Pickup:
			continue
		var solid: Variant = D.def((n as Prop).kind).get("solid", 0.0)
		if solid is float and solid <= 0.0:
			continue
		var tile := Vector2i(((n as Node2D).position / B.TILE).floor())
		var d := terrain.get_cell_tile_data(tile)
		if d and String(d.get_custom_data("terrain")) == "path":
			out.append("%s %s" % [n.name, tile])
	return out


## The story's things standing on the lava (people, dinos, pages, signs, story props, amber pebbles,
## the spawns): one line each. Returns how many.
static func _on_lava(root: Region, lava: Dictionary) -> int:
	var bad := 0
	var things: Array = root.get_node("Spawns").get_children()
	for n in root.get_node("Entities").get_children():
		var plain: bool = n.get_script() == Prop and (n as Prop).hidden_pebble == &""
		if n is Node2D and not plain and not n is TallGrass:
			things.append(n)
	for n: Node2D in things:
		var t := Vector2i((n.position / B.TILE).floor())
		if lava.has(t):
			print("  NON sur la lave : %s %s" % [n.name, t])
			bad += 1
	return bad


## Walkable tiles (not lava) reached neither on foot nor mounted (`ride`).
static func _lost(root: Region, ride: Dictionary, lava: Dictionary) -> int:
	var terrain: TileMapLayer = root.get_node("Terrain")
	var size := terrain.get_used_rect().end
	var lost := 0
	for y in size.y:
		for x in size.x:
			var c := Vector2i(x, y)
			var d := terrain.get_cell_tile_data(c)
			if d and String(d.get_custom_data("terrain")) in B.WALKABLE and not lava.has(c) and not ride.has(c):
				lost += 1
	return lost
