extends RefCounted
## Visual and walking checks of the chapter 7 map (agent CARTE): the three zones of the Cieux
## Éternels (cieux, nids_geants, arche_du_vent), place by place, at several hours and weathers; the
## join with the Monts from both sides; then, zone by zone (verifier), on the live zone: every key
## place reachable on foot from the way in (and Chloé's own body swept along the way: nothing solid
## blocks it), the islets reached only in flight, no prop floating over a drop or standing on a path,
## every rope of the bridges (Ropes) joining two posts less than 7 m apart.
## No scene is played (the story's flags are set; the zones are entered without their scenes).
## While world.gd ZONES does not list the three zones yet, `entrer` loads them itself.
## godot --path Godot --script res://tools/capture.gd --resolution 1600x900 -- out=<dossier>
##   scenario_file=res://tools/scenarios/vis_cieux.gd titre="Carte des Cieux : lieux, accès, décor"

const SELF := "res://tools/scenarios/vis_cieux.gd"
const PLACES := "res://story/cieux_places.gd"
const ZONES := {
	&"cieux": "res://regions/cieux/cieux.tscn",
	&"nids_geants": "res://regions/cieux/nids_geants.tscn",
	&"arche_du_vent": "res://regions/cieux/arche_du_vent.tscn",
}
const TILE := 48.0
## Chloé's body (actors/player.tscn: a circle of 11 px, a little margin), a dino's or a person's foot
## (px); the bridges' posts.
const PLAYER_RADIUS := 13.0
const BODY_RADIUS := 16.0
const POSTS := ["pieu_corde", "poteau_lianes", "pilier_pont_1", "pilier_pont_2"]
## The ground's layers of cliffs (WorldView.MAT.CLIFF, MAT.COVER_CLIFF).
const CLIFF_LAYERS := [3, 11]
## What a step along a rim costs, against 1 elsewhere (_path).
const RIM_COST := 4
## The lanes tried beside a step's middle line (px).
const LANES := [0.0, 8.0, -8.0, 16.0, -16.0, 22.0, -22.0]
## How a prop's base is measured against the ground (tools/zones/cieux_pieds.gd).
const FEET := "res://tools/zones/cieux_pieds.gd"
## The chapter's flags that keep its scenes quiet (they are not played here) and open its ways.
const FLAGS := ["prologue_done", "tuto_commandes", "sceau_plaines", "havre_arrive", "selle", "monts_ouverts", "monts_arrivee",
	"coeur_4", "sceau_monts", "maia_alliee", "harnais_vol", "cieux_ouverts", "cieux_arrivee", "pont_lianes_vu", "vol_obtenu",
	"quetzal_roi_confiance", "sceau_cieux"]

