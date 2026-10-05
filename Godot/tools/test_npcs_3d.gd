extends SceneTree
## The people of the Prairie du Grand Crâne in 3D, checked in the real engine (it needs a window to
## render, so not --headless):
##   godot --path Godot --script res://tools/test_npcs_3d.gd -- out=<folder>
## Opens the 3D Prairie (Zone3D builds its people itself, Npcs3D), walks Chloé up to one, shows « E : parler », opens the game's
## dialogue; then, story moment by story moment (the flags), who is there (people and the story's
## dinos), where the remodelled zone's plan puts them, on dry and free ground, seen from around; and
## the screenshots. Prints PASS / FAIL, quits with 1 on any failure.

const ZONE := "res://world3d/zone3d/zone_3d.tscn"
## Loaded at run time, never named: this script is compiled before the autoloads, and naming a class
## that uses one (Dialogue, Game) would compile it too early (as tools/test_world3d.gd does).
const NPCS := "res://world3d/actors/npcs_3d.gd"
const PALETTE := "res://world3d/actors/npc_palette.gd"
const PITCH_DEFAULT := -22.0   # CameraPivot.PITCH_DEFAULT
## Written small at the top left and left there for the whole run (Greg, 04/10: the pictures must
## say what the test is about, and go on saying it shot after shot — not a new line each time).
const CAPTION := "PNJ 3D dans la Prairie — placement, apparence, échelle, approche et dialogue"
## The zone's own banner (ZoneBanner, 3.2 s from the start) gone before the first picture: the
## caption is then the only one at the top left.
const BANNER_GONE_S := 3.8
const SOLID := 1 | 16   # Layers3D.WORLD | Layers3D.WATER
const KNEE_M := 0.4
## Seen from around: lines of sight from so many directions, so far beyond its body, at eye height.
const AROUND := 8
const AROUND_M := 9.0
const AROUND_SEEN := 5      # at least this many of them clear
## The story's moments: the flags set, who must be there, who must not, and a picture.
const MOMENTS := [
	{"what": "nouvelle partie", "flags": [], "there": ["Maia", "GrandVoyageur"], "gone": ["MaiaDefi", "Alpha", "Elise"],
		"view": {"name": "06_pnj_carrefour_maia_voyageur", "at": Vector2(121, 112), "toward": Vector2(108, 100), "pitch": -10.0, "dist": 4.0,
			"shows": ["Maia", "GrandVoyageur"]}},
	{"what": "Crâne ouvert", "flags": [&"crane_ouvert"], "there": ["Maia", "GrandVoyageur", "Alpha"], "gone": ["MaiaDefi"],
		"view": {"name": "07_pnj_parvis_alpha", "at": Vector2(166, 117), "toward": Vector2(178.4, 109), "pitch": -10.0, "dist": 4.0,
			"shows": ["Alpha"]}},
	{"what": "Sceau de la Prairie", "flags": [&"crane_ouvert", &"sceau_plaines"], "there": ["MaiaDefi", "GrandVoyageur"], "gone": ["Maia", "Alpha"]},
	{"what": "arrivée au Havre", "flags": [&"havre_arrive"], "there": ["Maia", "GrandVoyageur", "Elise"], "gone": []},
]
const MOMENT_FLAGS: Array[StringName] = [&"crane_ouvert", &"sceau_plaines", &"maia_defi_1", &"havre_arrive"]

var _out := "user://test_npcs_3d"
var _failed := 0
var _zone: Node
var _player: Node3D
var _pivot: Node3D
var _npcs: Node3D


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://capture_save.json")   # never the player's save
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://capture_save.json"))
	change_scene_to_file(ZONE)
	_run()


