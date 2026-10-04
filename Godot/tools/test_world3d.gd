extends SceneTree
## Phases 1 to 3 of docs/migration-3d.md, checked in the real engine (it needs a window to render,
## so not --headless):
##   godot --path Godot --script res://tools/test_world3d.gd -- out=<folder> [only=1|2|3|4]
## `only=`: just that phase (test what a change touches, not everything: the whole run is for a big
## change). Phase 1: Chloé's body and the camera; 2: jump, sign, her animations; 3: the dinos;
## 4: the Prairie in 3D (its own scene, only with only=4).
## Prints PASS / FAIL for each check, saves screenshots, quits with 1 on any failure.
## (Game classes are used through the nodes only: this script is compiled before the autoloads.)

const DEMO := "res://world3d/demo/demo_3d.tscn"
const ZONE := "res://world3d/zone3d/zone_3d.tscn"   # phase 4: the Prairie du Grand Crâne in 3D
const WALK_SPEED := 1.6            # Player3D.WALK (m/s)
const RUN_SPEED := 165.0 / 48.0 * 1.45   # Player.SPEED × Player.RUN_SPEED (m/s): the 2.5D run

var _out := "user://test_world3d"
var _failed := 0
var _demo: Node
var _player: Node3D
var _pivot: Node3D
var _only := 0   # 0: every phase


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("only="):
			_only = int(arg.substr(5))
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://capture_save.json")   # never the player's save
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://capture_save.json"))   # a new game each time
	change_scene_to_file(ZONE if _only in [4, 5] else DEMO)
	_run()