const STEPS := [
	[0.60, "flags", FLAGS], [0.65, "talk", true], [0.70, "clock", 11.0], [0.75, "weather", &"clear"],
	# 1. The join with the Monts, from the Monts (the Cieux beyond their north edge), then from the Cieux.
	[1.00, "static", [SELF, "entrer", "monts", "DepuisCieux"]], [3.60, "weather", &"clear"], [3.70, "calm", 900.0],
	[3.80, "tp", Vector2(100.5, 6.0)], [3.90, "face", Vector2(0, -1)], [4.00, "camera_distance", 16.0], [6.20, "shot", "a0_monts_vers_cieux"],
	[6.40, "static", [SELF, "entrer", "cieux", "DepuisMonts"]], [7.40, "shot", "a1a_cieux_nom_de_zone"], [9.00, "weather", &"clear"], [9.10, "calm", 900.0],
	[9.20, "camera_distance", 12.0], [9.30, "tp", Vector2(72.5, 82.5)], [9.40, "face", Vector2(0, 1)], [11.40, "shot", "a1_cieux_sortie_monts"],
	[11.50, "static", [SELF, "verifier", "cieux"]],
	# 2. The Cieux, place by place (late morning).
	[11.80, "tp", Vector2(72.5, 76.5)], [11.90, "face", Vector2(0, -1)], [13.90, "shot", "b0_arrivee"],
	[14.00, "tp", Vector2(66.0, 73.0)], [14.10, "face", Vector2(-1, 0)], [16.00, "shot", "b1_premier_pont"],
	[16.10, "tp", Vector2(52.0, 73.0)], [16.20, "face", Vector2(0, -1)], [18.00, "shot", "b2_guet"],
	[18.10, "tp", Vector2(33.0, 69.0)], [18.20, "face", Vector2(-1, 0)], [20.00, "shot", "b3_mer_de_nuages"],
	[20.10, "tp", Vector2(52.0, 51.0)], [20.20, "face", Vector2(0, -1)], [22.00, "shot", "b4_vents"],
	[22.10, "tp", Vector2(46.5, 29.0)], [24.00, "shot", "b5_haut_rempart"],
	[24.10, "tp", Vector2(46.5, 10.0)], [26.00, "shot", "b6_rampe_nids"],
	[26.10, "tp", Vector2(79.0, 51.0)], [28.00, "shot", "b7_fendu"],
	[28.10, "tp", Vector2(89.0, 71.0)], [30.00, "shot", "b8_rhamphos"],
	[30.10, "tp", Vector2(76.0, 22.0)], [32.00, "shot", "b9_belvedere"],
	[32.10, "tp", Vector2(8.0, 79.0)], [34.00, "shot", "b10_ilot_page33"],
	[34.10, "camera_distance", 20.0], [34.20, "tp", Vector2(52.0, 60.0)], [36.20, "shot", "b11_vue_large"], [36.30, "camera_distance", 12.0],
	# 3. Hours and weathers: dawn on the Mer de nuages, the night at the arrival, mist, snow, blizzard.
	[36.50, "clock", 6.5], [36.60, "tp", Vector2(25.0, 66.0)], [36.70, "face", Vector2(0, -1)], [39.00, "shot", "c0_mer_aube"],
	[39.10, "clock", 22.5], [39.20, "tp", Vector2(72.5, 76.5)], [39.30, "face", Vector2(0, -1)], [42.00, "shot", "c1_arrivee_nuit"],
	[42.10, "clock", 11.0], [42.20, "weather", &"mist"], [42.30, "tp", Vector2(52.0, 73.0)], [46.00, "shot", "c2_guet_brume"],
	[46.10, "weather", &"snow"], [50.00, "shot", "c3_guet_neige"],
	[50.10, "weather", &"blizzard"], [54.00, "shot", "c4_guet_blizzard"], [54.10, "weather", &"clear"],
	# (A preview of the map's patch to world_view.gd: the cliffs in grey snowy rock, as in the Monts.)
	[54.15, "static", [SELF, "apercu_falaises", "res://assets/art/ground/falaise_neige.png"]],
	[54.20, "tp", Vector2(72.5, 76.5)], [54.25, "face", Vector2(0, -1)], [56.00, "shot", "c5_arrivee_apercu_patch_falaises"],
	[56.10, "tp", Vector2(46.5, 29.0)], [58.30, "shot", "c6_haut_apercu_patch_falaises"],
	# 4. The nests.
	[58.50, "static", [SELF, "entrer", "nids_geants", "DepuisCieux"]], [59.50, "shot", "d0a_nids_nom_de_zone"], [61.20, "weather", &"clear"], [61.30, "calm", 900.0],
	[61.40, "static", [SELF, "verifier", "nids_geants"]],
	[61.60, "tp", Vector2(34.5, 50.5)], [61.70, "face", Vector2(0, -1)], [63.60, "shot", "d0_nids_entree"],
	[63.70, "tp", Vector2(36.0, 34.0)], [65.60, "shot", "d1_nids"],
	[65.70, "tp", Vector2(23.0, 16.0)], [67.60, "shot", "d2_grand_nid"],
	[67.70, "tp", Vector2(35.0, 8.0)], [67.80, "face", Vector2(1, 0)], [69.60, "shot", "d3_pont_aiguille"],
	[69.70, "tp", Vector2(43.0, 6.0)], [69.80, "face", Vector2(0, -1)], [71.60, "shot", "d4_aiguille"],
	[71.70, "tp", Vector2(59.0, 20.0)], [73.60, "shot", "d5_nid_oublie"],
	# 5. The Arche du Vent.
	[74.00, "static", [SELF, "entrer", "arche_du_vent", "DepuisNids"]], [75.00, "shot", "e0a_arche_nom_de_zone"], [76.70, "weather", &"clear"], [76.80, "calm", 900.0],
	[76.90, "static", [SELF, "verifier", "arche_du_vent"]],
	[77.10, "tp", Vector2(28.0, 40.5)], [77.20, "face", Vector2(0, -1)], [79.10, "shot", "e0_arche_entree"],
	[79.20, "tp", Vector2(28.0, 27.0)], [81.10, "shot", "e1_arche_terrasse"],
	[81.20, "tp", Vector2(28.0, 21.0)], [83.10, "shot", "e2_arche_centre"],
	[83.20, "tp", Vector2(20.0, 9.0)], [83.30, "face", Vector2(0, -1)], [85.10, "shot", "e3_descente_cendre"],
	[85.20, "tp", Vector2(35.0, 18.5)], [85.30, "face", Vector2(0, -1)], [87.10, "shot", "e4_cairn"],
	[87.20, "weather", &"blizzard"], [87.30, "tp", Vector2(28.0, 27.0)], [91.20, "shot", "e5_arche_blizzard"],
	[91.30, "weather", &"clear"], [91.40, "clock", 19.0], [93.50, "shot", "e6_arche_soir"],
	# 6. Nothing floating by the bridges and the rims, at the camera's nearest and farthest (8 and 20 m).
	[93.60, "static", [SELF, "entrer", "cieux", "DepuisMonts"]], [96.10, "weather", &"clear"], [96.20, "calm", 900.0],
	[96.25, "clock", 11.0], [96.30, "camera_distance", 8.0], [96.40, "tp", Vector2(52.0, 61.0)], [96.50, "face", Vector2(0, -1)],
	[98.50, "shot", "f0_pont_zoom_min"], [98.60, "camera_distance", 20.0], [100.80, "shot", "f1_pont_zoom_max"],
	[100.90, "tp", Vector2(63.0, 73.0)], [101.00, "face", Vector2(-1, 0)], [103.00, "shot", "f2_premier_pont_zoom_max"],
	[103.10, "camera_distance", 8.0], [105.10, "shot", "f3_premier_pont_zoom_min"],
	[105.20, "tp", Vector2(85.0, 60.0)], [105.30, "face", Vector2(0, -1)], [107.30, "shot", "f4_long_pont_zoom_min"],
	[107.40, "camera_distance", 20.0], [109.50, "shot", "f5_long_pont_zoom_max"],
	[109.60, "clock", 19.0], [109.70, "tp", Vector2(76.0, 22.0)], [111.80, "shot", "f6_belvedere_soir_zoom_max"],
	[111.90, "tp", Vector2(33.0, 69.0)], [112.00, "face", Vector2(-1, 0)], [114.00, "shot", "f7_rive_mer_soir_zoom_max"],
	[114.10, "camera_distance", 12.0],
	# 7. The joins between zones, seen from each side (no seam, no line between two grounds): the Pitons
	# to the nests (their carved way), the nests to the Arche (the needle, the platform).
	[114.20, "clock", 11.0], [114.30, "tp", Vector2(46.5, 3.0)], [114.40, "face", Vector2(0, -1)], [116.40, "shot", "g0_jonction_cieux_vers_nids"],
	[116.50, "static", [SELF, "entrer", "nids_geants", "DepuisCieux"]], [119.00, "weather", &"clear"], [119.10, "calm", 900.0],
	[119.20, "tp", Vector2(34.5, 57.0)], [119.30, "face", Vector2(0, 1)], [121.30, "shot", "g1_jonction_nids_vers_cieux"],
	[121.40, "tp", Vector2(43.0, 2.5)], [121.50, "face", Vector2(0, -1)], [123.50, "shot", "g2_jonction_nids_vers_arche"],
	[123.60, "static", [SELF, "entrer", "arche_du_vent", "DepuisNids"]], [126.10, "weather", &"clear"], [126.20, "calm", 900.0],
	[126.30, "tp", Vector2(28.0, 42.0)], [126.40, "face", Vector2(0, 1)], [128.40, "shot", "g3_jonction_arche_vers_nids"],
	[128.50, "state", null],
]