func _run() -> void:
	await create_timer(1.5).timeout
	var caption := ShotCaption.show_on(self, CAPTION)
	_zone = current_scene
	if _zone == null or _zone.get("player") == null:
		print("TEST pnj 3D : ÉCHEC (la Prairie 3D ne s'est pas construite)")
		quit(1)
		return
	_player = _zone.get("player")
	_pivot = _player.get("pivot")
	_quiet()
	await _build()
	_placement()
	await create_timer(maxf(BANNER_GONE_S - 1.5, 0.0)).timeout
	await _approach()
	await _dialogue()
	await _moments()
	caption.queue_free()
	print("TEST pnj 3D : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


## No battle while the people are looked at: no hidden dino in the tall grass, the others calm.
func _quiet() -> void:
	var enc: Node = _zone.get("session").get("encounters")
	enc.set_physics_process(false)
	for d in _zone.get("dinos"):
		d.call("calm_down", 9999.0)


## The people of the 2.5D zone are read and put down: the colours come off their own sheets.
func _build() -> void:
	for name in ["chloe", "maia", "elise"]:
		var palette: Object = load(PALETTE).call("of", load("res://assets/art/characters/%s.png" % name))
		print("  couleurs de %s : %s" % [name, palette.call("as_dictionary")])
	_npcs = _zone.get("npcs")   # the zone builds them itself now
	if _npcs == null:           # (without that wiring, the test puts them down itself)
		_npcs = (load(NPCS) as GDScript).new()
		_npcs.name = "Npcs"
		_zone.add_child(_npcs)
		_npcs.call("build", _zone.get("source"), _zone.get("terrain"))
	await _settled(_npcs)
	var people: Array = _npcs.get("people")
	print("  %d personne(s), %d dino(s) de l'histoire : %s" % [people.size(), (_npcs.get("dinos") as Array).size(), _npcs.call("counts")])
	_check("the people of the 2.5D zone are there", people.size() >= 1, "%d" % people.size())
	var maia: Node3D = _npcs.call("person", &"Maia")
	_check("Maïa stands at the crossroads, as in the 2.5D", maia != null, "%s" % [maia])
	if maia == null:
		print("TEST pnj 3D : ÉCHEC (Maïa manque)")
		quit(1)
		return
	_check("…with her name, read off the 2.5D zone", maia.get("display_name") == "Maïa", "%s" % maia.get("display_name"))
	_check("…at her own height (1.50 m, Heights)", absf(float(maia.get("height_m")) - 1.50) < 0.01, "%.2f m" % maia.get("height_m"))
	_check("…her story scene known (event « maia »)", maia.get("event") == &"maia", "%s" % maia.get("event"))
	var voyageur: Node3D = _npcs.call("dino", &"GrandVoyageur")
	_check("the Grand Voyageur (the 2.5D's DinoNpc) stands at the crossroads too, a brachiosaurus", voyageur != null and voyageur.get("species").get("id") == &"brachiosaurus",
		"%s" % [voyageur])
	if voyageur:
		_check("…bigger than a wild one (its size 1.6)", absf(float(voyageur.get("share")) - 1.6) < 0.01, "%.1f m de long, %.1f m de haut" % [voyageur.get("length_m"), voyageur.get("height_m")])
	await process_frame


## Everyone stands on the ground (not floating, not sunk), where the zone puts them: the plan's place
## in the remodelled Prairie (its group of scenes moved as one), else the 2.5D's.
func _placement() -> void:
	var terrain: Object = _zone.get("terrain")
	var worst := 0.0
	for npc: Node3D in _npcs.call("everyone"):
		var at := npc.global_position
		worst = maxf(worst, absf(at.y - float(terrain.call("height_at", at.x, at.z))))
	_check("everyone stands on the ground (no floating, no sinking)", worst < 0.05, "écart max %.3f m" % worst)
	var maia: Node3D = _npcs.call("person", &"Maia")
	var source: Object = _zone.get("source")
	var expected: Vector3 = source.call("to_3d", Vector2(62.6, 44.4) * 48.0)   # her tile in the 2.5D
	var where := "where the 2.5D puts her (× the zone's scale)"
	if terrain.call("is_remodelled"):
		var place: Array = (load(NPCS) as GDScript).call("places_of", &"plaines")["Maia"]["at"]
		expected = Vector3(float(place[0]), 0.0, float(place[1]))
		where = "where the remodelled zone's plan puts her (the crossroads moved with its group)"
	_check("…" + where, Vector2(maia.global_position.x - expected.x, maia.global_position.z - expected.z).length() < 0.2,
		"%s contre %s" % [maia.global_position, expected])
	var spots: Dictionary = _npcs.get("spots")
	for who: String in spots:
		var s: Dictionary = spots[who]
		print("MESURE  %s : %s, %.1f m de sa place du 2,5D" % [who, s["why"], s["moved_m"]])
	var facing: Vector3 = maia.get("_facing")
	_check("…facing the way the 2.5D does (« left » = −X)", facing.x < -0.9, "%s" % facing)


## Chloé comes up to her: from afar, then close enough for « E : parler ».
func _approach() -> void:
	var maia: Node3D = _npcs.call("person", &"Maia")
	await _stand_near(maia, 9.0, 32.0)
	await _shot("01_pnj_vus_de_loin")
	_check("too far to talk to her", _player.call("nearest_interactable") == null, "%s" % [_player.call("nearest_interactable")])
	await _stand_near(maia, 1.15, 42.0)
	var talk: Node3D = maia.get_node("Talk")
	_check("close by, she is the one Chloé would use", _player.call("nearest_interactable") == talk,
		"%s" % [_player.call("nearest_interactable")])
	_check("… « E : parler » shows over her head", (talk.get("_hint") as Label3D).visible,
		"%s" % (talk.get("_hint") as Label3D).text)
	await _shot("02_pnj_invite_parler")
	_pivot.call("set_view", 150.0, -4.0, 2.4)   # her face, from the far side
	_pivot.call("snap")
	await create_timer(0.8).timeout
	await _shot("03_pnj_style_et_couleurs")
	await _stand_near(maia, 1.15, 42.0)


## Stands Chloé `back` metres south of `npc`, facing them, the camera turned `orbit` degrees aside
## so neither of them hides the other.
func _stand_near(npc: Node3D, back: float, orbit: float) -> void:
	_zone.call("place_at", npc.global_position + Vector3(0.0, 0.0, back), 180.0)
	_pivot.call("set_view", orbit, -11.0, clampf(back + 2.2, 3.2, 11.0))
	_pivot.call("snap")
	await create_timer(1.2).timeout


## E opens the game's own dialogue box, with her own lines, and closes it again.
func _dialogue() -> void:
	var dialogue := root.get_node("Dialogue")
	_press(&"interact")
	await create_timer(0.8).timeout
	_check("E opens the game's dialogue", dialogue.get("active") and _player.get("busy"),
		"active %s, occupée %s" % [dialogue.get("active"), _player.get("busy")])
	await _shot("04_pnj_dialogue_du_jeu")
	var presses := 0
	while dialogue.get("active") and presses < 14:
		_press(&"interact")
		presses += 1
		await create_timer(0.5).timeout
	await create_timer(0.4).timeout
	_check("…it closes, and Chloé can move again", not dialogue.get("active") and not _player.get("busy"),
		"%d appui(s)" % presses)
	_check("…her lines were Maïa's own (several steps)", presses >= 3, "%d appui(s)" % presses)
	_check("…and the story flag she sets is set (met_maia)", root.get_node("Game").call("flag", &"met_maia"), "")
	var maia: Node3D = _npcs.call("person", &"Maia")
	var to_chloe: Vector3 = (_player.global_position - maia.global_position).slide(Vector3.UP).normalized()
	var looks: Vector3 = (maia.get_node("Model") as Node3D).global_basis.z.slide(Vector3.UP).normalized()
	_check("…she turned to Chloé to talk to her", looks.dot(to_chloe) > 0.8, "%.2f" % looks.dot(to_chloe))


## The story says who is there (show_flag / hide_flag): at each of its moments, the people and the
## story's dinos are put down again — those of the moment there, the others not; each one where the
## zone puts them, on dry ground with nothing solid in them, seen from around; a picture or two.
func _moments() -> void:
	var game := root.get_node("Game")
	(_npcs as Node3D).visible = false   # (the zone's own, of the new game: out of the pictures)
	for moment: Dictionary in MOMENTS:
		for f in MOMENT_FLAGS:
			game.call("set_flag", f, f in moment["flags"])
		var again: Node3D = (load(NPCS) as GDScript).new()
		again.name = "NpcsAgain"
		_zone.add_child(again)
		again.call("build", _zone.get("source"), _zone.get("terrain"))
		await _settled(again)
		var here: Array[String] = []
		for actor: Node3D in again.call("everyone"):
			here.append(String(actor.name))
		var wrong: Array[String] = []
		for who: String in moment["there"]:
			if not who in here:
				wrong.append("%s manque" % who)
		for who: String in moment["gone"]:
			if who in here:
				wrong.append("%s est là" % who)
		_check("%s : the story's people are there, the others not (%s)" % [moment["what"], ", ".join(moment["there"])], wrong.is_empty(),
			"%s ; présents %s" % [wrong, here])
		var bad: Array[String] = []
		for actor: Node3D in again.call("everyone"):
			var trouble := _trouble(again, actor)
			if trouble != "":
				bad.append("%s %s" % [actor.name, trouble])
		_check("…each on dry, free ground where the zone puts them, seen from around", bad.is_empty(), "%s" % [bad])
		if moment.has("view"):
			await _view(again, moment["view"])
		elif String(moment["what"]) == "arrivée au Havre":
			var elise: Node3D = again.call("person", &"Elise")
			if elise:
				_check("…Élise at her own height (1.65 m)", absf(float(elise.get("height_m")) - 1.65) < 0.01, "%.2f m" % elise.get("height_m"))
				await _stand_near(elise, 2.6, 46.0)
				await _shot("05_pnj_elise_selon_drapeau")
		again.queue_free()
		await process_frame
	for f in MOMENT_FLAGS:
		game.call("set_flag", f, false)
	(_npcs as Node3D).visible = true


## What is wrong with where `actor` stands ("" if nothing): off the zone's place for them, off the
## ground, in the water, something solid in them, or hidden from most sides.
func _trouble(npcs: Node3D, actor: Node3D) -> String:
	var terrain: Object = _zone.get("terrain")
	var at := actor.global_position
	var spot: Dictionary = (npcs.get("spots") as Dictionary).get(String(actor.name), {})
	var place: Vector3 = spot.get("at", at)
	if Vector2(at.x - place.x, at.z - place.z).length() > 0.2:
		return "pas à sa place (%.1f, %.1f) contre (%.1f, %.1f)" % [at.x, at.z, place.x, place.z]
	var ground := float(terrain.call("height_at", at.x, at.z))
	if absf(at.y - ground) > 0.05:
		return "pas sur le sol (%.2f m d'écart)" % (at.y - ground)
	if float(terrain.call("water_depth_at", at.x, at.z)) > 0.0:
		return "dans l'eau"
	var space := (_zone as Node3D).get_world_3d().direct_space_state
	var tall := maxf(float(actor.get("height_m")), 1.5)
	var params := PhysicsShapeQueryParameters3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = float(actor.get("radius"))
	cylinder.height = tall - KNEE_M
	params.shape = cylinder
	params.collision_mask = SOLID
	var skip := _ground_rid()
	if skip.is_valid():
		params.exclude = [skip]
	params.transform = Transform3D(Basis.IDENTITY, Vector3(at.x, ground + (KNEE_M + tall) * 0.5, at.z))
	var hits := space.intersect_shape(params, 1)
	if not hits.is_empty():
		return "dans %s" % hits[0]["collider"]
	var seen := _seen_from_around(actor)
	print("MESURE  %s en (%.1f, %.1f), sol %.2f m, vu de %d côté(s) sur %d" % [actor.name, at.x, at.z, ground, seen, AROUND])
	if seen < AROUND_SEEN:
		return "caché (vu de %d côté(s) sur %d)" % [seen, AROUND]
	return ""


## From how many of AROUND directions, AROUND_M beyond its body and at eye height there, nothing of
## the world stands between an onlooker and its chest.
func _seen_from_around(actor: Node3D) -> int:
	var terrain: Object = _zone.get("terrain")
	var space := (_zone as Node3D).get_world_3d().direct_space_state
	var chest := actor.global_position + Vector3.UP * float(actor.get("height_m")) * 0.6
	var reach := float(actor.get("radius")) + AROUND_M
	var seen := 0
	for k in AROUND:
		var p := Vector2(actor.global_position.x, actor.global_position.z) + Vector2.from_angle(TAU * k / AROUND) * reach
		var eye := Vector3(p.x, float(terrain.call("height_at", p.x, p.y)) + 1.5, p.y)
		var ray := PhysicsRayQueryParameters3D.create(eye, chest, SOLID)
		if space.intersect_ray(ray).is_empty():
			seen += 1
	return seen


## A view of a moment: Chloé at `at` looking `toward`, the camera behind her; each one it `shows` in
## the picture and not hidden from the camera.
func _view(npcs: Node3D, v: Dictionary) -> void:
	var who: Array = v["shows"]
	var terrain: Object = _zone.get("terrain")
	var at: Vector2 = v["at"]
	var look: Vector2 = ((v["toward"] as Vector2) - at).normalized()
	var yaw := rad_to_deg(atan2(-look.x, -look.y))
	_player.call("place_at", Vector3(at.x, float(terrain.call("height_at", at.x, at.y)) + 0.05, at.y), deg_to_rad(yaw + 180.0))
	_pivot.call("set_view", yaw, v["pitch"], v["dist"])
	_pivot.call("snap")
	await create_timer(1.4).timeout
	await _shot(v["name"])
	var camera: Camera3D = _pivot.get("camera")
	var space := (_zone as Node3D).get_world_3d().direct_space_state
	var screen := root.get_viewport().get_visible_rect()
	var missing: Array[String] = []
	for name: String in who:
		var actor: Node3D = npcs.call("person", StringName(name))
		if actor == null:
			actor = npcs.call("dino", StringName(name))
		if actor == null:
			missing.append("%s absent" % name)
			continue
		var chest := actor.global_position + Vector3.UP * float(actor.get("height_m")) * 0.6
		var on_screen := camera.is_position_in_frustum(chest) and screen.has_point(camera.unproject_position(chest))
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position, chest, SOLID))
		if not on_screen or not hit.is_empty():
			missing.append("%s %s" % [name, "hors du cadre" if not on_screen else "caché par %s" % hit["collider"]])
	_check("…in the picture %s: %s" % [v["name"], ", ".join(who)], missing.is_empty(), "%s" % [missing])
	print("IMAGE  %s" % ProjectSettings.globalize_path(_out.path_join("%s.png" % v["name"])))


## Waits for Npcs3D to have checked everyone's place (its `settled`), 5 s at most.
func _settled(npcs: Node) -> void:
	var t0 := Time.get_ticks_msec()
	while not npcs.get("is_settled") and Time.get_ticks_msec() - t0 < 5000:
		await process_frame
	_check("%s : everyone's place checked once the zone's bodies are in" % npcs.name, npcs.get("is_settled"), "")


## The ground's own collision (left out of the queries: its slopes are the relief's).
func _ground_rid() -> RID:
	var terrain: Object = _zone.get("terrain")
	var body: Object = terrain.get("body")
	if body:
		return body.call("get_rid")
	var holder: Object = terrain.get("ground3d")
	var t3d: Object = holder.get("terrain") if holder else null
	var col: Object = t3d.get("collision") if t3d else null
	if col and col.has_method("get_rid"):
		return col.call("get_rid")
	return RID()


func _check(what: String, ok: bool, detail: String) -> void:
	print("%s  %s  (%s)" % ["PASS" if ok else "FAIL", what, detail])
	if not ok:
		_failed += 1


func _shot(name: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))


func _press(action: StringName) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await create_timer(0.05).timeout
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