func _run() -> void:
	await create_timer(1.2).timeout
	_demo = current_scene
	_player = _demo.get("player")
	_pivot = _player.get("pivot")
	if _only in [0, 1]:
		await _phase1()
	if _only in [0, 2]:
		await _phase2()
	if _only == 5:   # (the Prairie too)
		await _phase5()
	if _only == 4:   # (its own scene: only with only=4)
		await _phase4()
	if _only in [0, 3]:
		await _phase3()
	print("TEST world3d%s: %s (%d échec(s))" % ["" if _only == 0 else " (phase %d)" % _only, "OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


## Phase 1: Chloé lands on the ground; walks away from the camera at her walking speed; walks "up"
## again after the camera turned a quarter, so another way; runs 1.45× faster; climbs low steps
## and the gentle ramp onto the terrace, not the steep slope; the camera comes in against the wall
## instead of going through it (and she fades); the zoom reaches the distance asked for.
func _phase1() -> void:
	_check("lands on the ground", _player.is_on_floor() and absf(_player.global_position.y) < 0.05,
		"y = %.3f, on floor %s" % [_player.global_position.y, _player.is_on_floor()])
	await _shot("00_depart")

	var walked := await _walk(&"start", 0.0, 1.0)
	_check("walks away from the camera", walked.normalized().dot(Vector3.FORWARD) > 0.97, "dir %s" % walked.normalized())
	var expected := WALK_SPEED * 1.0
	_check("at a child's walking pace", absf(walked.length() - expected) < 0.2, "%.2f m in 1 s (≈ %.2f)" % [walked.length(), expected])

	var turned := await _walk(&"start", 90.0, 1.0)
	_check("up follows the camera", turned.normalized().dot(Vector3.LEFT) > 0.97, "dir %s" % turned.normalized())

	var ran := await _walk(&"start", 0.0, 1.0, true)
	var run_expected := RUN_SPEED * 1.0
	_check("runs at the 2.5D's running speed (less the start)", absf(ran.length() - run_expected) < 0.6, "%.2f m in 1 s (≈ %.2f)" % [ran.length(), run_expected])

	var top := await _highest(&"before_steps", 3.6)
	_check("climbs low steps (15 cm each)", top > 0.55, "highest %.2f m" % top)
	await _walk(&"before_ramp", NAN, 4.8)
	_check("walks up the gentle ramp onto the terrace", absf(_player.global_position.y - 1.2) < 0.1 and _player.is_on_floor(),
		"y = %.2f" % _player.global_position.y)
	await _shot("01_terrasse")
	top = await _highest(&"before_steep", 2.5)
	_check("cannot climb the steep slope", top < 0.6, "highest %.2f m" % top)

	_demo.call("place", &"by_wall")
	await create_timer(1.0).timeout
	var arm: SpringArm3D = _pivot.get("arm")
	var cam: Camera3D = _pivot.get("camera")
	_check("the camera comes in against the wall", arm.get_hit_length() < 2.0, "arm %.2f m" % arm.get_hit_length())
	_check("…and stays on her side of it", cam.global_position.z > -17.5, "camera z %.2f" % cam.global_position.z)
	_check("she fades out with the camera that close", float(_player.get("_fade")) > 0.5, "fade %.2f" % float(_player.get("_fade")))
	await _shot("02_mur")

	_demo.call("place", &"start")
	_pivot.call("set_distance", 10.0, false)
	await create_timer(1.5).timeout
	_check("zooms out to the distance asked for", absf(arm.get_hit_length() - 10.0) < 0.3, "arm %.2f m" % arm.get_hit_length())
	_check("…and she is back in full", float(_player.get("_fade")) < 0.01, "fade %.2f" % float(_player.get("_fade")))
	_pivot.call("set_view", 35.0, -35.0)
	await create_timer(0.4).timeout
	await _shot("03_zoom_orbite")
	_pivot.call("set_distance", 4.5, false)


## Phase 2: the jump (held, tapped, onto a low crate, not onto a high one), the sign read out in the
## game's dialogue box, and — once her model is in — the animation states.
func _phase2() -> void:
	var apex := await _jump_from(&"start", 1.2, false)
	_check("a held jump goes up about 0.65 m, under a cliff step (0.75)", apex > 0.6 and apex < 0.72, "apex %.2f m" % apex)
	var tap := await _jump_from(&"start", 0.06, false)
	_check("a tapped jump goes lower", tap < apex - 0.15, "apex %.2f m" % tap)
	await _jump_from(&"before_low_box", 1.0, true)
	_check("jumps onto the low crate (0.5 m)", absf(_player.global_position.y - 0.5) < 0.05 and _player.is_on_floor(),
		"y = %.2f" % _player.global_position.y)
	await _shot("04_caisse")
	await _jump_from(&"before_high_box", 1.0, true)
	_check("not onto the high one (1 m)", _player.global_position.y < 0.1, "y = %.2f" % _player.global_position.y)

	_demo.call("place", &"before_sign")
	await create_timer(0.4).timeout
	var signpost: Node3D = _demo.get("signpost")
	_check("the sign is the one in reach", _player.call("nearest_interactable") == signpost, "nearest %s" % [_player.call("nearest_interactable")])
	_check("…with its hint shown", (signpost.get("_hint") as Label3D).visible, "")
	await _shot("05_panneau_indice")
	_press(&"interact")
	await create_timer(0.6).timeout
	var dialogue := root.get_node("Dialogue")
	_check("interacting opens the game's dialogue", dialogue.get("active") and _player.get("busy"), "active %s" % dialogue.get("active"))
	await _shot("06_dialogue")
	var presses := 0
	while dialogue.get("active") and presses < 12:
		_press(&"interact")
		presses += 1
		await create_timer(0.5).timeout
	await create_timer(0.3).timeout
	_check("…which closes, and she can move again", not dialogue.get("active") and not _player.get("busy"), "%d appuis" % presses)

	var animator: Node = _player.get("animator")
	if animator == null:
		print("SKIP  animations (pas encore de modèle : capsule)")
		return
	_demo.call("place", &"start")   # (60 cm up: she drops, lands, stands)
	await create_timer(1.6).timeout
	_check("standing: the move state", animator.call("state") == &"move", "%s" % animator.call("state"))
	await _shot("07_debout")
	var tree: AnimationTree = animator.get("tree")
	Input.action_press(&"move_up")
	await create_timer(0.6).timeout
	var blend: float = tree.get(&"parameters/sm/move/blend_position")
	var pace: float = tree.get(&"parameters/pace/scale")
	_check("walking (1.6 m/s): child steps, ~0.74 m at ~2.2 a second", absf(blend - 0.74) < 0.06 and absf(pace - 1.08) < 0.05,
		"pas %.2f m, %.2f cycles/s" % [blend, pace])
	var gait := await _gait_sample(1.5)
	_check("…a walk: a foot always on the ground", gait.x < 0.05, "les deux pieds en l'air %d %% du temps" % int(gait.x * 100))
	_check("…as many steps as the cadence says", absf(gait.y - 2.17) < 0.45, "%.2f pas/s mesurés" % gait.y)
	await _shot("07_marche")
	Input.action_press(&"run")
	await create_timer(0.5).timeout
	blend = tree.get(&"parameters/sm/move/blend_position")
	pace = tree.get(&"parameters/pace/scale")
	_check("running (5 m/s): longer and quicker steps", blend > 1.35 and blend < 1.6 and pace > 1.65, "pas %.2f m, %.2f cycles/s" % [blend, pace])
	gait = await _gait_sample(1.0)
	_check("…a run, but no floating leaps (was 67 %, slowed)", gait.x < 0.62, "les deux pieds en l'air %d %% du temps" % int(gait.x * 100))
	await _shot("07_course")
	Input.action_release(&"run")
	Input.action_release(&"move_up")
	# her strides seen from the side, a frame every 1/20 s: walking, then running
	for run in [false, true]:
		_demo.call("place", &"start")
		_pivot.call("set_view", 0.0, -8.0, 4.0)
		await create_timer(0.9).timeout
		Input.action_press(&"move_right")
		if run:
			Input.action_press(&"run")
		await create_timer(0.5).timeout
		await _strip("07_foulees_%s" % ("course" if run else "marche"), 10, 0.05)
		Input.action_release(&"move_right")
		Input.action_release(&"run")
	_demo.call("place", &"before_sign")   # (on the ground: no drop, no landing)
	await create_timer(0.4).timeout
	await create_timer(0.4).timeout
	_press(&"jump", 0.4)
	await create_timer(0.25).timeout
	_check("jumping: off the move state", animator.call("state") in [&"jump_start", &"air"], "%s" % animator.call("state"))
	await _shot("08_saut")
	await create_timer(1.5).timeout
	_check("back to the move state after landing", animator.call("state") == &"move", "%s" % animator.call("state"))


## Phase 3: the two wild Velociraptors — real size (2 m long, younger smaller), on the ground; they
## amble about their homes; one watches Chloé coming, runs off (running) when she comes too close,
## calms down once she is far; Chloé observes one (its name and level in the dialogue).
func _phase3() -> void:
	var raptors: Array = _demo.get("raptors")
	_check("two Velociraptors in the meadow", raptors.size() == 2, "%d" % raptors.size())
	if raptors.is_empty():
		return
	var r: CharacterBody3D = raptors[0]
	var game_dino: RefCounted = r.get("dino")
	var length: float = r.get("length_m")
	var growth: float = r.get("growth")
	_check("its gameplay creature is the 2.5D's", game_dino.get("level") == 14 and game_dino.call("species").get("id") == &"velociraptor",
		"niv. %d" % game_dino.get("level"))
	_check("grown (level 14): its real length, 2 m", absf(length - 2.0) < 0.15 and absf(growth - 1.0) < 0.01,
		"%.2f m (croissance %.2f), hauteur %.2f m" % [length, growth, r.get("height_m")])
	var young: CharacterBody3D = raptors[1]
	var young_length: float = young.get("length_m")
	_check("young (level 5): smaller, as it grows in the 2.5D", absf(young_length - 2.0 * float(young.get("growth"))) < 0.1 and young_length < 1.5,
		"%.2f m (croissance %.2f)" % [young_length, young.get("growth")])
	_demo.call("place", &"far_away")
	var home: Vector3 = r.get("home")
	var start: Vector3 = r.global_position
	var furthest := 0.0
	var off_home := 0.0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() < t0 + 12000:
		await physics_frame
		furthest = maxf(furthest, (r.global_position - start).length())
		off_home = maxf(off_home, (r.global_position - home).slide(Vector3.UP).length())
	_check("it stands on the ground", r.is_on_floor(), "y %.2f" % r.global_position.y)
	_check("it ambles about (left alone 12 s)", furthest > 1.0, "moved up to %.1f m" % furthest)
	_check("…around its home", off_home < 8.0 + 2.0, "up to %.1f m from home" % off_home)

	# Chloé comes near: watched, then run from
	var pos: Vector3 = r.global_position
	var near := pos + Vector3(0, 0, -7.5)
	_player.call("place_at", near, 0.0)
	_pivot.call("set_view", 180.0, -22.0)
	await create_timer(0.8).timeout
	_check("it watches Chloé coming (7.5 m)", r.call("state") == &"alert", "%s" % r.call("state"))
	await _shot("09_raptor_regarde")
	var before := (r.global_position - _player.global_position).length()
	Input.action_press(&"move_up")
	var fled := false
	var top_speed := 0.0
	t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() < t0 + 2500:
		await physics_frame
		fled = fled or r.call("state") == &"flee"
		top_speed = maxf(top_speed, Vector2(r.velocity.x, r.velocity.z).length())
	Input.action_release(&"move_up")
	var after := (r.global_position - _player.global_position).length()
	_check("it runs off when she comes close", fled and after > 4.0, "%.1f → %.1f m" % [before, after])
	_check("…running, faster than her", top_speed > 3.6, "%.1f m/s" % top_speed)
	var blend: float = (r.get("animator").get("tree") as AnimationTree).get(&"parameters/sm/move/blend_position")
	_check("…with its run animation", blend > 1.5, "blend %.2f" % blend)
	await _shot("10_raptor_fuit")
	_demo.call("place", &"far_away")
	t0 = Time.get_ticks_msec()
	while r.call("state") == &"flee" and Time.get_ticks_msec() < t0 + 8000:
		await physics_frame
	_check("it calms down once she is far", r.call("state") != &"flee", "%s" % r.call("state"))
	_check("…still on the meadow (it never runs off its edge)", r.global_position.y > -0.2 and absf(r.global_position.z) < 40.0,
		"at %s" % r.global_position)

	# observing the other one, from 5 m
	var other: CharacterBody3D = raptors[1]
	other.set_physics_process(false)   # held still: a raptor that wanders off is not what is tested here
	other.velocity = Vector3.ZERO
	await create_timer(0.5).timeout
	var at := other.global_position + Vector3(0, 0, -5.0)
	_player.call("place_at", Vector3(at.x, 0.0, at.z), 0.0)
	_pivot.call("set_view", 160.0, -18.0, 4.5)
	await create_timer(0.5).timeout
	var it: Node = _player.call("nearest_interactable")
	_check("she can observe a raptor from 5 m", it != null and it.get_parent() == other, "%s" % [it])
	await _shot("11_observer_raptor")
	if it:
		var first: String = (it.get("lines") as Array)[0]["text"]
		_check("…it reads its name and level", first.contains("Velociraptor") and first.contains("niveau 5"), first)
		_press(&"interact")
		await create_timer(0.8).timeout
		_check("…in the game's dialogue", root.get_node("Dialogue").get("active"), "")
		await _shot("12_observer_dialogue")
		var presses := 0
		while root.get_node("Dialogue").get("active") and presses < 15:
			_press(&"interact")
			presses += 1
			await create_timer(0.5).timeout

	# side by side, for the sizes: the grown raptor held still, Chloé beside it, seen from the side
	r.set_physics_process(false)
	r.velocity = Vector3.ZERO
	var model: Node3D = r.get("model").get_parent()
	model.rotation.y = PI * 0.5   # facing +X
	_player.call("place_at", r.global_position + Vector3(0.4, 0, -1.0), PI * 0.5)
	_player.set_physics_process(false)
	_pivot.call("set_view", 0.0, -8.0, 3.2)
	_pivot.set("target", r)
	_pivot.call("snap")
	await create_timer(0.6).timeout
	await _shot("13_echelle_chloe_raptor")
	_pivot.set("target", _player)
	_player.set_physics_process(true)
	r.set_physics_process(true)


## Phase 4: the Prairie du Grand Crâne in 3D (world3d/zone3d), built from the 2.5D zone. It builds
## quickly; Chloé arrives on the ground and walks over the relief; the woods, deep water and a cliff
## stop her as in the 2.5D; its raptors are out; frames per second; pictures of the zone.
func _phase4() -> void:
	var zone := _demo
	_quiet(zone)
	var src: RefCounted = zone.get("source")
	var terrain: Node3D = zone.get("terrain")
	var build_ms: int = zone.get("build_ms")
	_check("the zone builds in a few seconds", build_ms < 8000, "%d ms, %s m" % [build_ms, src.call("size_m")])
	var at := _player.global_position
	_check("Chloé arrives on the ground", _player.is_on_floor() and absf(at.y - float(terrain.call("height_at", at.x, at.z))) < 0.15,
		"y %.2f, sol %.2f" % [at.y, terrain.call("height_at", at.x, at.z)])
	await _shot("20_prairie_arrivee")
	var moved := await _hold_up(3.0)
	_check("she walks over the relief", moved > 3.0 and _player.is_on_floor(), "%.1f m, au sol %s" % [moved, _player.is_on_floor()])
	_pivot.call("set_view", 200.0, -48.0, 14.0)
	await create_timer(0.6).timeout
	await _shot("21_prairie_vue_haute")
	for test: Array in [[&"forest", "the woods stop her"], [&"water", "deep water stops her"]]:
		var spot: Vector2i = _tile_south_of(src, test[0])
		if spot.x < 0:
			print("SKIP  %s (pas de case %s bordée d'herbe)" % [test[1], test[0]])
			continue
		await _walk_north_from(src, terrain, spot)
		var now: Vector2i = src.call("tile_at", _player.global_position.x, _player.global_position.z)
		_check(test[1], src.call("surface", now) != test[0], "case %s : %s" % [now, src.call("surface", now)])
		await _shot("22_bord_%s" % test[0])
	var edge := _cliff_south_side(src)
	if edge.x >= 0:
		await _walk_north_from(src, terrain, edge)
		var low: float = src.call("tile_height", edge)
		_check("a cliff stops her (no climbing, no jumping up)", _player.global_position.y < low + 0.4, "y %.2f (bas %.2f)" % [_player.global_position.y, low])
		await _shot("23_falaise")
	var dinos: Array = zone.get("dinos")
	_check("the raptors of its habitats are out", dinos.size() > 0, "%d" % dinos.size())
	if not dinos.is_empty():
		var d: Node3D = dinos[0]
		_player.call("place_at", d.global_position + Vector3(0, 0.3, -6.0), 0.0)
		_pivot.call("set_view", 160.0, -15.0, 5.0)
		await create_timer(1.2).timeout
		await _shot("24_raptor_prairie")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	zone.call("place", &"DepuisPort")
	await create_timer(1.0).timeout
	var frames := 0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() < t0 + 3000:
		await process_frame
		frames += 1
	var fps := frames / 3.0
	_check("smooth on this PC (GTX 1650 Ti)", fps > 60.0, "%.0f im/s" % fps)


## No battle while the zone's ground is tested: no hidden dinos in the tall grass, the others calm.
func _quiet(zone: Node) -> void:
	var enc: Node = zone.get("session").get("encounters")
	enc.set_physics_process(false)
	for d in zone.get("dinos"):
		d.call("calm_down", 9999.0)


## Phase 5: the game in the 3D Prairie — a new game (Vif), the game's HUD, Vif walking with Chloé,
## the day and the night (the 2.5D's light), the dinos of the time of day (Parasaurolophus by day),
## a raptor met at night starting the game's own battle (left by running away), the save keeping
## Chloé's place in the 2.5D's units.
func _phase5() -> void:
	var zone := _demo
	var session: Node = zone.get("session")
	var enc: Node = session.get("encounters")
	var game := root.get_node("Game")
	var party: Array = game.get("party")
	_check("a new game, with Vif", party.size() == 1 and party[0].call("species").get("id") == &"velociraptor", "%d dino(s)" % party.size())
	var hud: CanvasLayer = session.get("hud")
	var bars := hud.find_children("*", "PartyBar", true, false).size() + hud.find_children("*", "ClockBadge", true, false).size()
	_check("the game's HUD (party, clock…)", bars == 2, "%d" % bars)
	enc.set_physics_process(false)   # (no hidden dino while Vif's walk is looked at)
	var companion: Node3D = session.get("companion")
	_check("Vif walks with Chloé", companion != null, "%s" % [companion])
	if companion:
		zone.call("place", &"DepuisPort")
		await create_timer(1.0).timeout
		await _hold_up(4.0)
		await create_timer(0.8).timeout
		var gap := companion.global_position.distance_to(_player.global_position)
		_check("…keeping up with her", gap < 4.0, "%.1f m" % gap)
		await _shot("30_vif_suit_chloe")
	var sun: DirectionalLight3D = zone.get("sky").get("sun")
	game.set("clock", 13.0 * 60.0)
	await create_timer(0.6).timeout
	var day: float = sun.light_energy
	var day_dinos: Array = zone.get("dinos").map(func(d: Node) -> StringName: return d.get("species").get("id"))
	_check("by day, the Parasaurolophus are out (the 2.5D's habitats)", &"parasaurolophus" in day_dinos and not &"velociraptor" in day_dinos, "%s" % [day_dinos])
	_player.call("place_at", _player.global_position, PI)
	_pivot.call("set_view", 200.0, -20.0, 9.0)
	await _shot("31_jour")
	game.set("clock", 22.5 * 60.0)
	await create_timer(1.0).timeout
	var night: float = sun.light_energy
	_check("the night falls (the 2.5D's light over the day)", night < day * 0.5, "soleil %.2f → %.2f" % [day, night])
	await _shot("32_nuit")
	var raptor: Node3D = null
	for d in zone.get("dinos"):
		if d.get("species").get("id") == &"velociraptor":
			raptor = d
			break
	_check("at night, the raptors are out", raptor != null, "")
	if raptor == null:
		return
	raptor.set_physics_process(false)   # held still, so Chloé walks into it
	enc.set_physics_process(true)
	var to := raptor.global_position + Vector3(0, 0, -3.5)
	zone.call("place_at", to, 0.0)
	await create_timer(0.5).timeout
	Input.action_press(&"move_up")
	var battle: Node = null
	var t0 := Time.get_ticks_msec()
	while battle == null and Time.get_ticks_msec() < t0 + 5000:
		await process_frame
		for n in enc.get_children():
			if n.has_signal("_action_chosen"):
				battle = n
	Input.action_release(&"move_up")
	_check("walking into a raptor starts the game's battle", battle != null and paused, "en pause : %s" % paused)
	if battle == null:
		return
	await create_timer(2.5).timeout
	await _shot("33_combat")
	t0 = Time.get_ticks_msec()
	while is_instance_valid(battle) and battle.is_inside_tree() and Time.get_ticks_msec() < t0 + 40000:
		var hud_open: bool = battle.get("_hud") != null and battle.get("_hud").call("is_open")
		if battle.get("_menu").visible or hud_open:
			battle.emit_signal("_action_chosen", {"type": "run"})
		else:
			_press(&"interact")
		await create_timer(0.4).timeout
	while root.get_node("Dialogue").get("active"):
		_press(&"interact")
		await create_timer(0.4).timeout
	await create_timer(0.5).timeout
	_check("…left by running away, the zone goes on", not paused and enc.get("last_result") == "run", "résultat « %s »" % enc.get("last_result"))
	_check("…and that raptor keeps away a while", is_instance_valid(raptor) and raptor.call("is_calm"), "")
	var save := root.get_node("Save")
	_check("the save writes", save.call("save_game"), "")
	var at := _player.global_position
	var px: Vector2 = game.get("player_position")
	var s: float = zone.get("source").get("scale")
	_check("…Chloé's place, in the 2.5D's units", px.distance_to(Vector2(at.x, at.z) / s * 48.0) < 2.0 and game.get("has_position"), "%s" % px)


## The first tile of `surface` whose south neighbour is open grass on the same level: that neighbour.
func _tile_south_of(src: RefCounted, surface: StringName) -> Vector2i:
	var tiles: Vector2i = src.get("tiles")
	for y in range(2, tiles.y - 3):
		for x in range(2, tiles.x - 2):
			var below := Vector2i(x, y + 1)
			if src.call("surface", Vector2i(x, y)) == surface and src.call("surface", below) == &"grass" \
					and src.call("surface", below + Vector2i(0, 1)) == &"grass" and src.call("surface", below + Vector2i(0, 2)) == &"grass" \
					and absf(float(src.call("tile_height", below)) - float(src.call("tile_height", below + Vector2i(0, 2)))) < 0.1:
				return below
	return Vector2i(-1, -1)


## A grass tile at the foot of a cliff that rises to the north.
func _cliff_south_side(src: RefCounted) -> Vector2i:
	var tiles: Vector2i = src.get("tiles")
	for y in range(2, tiles.y - 3):
		for x in range(2, tiles.x - 2):
			var top := Vector2i(x, y)
			var foot := Vector2i(x, y + 1)
			var ht: float = src.call("tile_height", top)
			var hf: float = src.call("tile_height", foot)
			var behind := foot + Vector2i(0, 1)   # where she starts from: open grass on the foot's level
			if ht > hf and src.call("is_cliff", ht, hf) and src.call("surface", foot) == &"grass" and src.call("surface", behind) == &"grass" \
					and absf(float(src.call("tile_height", behind)) - hf) < 0.05 and absf(float(src.call("tile_height", behind + Vector2i(0, 1))) - hf) < 0.05 \
					and absf(float(src.call("tile_height", foot + Vector2i(-1, 0))) - hf) < 0.05 and absf(float(src.call("tile_height", foot + Vector2i(1, 0))) - hf) < 0.05:
				return foot
	return Vector2i(-1, -1)


## From the middle of the tile south of `tile` (so 1.5 tiles from its north edge), facing north, the
## camera behind: holds "up" (and jump at the end) for 2.5 s.
func _walk_north_from(src: RefCounted, terrain: Node3D, tile: Vector2i) -> void:
	var s: float = src.get("scale")
	var x := (tile.x + 0.5) * s
	var z := (tile.y + 1.5) * s
	_player.call("place_at", Vector3(x, float(terrain.call("height_at", x, z)) + 0.2, z), PI)
	_pivot.call("set_view", 0.0, -25.0, 4.5)
	await create_timer(0.5).timeout
	await _hold_up(2.0)
	_press(&"jump", 0.3)
	Input.action_press(&"move_up")
	await create_timer(0.6).timeout
	Input.action_release(&"move_up")
	await create_timer(0.6).timeout


## Holds "up" for `secs`; returns how far she went on the ground (m).
func _hold_up(secs: float) -> float:
	var from := _player.global_position
	Input.action_press(&"move_up")
	await create_timer(secs).timeout
	Input.action_release(&"move_up")
	await create_timer(0.3).timeout
	return (_player.global_position - from).slide(Vector3.UP).length()


## From a mark, jumps (button held `hold` s), walking forward for the first 0.4 s too if `forward`
## (enough to reach a crate, not to walk off its far side); returns the apex (m).
func _jump_from(mark: StringName, hold: float, forward: bool) -> float:
	_demo.call("place", mark)
	await create_timer(0.4).timeout
	if forward:
		Input.action_press(&"move_up")
	_press(&"jump", hold)
	var top := -INF
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() < start + 1200:
		await physics_frame
		top = maxf(top, _player.global_position.y)
		if Time.get_ticks_msec() > start + 400:
			Input.action_release(&"move_up")
	Input.action_release(&"move_up")
	await create_timer(0.5).timeout
	return top


## Chloé's feet over `secs` as she moves: the share of the time both are off the ground, and how many
## times a second a foot is set down (her steps), read on her skeleton.
func _gait_sample(secs: float) -> Vector2:
	var skel := _player.get("model").find_children("*", "Skeleton3D", true, false).front() as Skeleton3D
	var feet := [skel.find_bone("ball_l"), skel.find_bone("ball_r")]
	var down := [true, true]   # a foot already down when it starts is not a step
	var steps := 0
	var airborne := 0
	var frames := 0
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		await physics_frame
		frames += 1
		var ground := _player.global_position.y
		var any_down := false
		for k in 2:
			var y := (skel.global_transform * skel.get_bone_global_pose(feet[k])).origin.y - ground
			# a step: set down after being truly lifted (the heel-to-toe roll is not two steps)
			if y < 0.06 and not down[k]:
				steps += 1
				down[k] = true
			elif y > 0.12:
				down[k] = false
			any_down = any_down or y < 0.06
		if not any_down:
			airborne += 1
	return Vector2(float(airborne) / maxi(frames, 1), steps / secs)


## `count` frames `every` s apart, side by side in one picture (each frame cropped to the middle).
func _strip(name: String, count: int, every: float) -> void:
	var frames: Array[Image] = []
	for i in count:
		await process_frame
		var full := root.get_viewport().get_texture().get_image()
		var w := int(full.get_width() * 0.25)
		var crop := full.get_region(Rect2i(int(full.get_width() * 0.5 - w * 0.5), int(full.get_height() * 0.2), w, int(full.get_height() * 0.6)))
		frames.append(crop)
		await create_timer(every).timeout
	var sheet := Image.create(frames[0].get_width() * count, frames[0].get_height(), false, frames[0].get_format())
	for i in count:
		sheet.blit_rect(frames[i], Rect2i(Vector2i.ZERO, frames[i].get_size()), Vector2i(i * frames[0].get_width(), 0))
	sheet.save_png(_out.path_join(name + ".png"))


## A press of an action as an event (as a key would), released after `hold` s.
func _press(action: StringName, hold := 0.05) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await create_timer(hold).timeout
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


## From a mark, the camera turned `yaw` degrees from behind her (NAN: as the mark sets it), holds
## "up" (and run) for `secs`; returns how far she went on the ground.
func _walk(mark: StringName, yaw: float, secs: float, run := false) -> Vector3:
	_demo.call("place", mark)
	if not is_nan(yaw):
		_pivot.call("set_view", yaw, -22.0)
	await create_timer(0.3).timeout
	var from := _player.global_position
	Input.action_press(&"move_up")
	if run:
		Input.action_press(&"run")
	await create_timer(secs).timeout
	var moved := _player.global_position - from
	Input.action_release(&"move_up")
	Input.action_release(&"run")
	await create_timer(0.4).timeout
	return Vector3(moved.x, 0.0, moved.z)


## From a mark, holds "up" for `secs`; returns the highest she stood (m).
func _highest(mark: StringName, secs: float) -> float:
	_demo.call("place", mark)
	await create_timer(0.3).timeout
	Input.action_press(&"move_up")
	var top := -INF
	var end := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < end:
		await physics_frame
		top = maxf(top, _player.global_position.y)
	Input.action_release(&"move_up")
	await create_timer(0.3).timeout
	return top


func _check(what: String, ok: bool, detail: String) -> void:
	print("%s  %s  (%s)" % ["PASS" if ok else "FAIL", what, detail])
	if not ok:
		_failed += 1


func _shot(name: String) -> void:
	await process_frame
	root.get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))