## Enters zone `zone` at its spawn `spawn`, without its story scene: through the world's own way when
## world.gd ZONES lists it, else by the same steps as World._enter_zone (the three new zones are
## only in ZONES once the lead has applied the map's patch); the neighbours beyond the edges (the
## Cieux among them) are shown either way.
static func entrer(zone: String, spawn: String) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var world: Node = tree.current_scene
	var listed: Dictionary = (world.get_script() as Script).get_script_constant_map()["ZONES"]
	var all := listed.duplicate()
	all.merge(ZONES)
	var region: Node2D = world.get("region")
	var player: Node2D = world.get("player")
	var companion: Node2D = world.get("companion")
	for actor in [player, companion]:
		actor.get_parent().remove_child(actor)
	var holder: Node2D = world.get("region_holder")
	holder.remove_child(region)
	region.queue_free()
	region = (load(all[StringName(zone)]) as PackedScene).instantiate()
	holder.add_child(region)
	world.set("region", region)
	var game := tree.root.get_node("Game")
	game.set("region_id", StringName(zone))
	var levels: Vector2i = region.get("levels")
	game.set("zone_level", roundi((levels.x + levels.y) / 2.0))
	game.call("set_climate", {"rain": region.get("rain_chance"), "mist": region.get("mist_chance"), "storm": region.get("storm_chance"),
		"sandstorm": region.get("sandstorm_chance"), "snow": region.get("snow_chance"), "blizzard": region.get("blizzard_chance")})
	var entities: Node2D = region.get("entities")
	entities.add_child(player)
	entities.add_child(companion)
	player.set("surface_at", Callable(region, "surface_at"))
	player.set("snow_at", Callable(region, "snow_at"))
	player.set("cold", region.get("cold"))
	player.set("slippery", region.get("slippery"))
	var at: Vector2 = region.call("spawn_point", StringName(spawn))
	player.call("teleport", at)
	companion.call("stand_beside", at)
	(player.get_node("Camera") as Camera2D).call(&"fit_to", region.call("bounds"))
	for exit in region.call("exits"):
		exit.connect("taken", Callable(world, "_on_exit_taken"))
	world.call("_spawn_roamers")
	world.get("_view").call("show_zone", region, player, all)
	var tracker: Variant = world.get("_tracker")
	if tracker:
		tracker.set("zone", StringName(zone))
	world.call("_explore")
	var audio := tree.root.get_node("Audio")
	audio.call("play_music", region.get("music"))
	world.call("_find_sea")
	audio.call("play_ambience", region.get("ambience_id"))
	var zone_name: String = region.get("zone_name")
	world.call("_show_banner", zone_name if zone_name != "" else region.get("display_name"), region.get("display_name") if zone_name != "" else "")
	return "%s (%s)" % [zone, spawn]


