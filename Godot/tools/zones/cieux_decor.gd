extends RefCounted
## Les Cieux Éternels (chapter 7): the decor shared by the plans of the three zones (tools/zones/
## cieux.gd, nids_geants.gd, arche_du_vent.gd): the scattered rocks and pines of the pitons, the posts
## of the liana bridges, the needles and the puffs of cloud standing in the sea of clouds, the fires,
## the pages, the amber pebbles and the finds of the places reached only in flight.
## Pictures: the contract's names, a stand-in of the same family while one is not drawn (_kind).

const B := preload("res://tools/zone_builder.gd")
const C := preload("res://tools/zones/cieux_canvas.gd")
const F := preload("res://tools/zones/cieux_pieds.gd")
const PICKUP := "res://world/pickup.gd"
const NOOK_FIND := "res://world/nook_find.gd"
const STORY_PROP := "res://world/story_prop.gd"
## Just south of a trail or a kept-clear place (the camera looks north, 40° down: anything taller
## than Chloé there would hide them): low things only, over this many rows.
const VIEW_SHADOW := 5
## What stands on the pitons (see scatter): [kind, chance per tile, stand-in ("" = nothing)]; the
## first row that wins the roll is placed. Low down: rocks, frosted bushes, stones; high up, fewer
## bushes, more bare rock and wind-bent pines.
const PITONS := [
	["rocher_neige", 0.009, ""], ["rochers_cieux", 0.006, "rocher_neige"], ["pin_tordu", 0.006, ""], ["buisson_givre", 0.016, ""],
	["cailloux", 0.012, ""], ["piton_bas", 0.003, "rocher_neige"],
]
const SUMMITS := [
	["rocher_neige", 0.009, ""], ["rochers_cieux", 0.006, "rocher_neige"], ["pin_tordu", 0.008, ""], ["cailloux", 0.012, ""],
	["buisson_givre", 0.006, ""], ["piton_bas", 0.003, "rocher_neige"],
]
const LOW := [["cailloux", 0.016, ""], ["buisson_givre", 0.008, ""]]
## A piton's height (m) from which its plants are those of the summits.
const SUMMIT_FROM := 14.0
## The posts of the liana bridges: their pictures (at the ends, along), how far apart along a bridge
## (tiles), how far off its middle line (tiles: on the deck's edge, by the cliff).
const POST_END := ["pilier_pont_1", "poteau_lianes", "pieu_corde"]
const POST := ["pilier_pont_2", "poteau_lianes", "pieu_corde"]
const POST_EVERY := 3.0
const POST_OFF := 0.88
## (Nearer the middle, two posts face to face would leave Chloé less than her width between them.)
const POST_MIN := 0.42
const POST_STEP := 0.04
## In the sea of clouds: needles of rock (tall: never where they would hide a piton north of them),
## their foot sunk in the clouds (their Prop.KINDS foot: no stand-in with a ground drawn under it,
## that would stand ON the clouds), puffs of cloud (low: anywhere).
const NEEDLE := ["piton_haut", "aiguille_rocheuse"]
const PUFF := "nuage_bas_%d"   # four pictures (nuage_bas_1..4), one per spot
## A needle hides nothing farther than this (tiles) north of it.
const NEEDLE_SHADOW := 9
## The wind flags on their cairns that mark where one lands well (from the air, the landing areas
## read at a glance); where they stand from an area's middle (tiles), tried in turn.
const FLAGS := [["drapeau_vent_1"], ["drapeau_vent_2"]]
const FLAG_SPOTS: Array[Vector2] = [Vector2(2.6, -2.2), Vector2(-2.6, -2.2), Vector2(3.0, 0.4), Vector2(-3.0, 0.4)]


## The kind of `wanted`, or the first of its stand-ins that exists ("" when none does).
static func kind(wanted: Array) -> String:
	for k: String in wanted:
		if k != "" and Prop.KINDS.has(k):
			return k
	return ""


## A prop of `wanted` (or its stand-in) at tile point `t`; null when none exists.
static func put(entities: Node2D, wanted: Array, t: Vector2, flip := false, script: Script = null) -> Node2D:
	var k := kind(wanted)
	if k == "":
		return null
	return B.prop(entities, k, B.cell(t.x, t.y), flip, script)