## A preview of the map's patch to world_view.gd (CLIFF_TEX of the Cieux, kept even under cover
## layers): the zone's cliffs drawn in `picture` instead of the earth wall, in the live view only (the
## ground's stack of pictures rebuilt with that layer replaced). Nothing is written anywhere.
static func apercu_falaises(picture: String) -> String:
	var view: Node = (Engine.get_main_loop() as SceneTree).current_scene.get("_view")
	var mat: ShaderMaterial = view.get("_ground_mat")
	var stack: Texture2DArray = mat.get_shader_parameter("materials")
	var cliff := (load(picture) as Texture2D).get_image()
	if cliff.is_compressed():
		cliff.decompress()
	cliff.resize(stack.get_width(), stack.get_height(), Image.INTERPOLATE_LANCZOS)
	cliff.convert(Image.FORMAT_RGBA8)
	cliff.generate_mipmaps()
	var images: Array[Image] = []
	for i in stack.get_layers():
		images.append(cliff if i in CLIFF_LAYERS else stack.get_layer_data(i))
	var fresh := Texture2DArray.new()
	fresh.create_from_images(images)
	mat.set_shader_parameter("materials", fresh)
	return "falaises : " + picture.get_file()


## The checks of the live zone `zone`: prints one line per check (PASS / ÉCHEC) and gives back the
## count.
static func verifier(zone: String) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var world: Node = tree.current_scene
	var region: Node2D = world.get("region")
	var player: CharacterBody2D = world.get("player")
	var p: Dictionary = (load(PLACES) as Script).get_script_constant_map()
	var builder: GDScript = load("res://tools/zone_builder.gd")
	var from := _tile(region.call("spawn_point", StringName(_entry_spawn(zone))))
	var reach: Dictionary = builder.call("_reachable", region, from)
	var solid := _solid_tiles(region, world)
	var fails := 0
	var lines: Array[String] = []
	for place: String in _on_foot(zone):
		var target := Vector2i((p[place] as Vector2).floor())
		var path := _path(reach, solid, from, target)
		var ok := not path.is_empty()
		var blocked := _sweep(player, path) if ok else "pas de chemin"
		ok = ok and blocked == ""
		fails += 0 if ok else 1
		lines.append("%s %s : à pied depuis l'entrée%s" % ["PASS" if ok else "ÉCHEC", place, "" if ok else " — " + blocked])
	for islet: Array in p["ILOTS_VOL"]:
		if String(islet[0]) != zone:
			continue
		var c := Vector2i((islet[1] as Vector2).floor())
		var ok: bool = not reach.has(c) and builder.call("is_flat", region, c, 1)
		fails += 0 if ok else 1
		lines.append("%s îlot %s : seulement en vol, aire plate de 3 x 3" % ["PASS" if ok else "ÉCHEC", c])
	for s in _floating(world, region):
		fails += 1
		lines.append("ÉCHEC décor qui flotte : " + s)
	for s in _on_paths(region):
		fails += 1
		lines.append("ÉCHEC décor solide sur un chemin : " + s)
	var ropes := _ropes(world, region)
	fails += ropes.size() - 1
	lines.append_array(ropes)
	for line in lines:
		print("  ", line)
	return "%s : %d vérification(s) en échec" % [zone, fails]


static func _entry_spawn(zone: String) -> String:
	return {"cieux": "DepuisMonts", "nids_geants": "DepuisCieux", "arche_du_vent": "DepuisNids"}[zone]


## The key places of each zone (CieuxPlaces' names) that must be reached on foot.
static func _on_foot(zone: String) -> Array:
	match zone:
		"cieux":
			return ["PITON_ARRIVEE", "PREMIER_PONT", "GUET", "MER_DE_NUAGES", "VENTS", "HAUT", "FENDU", "RHAMPHOS", "BELVEDERE",
				"PAGE_31", "SORTIE_NIDS", "FEU_ARRIVEE"]
		"nids_geants":
			return ["NIDS_ENTREE", "NIDS", "PAGE_32", "GRAND_NID", "ROI", "AIGUILLE", "SORTIE_ARCHE", "FEU_NIDS"]
		_:
			return ["ARCHE_ENTREE", "ARCHE", "MASQUE", "BORD_ROI", "CAIRN", "DESCENTE_CENDRE", "SORTIE_VOLCAN", "FEU_ARCHE"]


static func _tile(px: Vector2) -> Vector2i:
	return Vector2i((px / TILE).floor())


## The tiles whose middle Chloé's body cannot stand on, for something solid nearby (a prop's foot, a
## dino, a person; their outline grown by her own radius): the walk goes round them, as she would.
## The bridges' posts are left out (they stand in the cliff's wall, on the deck's edge): the sweep
## along the deck says whether one is in the way.
static func _solid_tiles(region: Node, world: Node) -> Dictionary:
	var out := {}
	for n in region.get("entities").get_children():
		if not n is PhysicsBody2D or n == world.get("player") or n == world.get("companion") or n is Pickup:
			continue
		if n.has_signal("encountered"):
			continue   # (a wild dino wanders off: Chloé waits, or goes round)
		var half := Vector2(BODY_RADIUS, BODY_RADIUS)
		if n is Prop:
			if String((n as Prop).kind) in POSTS:
				continue
			var solid: Variant = Prop.KINDS.get((n as Prop).kind, {}).get("solid", 0.0)
			if solid is float and solid <= 0.0:
				continue
			half = Vector2(solid, solid) if solid is float else (solid as Vector2) / 2.0
		var foot := Rect2((n as Node2D).position - half, half * 2.0).grow(PLAYER_RADIUS)
		var t0 := _tile(foot.position)
		var t1 := _tile(foot.end)
		for y in range(t0.y, t1.y + 1):
			for x in range(t0.x, t1.x + 1):
				if foot.has_point((Vector2(x, y) + Vector2(0.5, 0.5)) * TILE):
					out[Vector2i(x, y)] = true
	return out