static func _kept_clear(keep: Array, p: Vector2) -> bool:
	return keep.any(func(r: Rect2) -> bool: return r.has_point(p))


## Rocks, pines and bushes on the pitons' open ground (not on a path or by it, not on a step, not
## in `keep` rects), by height; low things only just south of the trails and of `keep`.
static func scatter(c: C, entities: Node2D, rng: RandomNumberGenerator, keep: Array, density := 1.0) -> void:
	var paths := c.distance_to(func(x: int, y: int) -> bool: return c.ground_at(x, y) == "path")
	for y in c.h:
		for x in c.w:
			if c.is_void(x, y) or c.ground_at(x, y) != "grass" or paths[y * c.w + x] <= 1 or c.fields[y * c.w + x] == 1:
				continue
			var middle := Vector2(x + 0.5, y + 0.5)
			if _kept_clear(keep, middle) or not _steady(c, x, y) or _by_void(c, x, y):
				continue
			var table: Array = SUMMITS if c.height_at(x, y) >= SUMMIT_FROM else PITONS
			if _in_view(c, keep, x, y):
				table = LOW
			for row: Array in table:
				if rng.randf() < float(row[1]) * density:
					put(entities, [row[0], row[2]], Vector2(x + rng.randf_range(0.25, 0.75), y + rng.randf_range(0.35, 0.85)), rng.randf() < 0.5)
					break