## The tiles from `from` to `to` over the reachable tiles, round the solid ones, keeping off the
## rims (a tile by a cliff costs RIM_COST: one walks there only where the way is narrow, a bridge), or []
## when there is none; when `to` itself is taken (a fire, a nest), the nearest free tile next to it.
static func _path(reach: Dictionary, solid: Dictionary, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var free := func(t: Vector2i) -> bool: return reach.has(t) and (not solid.has(t) or t == from)
	var goal := to
	if not free.call(goal):
		for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(1, 1), Vector2i(-1, 1),
				Vector2i(0, 2), Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, -2)]:
			if free.call(to + d):
				goal = to + d
				break
		if not free.call(goal):
			return out
	var cost := {from: 0}
	var came := {from: from}
	var open: Array[Vector2i] = [from]
	while not open.is_empty():
		var best := 0
		for k in open.size():
			if cost[open[k]] < cost[open[best]]:
				best = k
		var here: Vector2i = open[best]
		open.remove_at(best)
		if here == goal:
			break
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n := here + d
			if not free.call(n):
				continue
			var step := 1 + (RIM_COST - 1 if _rim(reach, n) else 0)
			if not cost.has(n) or cost[here] + step < cost[n]:
				cost[n] = cost[here] + step
				came[n] = here
				if not n in open:
					open.append(n)
	if not came.has(goal):
		return out
	var t := goal
	while t != from:
		out.push_front(t)
		t = came[t]
	out.push_front(from)
	return out


## A reachable tile next to one that is not (a cliff's edge, the void, the zone's border).
static func _rim(reach: Dictionary, t: Vector2i) -> bool:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not reach.has(t + d):
			return true
	return false


## (Chloé walks anywhere across a way, not only through the tiles' middles: each step is tried along
## lanes beside the middle line too, LANES px apart; one free lane is enough.)
static func _sweep(player: CharacterBody2D, path: Array[Vector2i]) -> String:
	var saved := player.global_position
	var result := ""
	for k in path.size() - 1:
		var a := (Vector2(path[k]) + Vector2(0.5, 0.5)) * TILE
		var b := (Vector2(path[k + 1]) + Vector2(0.5, 0.5)) * TILE
		var across := (b - a).normalized().orthogonal()
		var hit: KinematicCollision2D = null
		for lane: float in LANES:
			player.global_position = a + across * lane
			if player.test_move(player.global_transform, Vector2.ZERO):
				continue   # (that lane starts inside something)
			hit = player.move_and_collide(b - a, true)
			if hit == null:
				break
		if hit:
			var what: Object = hit.get_collider()
			result = "bloqué entre %s et %s par %s" % [path[k], path[k + 1], what.get("name") if what else "?"]
			break
	player.global_position = saved
	return result


## Every prop whose drawn base stands above the drawn ground under it by more than 5 cm, across the
## base's width (tools/zones/cieux_pieds.gd: the same measure the zone plans settle their props by),
## posts of the bridges, signs, pickups and the story's things included.
static func _floating(world: Node, region: Node) -> Array[String]:
	var heights: HeightMap = world.get("_view").get("heights")
	var feet: GDScript = load(FEET)
	var tolerance: float = feet.get_script_constant_map()["TOLERANCE"]
	var out: Array[String] = []
	for n in region.get("entities").get_children():
		if not n is Prop:
			continue
		var up: float = feet.call("lift", heights, (n as Prop).kind, (n as Prop).flip, (n as Node2D).position)
		if up > tolerance:
			out.append("%s (%s) %s : sa base à %+.2f m du sol" % [n.name, (n as Prop).kind, ((n as Node2D).position / TILE).snapped(Vector2(0.1, 0.1)), up])
	return out


## The ropes of the bridges (Ropes: the zone's « Cordes »): each one declared joins two posts of the zone
## (POSTS) less than Ropes.MAX_SPAN (7 m) apart, from tie to tie. Its lines: one ÉCHEC per rope that does
## not, then the count (PASS).
static func _ropes(world: Node, region: Node) -> Array[String]:
	var heights: HeightMap = world.get("_view").get("heights")
	var out: Array[String] = []
	var pairs := Ropes.pairs(region)
	for pair: Variant in pairs:
		var ends := Ropes.posts(region, pair)
		var posts_ok := ends.size() == 2 and ends.all(func(n: Variant) -> bool: return n != null and String((n as Prop).kind) in POSTS)
		var span := Ropes.tie_point(heights, ends[0]).distance_to(Ropes.tie_point(heights, ends[1])) if posts_ok else INF
		if not posts_ok or span >= Ropes.MAX_SPAN:
			out.append("ÉCHEC corde %s : %s" % [pair, "un bout n'est pas un poteau de la zone" if not posts_ok else "%.1f m entre ses poteaux" % span])
	out.append("PASS cordes : %d déclarée(s), chacune entre deux poteaux à moins de %d m" % [pairs.size() - out.size(), Ropes.MAX_SPAN])
	return out


## Solid props whose foot circle or box touches a path tile (a trail or a bridge), but the posts.
static func _on_paths(region: Node) -> Array[String]:
	var terrain: TileMapLayer = region.get_node("Terrain")
	var out: Array[String] = []
	for n in region.get("entities").get_children():
		if not n is Prop or n is Pickup or String((n as Prop).kind) in POSTS + ["panneau"]:
			continue
		var solid: Variant = Prop.KINDS.get((n as Prop).kind, {}).get("solid", 0.0)
		var half := Vector2(solid, solid) if solid is float else (solid as Vector2) / 2.0
		if half.x <= 0.0:
			continue
		var pos: Vector2 = (n as Node2D).position
		for corner: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2.ZERO]:
			var d := terrain.get_cell_tile_data(_tile(pos + corner * half))
			if d and String(d.get_custom_data("terrain")) == "path":
				out.append("%s %s" % [n.name, (pos / TILE).snapped(Vector2(0.1, 0.1))])
				break
	return out