## Tile (x, y) is level with all its neighbours (nothing on a cliff's edge).
static func _steady(c: C, x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if absf(c.height_at(x + dx, y + dy) - c.height_at(x, y)) > 0.3:
				return false
	return true


## The void within two tiles: a piton's rim stays bare (its silhouette against the clouds).
static func _by_void(c: C, x: int, y: int) -> bool:
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			if c.is_void(x + dx, y + dy):
				return true
	return false


## A trail or a kept-clear place just north of tile (x, y): it must stay in sight.
static func _in_view(c: C, keep: Array, x: int, y: int) -> bool:
	for k in range(1, VIEW_SHADOW + 1):
		for dx in range(-2, 3):
			if c.ground_at(x + dx, y - k) == "path" or _kept_clear(keep, Vector2(x + dx + 0.5, y - k + 0.5)):
				return true
	return false


## The posts of a liana bridge along `pts`: a pair at each end of its deck, then a pair every
## POST_EVERY tiles, on the deck's edges over the void (in the cliff's wall: never in the way).
## Each post stands as far out on the deck as the drawn deck holds it (`hm`: the zone's HeightMap;
## the drawn deck is narrower than its two tiles: the ground's heights are sampled every half metre,
## so its flat top is about a metre wide and its sides already slope down to the clouds, where a post
## would hang in the air, cieux_pieds.gd), never nearer the middle than POST_MIN.
## Returns the ropes along the bridge: [post, next post] on the same side, next to each other (a
## side's rope stops where a post is missing; see ropes()).
static func bridge_posts(c: C, hm: HeightMap, entities: Node2D, pts: Array) -> Array:
	var out: Array = []
	var total := 0.0
	for k in pts.size() - 1:
		total += (pts[k] as Vector2).distance_to(pts[k + 1])
	# Where the deck is (the middle line over bridge tiles): its first and last point along it.
	var first := -1.0
	var last := -1.0
	var s := 0.0
	while s <= total:
		var p: Vector2 = _along(pts, s)[0]
		if c.bridges[c.at(floori(p.x), floori(p.y))] == 1:
			first = s if first < 0.0 else first
			last = s
		s += 0.25
	if first < 0.0:
		return out
	var stops: Array[float] = []
	s = first + 0.3
	while s < last - 1.0:
		stops.append(s)
		s += POST_EVERY
	stops.append(last - 0.3)
	var previous := {-1.0: null, 1.0: null}   # each side's last post (null: none at the stop before)
	for k in stops.size():
		var at := _along(pts, stops[k])
		var picture: Array = POST_END if k == 0 or k == stops.size() - 1 else POST
		var post_kind := kind(picture)
		for sign_: float in [-1.0, 1.0]:
			var side: Vector2 = (at[1] as Vector2) * sign_
			var edge: Vector2 = (at[0] as Vector2) + side * POST_OFF
			var beyond: Vector2 = edge + side * 0.6
			var post: Node2D = null
			# On the deck, by its edge over the void (where the deck meets a piton, no post across the way).
			if post_kind != "" and c.bridges[c.at(floori(edge.x), floori(edge.y))] == 1 and c.is_void(floori(beyond.x), floori(beyond.y)):
				post = _post(hm, entities, post_kind, at[0], side)
			if post and previous[sign_]:
				out.append([previous[sign_], post])
			previous[sign_] = post
	return out


## One post of `kind` beside the deck's middle line at `middle`, on the `side` (unit vector): as far
## out as it holds (cieux_pieds.gd), its picture turned so that its foot leans towards the middle; none
## (null) when it holds nowhere between POST_OFF and POST_MIN.
static func _post(hm: HeightMap, entities: Node2D, kind: String, middle: Vector2, side: Vector2) -> Node2D:
	var off := POST_OFF
	while off >= POST_MIN - 0.001:
		var t := middle + side * off
		for flip: bool in [side.x + side.y < 0.0, side.x + side.y >= 0.0]:
			if F.lift(hm, kind, flip, t * B.TILE) <= F.TOLERANCE:
				return put(entities, [kind], t, flip)
		off -= POST_STEP
	return null


## The ropes of the liana bridges (the hand rail from post to post, drawn by the view: world/view3d/
## ropes.gd, Ropes), declared in zone `root`: a node « Cordes » whose metadata « paires » lists the posts
## to join by their names in Entities, [["PilierPont1", "PilierPont3"], …]. `pairs`: [post, post]
## (bridge_posts); a post removed since (settle_all) takes its ropes with it. Added last: built again,
## the scene only gains this node.
static func ropes(root: Region, pairs: Array) -> void:
	var names: Array = []
	for pair: Array in pairs:
		if is_instance_valid(pair[0]) and is_instance_valid(pair[1]):
			names.append([String((pair[0] as Node).name), String((pair[1] as Node).name)])
	if names.is_empty():
		return
	var holder := Node.new()
	holder.name = Ropes.NODE
	holder.set_meta(Ropes.META, names)
	root.add_child(holder)


## The point `s` tiles along polyline `pts`, and the unit vector across it.
static func _along(pts: Array, s: float) -> Array:
	var run := 0.0
	for k in pts.size() - 1:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var span := a.distance_to(b)
		if s <= run + span or k == pts.size() - 2:
			var dir := (b - a).normalized()
			return [a + dir * clampf(s - run, 0.0, span), Vector2(-dir.y, dir.x)]
		run += span
	return [pts[0], Vector2.RIGHT]


## Needles of rock and puffs of cloud in the sea of clouds: `needles` needles (never just south of
## a piton they would hide), `puffs` puffs; both away from the pitons' feet.
static func sea_decor(c: C, entities: Node2D, rng: RandomNumberGenerator, needles: int, puffs: int) -> void:
	var land := c.distance_to(func(x: int, y: int) -> bool: return not c.is_void(x, y))
	var tries := 0
	var placed := 0
	while placed < needles and tries < needles * 200:
		tries += 1
		var x := rng.randi_range(3, c.w - 4)
		var y := rng.randi_range(3, c.h - 4)
		if land[y * c.w + x] < 3 or _land_north(c, x, y):
			continue
		if put(entities, NEEDLE, Vector2(x + 0.5, y + 0.6), rng.randf() < 0.5):
			placed += 1
	if not Prop.KINDS.has(PUFF % 1):
		return
	placed = 0
	tries = 0
	while placed < puffs and tries < puffs * 200:
		tries += 1
		var x := rng.randi_range(2, c.w - 3)
		var y := rng.randi_range(2, c.h - 3)
		if land[y * c.w + x] < 2:
			continue
		put(entities, [PUFF % (1 + (x + y) % 4)], Vector2(x + rng.randf(), y + rng.randf()), rng.randf() < 0.5)
		placed += 1


## Ground above the void within NEEDLE_SHADOW tiles north of tile (x, y) (a tall thing would hide it).
static func _land_north(c: C, x: int, y: int) -> bool:
	for k in range(0, NEEDLE_SHADOW + 1):
		for dx in range(-3, 4):
			if c.inside(x + dx, y - k) and not c.is_void(x + dx, y - k):
				return true
	return false


## A wind flag by each landing area of `areas` (tiles): on level open ground off the trails, at the
## first of FLAG_SPOTS that has some (the flags in turn).
static func landing_flags(c: C, entities: Node2D, areas: Array) -> void:
	for i in areas.size():
		for off: Vector2 in FLAG_SPOTS:
			var t: Vector2 = areas[i] + off
			var x := floori(t.x)
			var y := floori(t.y)
			if c.is_void(x, y) or c.ground_at(x, y) != "grass" or c.fields[c.at(x, y)] == 1 or _by_void(c, x, y) or not _steady(c, x, y):
				continue
			put(entities, FLAGS[i % FLAGS.size()], t, off.x < 0.0)
			break


## A campfire to rest by (see Rest) at the nearest level spot to `t`, the scenery around it cleared.
static func fire(root: Region, entities: Node2D, t: Vector2) -> void:
	var at := B.flat_spot(root, t, 1)
	for n in entities.get_children():
		if n.get_script() == Prop and (n as Node2D).position.distance_to(at) < 2.0 * B.TILE:
			n.free()
	B.prop(entities, "feu_camp", at)


## Hélène's page `n` at tile `t` (taken_flag found_journal_<n>, its lines page_<n>).
static func page(entities: Node2D, n: int, t: Vector2) -> Node2D:
	var p: Node2D = B.prop(entities, "ambre", B.cell(t.x, t.y), false, load(PICKUP))
	p.name = "Page%d" % n
	p.taken_flag = StringName("found_journal_%d" % n)
	p.dialogue_id = StringName("page_%d" % n)
	return p


## Amber pebbles lying in sight at `tiles` (places only the Vol reaches: ZoneBuilder.hide_pebbles
## only hides them where one walks), numbered on from the zone's count; root.pebbles grows.
static func pebbles_in_sight(root: Region, entities: Node2D, tiles: Array) -> void:
	for t: Vector2 in tiles:
		var p: Pickup = B.prop(entities, "galet", B.cell(t.x, t.y), false, load(PICKUP))
		p.name = "Galet%02d" % root.pebbles
		p.taken_flag = StringName("galet_%s_%02d" % [root.region_id, root.pebbles])
		root.pebbles += 1


## Something found in a place only the Vol reaches: `item` given with `line` (NookFind: no line of
## DialogueDB needed), its picture `wanted` (or a stand-in), flag `flag`.
static func find(entities: Node2D, wanted: Array, t: Vector2, item: String, line: String, flag: StringName, node_name: String) -> Node2D:
	var f: Node2D = put(entities, wanted, t, false, load(NOOK_FIND))
	if f == null:
		return null
	f.name = node_name
	f.item_id = item
	f.line = line
	f.taken_flag = flag
	return f


## Every solid prop whose foot stands on a path or a bridge (it would block the way): their names
## and tiles, for the plans' checks.
static func on_paths(root: Region) -> Array[String]:
	var terrain: TileMapLayer = root.get_node("Terrain")
	var out: Array[String] = []
	for n in root.get_node("Entities").get_children():
		if not n is Prop or n is Pickup:
			continue
		var def: Dictionary = Prop.KINDS.get((n as Prop).kind, {})
		var solid: Variant = def.get("solid", 0.0)
		if (solid is float and solid <= 0.0) or (n as Prop).kind in POST + POST_END:
			continue
		var tile := Vector2i(((n as Node2D).position / B.TILE).floor())
		var d := terrain.get_cell_tile_data(tile)
		if d and String(d.get_custom_data("terrain")) == "path":
			out.append("%s %s" % [n.name, tile])
	return out
