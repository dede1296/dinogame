extends SceneTree
## Phases 1 to 3 of docs/migration-3d.md, checked in the real engine (it needs a window to render,
## so not --headless):
##   godot --path Godot --script res://tools/test_world3d.gd -- out=<folder> [only=1|2|3|4|5|7]
## `only=`: just that phase (test what a change touches, not everything: the whole run is for a big
## change). Phase 1: Chloé's body and the camera; 2: jump, sign, her animations; 3: the dinos;
## 4: the Prairie in 3D (its own scene, only with only=4); 5: the game in it; 7: its species.
## Prints PASS / FAIL for each check, saves screenshots, quits with 1 on any failure.
## (Game classes are used through the nodes only: this script is compiled before the autoloads.)

const DEMO := "res://world3d/demo/demo_3d.tscn"
const ZONE := "res://world3d/zone3d/zone_3d.tscn"   # phase 4: the Prairie du Grand Crâne in 3D
const WALK_SPEED := 1.6            # Player3D.WALK (m/s)
const RUN_SPEED := 165.0 / 48.0 * 1.45   # Player.SPEED × Player.RUN_SPEED (m/s): the 2.5D run

var _out := "user://test_world3d"
var _failed := 0
var _caption_layer: CanvasLayer   # what this run tests, written on the view for the whole test
var _demo: Node
var _player: Node3D
var _pivot: Node3D
var _only := 0   # 0: every phase
var _views_only: PackedStringArray = []   # vues=02,03: only these views of the remodelled Prairie


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("only="):
			_only = int(arg.substr(5))
		elif arg.begins_with("vues="):
			_views_only = arg.substr(5).split(",")
	DirAccess.make_dir_recursive_absolute(_out)
	root.get_node("Save").set("path", "user://capture_save.json")   # never the player's save
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://capture_save.json"))   # a new game each time
	change_scene_to_file(ZONE if _only in [4, 5, 7] else DEMO)
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
	if _only == 7:   # (the Prairie: its species)
		await _phase7()
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
	_caption("Phase 1 — Chloé en 3D : sol, relief, caméra orbitale")
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
	_caption("Phase 2 — saut, interaction (panneau, dialogue) et foulées de Chloé")
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
	_caption("Phase 3 — premier dino 3D : taille, états, fuite, observation")
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
## Once the zone is remodelled (its plan's relief), the 2.5D's tiles no longer say where its woods,
## water and cliffs are: those three checks are skipped, said so, and the remodelled zone is checked
## instead (_remodelled): its scenery and the story's actors on the new ground, its water, what stops
## Chloé walked over on the game's own collisions (passages closed, then open), four views.
func _phase4() -> void:
	var zone := _demo
	var terrain: Node3D = zone.get("terrain")
	var remodelled: bool = terrain.call("is_remodelled")
	_caption(REMODELLED_CAPTION if remodelled else "Phase 4 — la Prairie bâtie en 3D : terrain, eau, falaises, décors, habitants")
	_quiet(zone)
	var src: RefCounted = zone.get("source")
	var build_ms: int = zone.get("build_ms")
	_check("the zone builds in a few seconds", build_ms < 8000, "%d ms, %s m" % [build_ms, src.call("size_m")])
	var at := _player.global_position
	_check("Chloé arrives on the ground", _player.is_on_floor() and absf(at.y - float(terrain.call("height_at", at.x, at.z))) < 0.15,
		"y %.2f, sol %.2f" % [at.y, terrain.call("height_at", at.x, at.z)])
	if not remodelled:
		await _shot("20_prairie_arrivee")
	var moved := await _hold_up(3.0)
	_check("she walks over the relief", moved > 3.0 and _player.is_on_floor(), "%.1f m, au sol %s" % [moved, _player.is_on_floor()])
	if remodelled:
		for rule in ["the woods stop her", "deep water stops her", "a cliff stops her (no climbing, no jumping up)"]:
			print("SKIP  %s (règle des cases du 2,5D : la zone est remodelée, ses bois, son eau et ses falaises ne sont plus ceux des cases ; ce qui l'arrête suit le relief et le plan, vérifié plus bas)" % rule)
		await _remodelled(zone)
		await _fps_check(zone)
		return
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
	await _fps_check(zone)


## The frames per second at the arrival, vsync off (the threshold is said, not tuned here).
func _fps_check(zone: Node) -> void:
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


# --- phase 4 on a remodelled zone ---------------------------------------------------------------------

const REMODELLED_CAPTION := "Prairie remodelée — relief, obstacles et acteurs sur le nouveau sol"
const LAYOUT := "res://docs/zones-3d/plaines-layout.json"
const RELIEF_TEST := "res://tools/test_relief_plaines.gd"   # its BEHIND: what lies behind a passage
const STORY_WORLD := "res://world3d/story/story_world_3d.gd"
const GRID := 0.5             # the walk's grid (Terrain3D's vertices)
## The walk's body: Chloé's (0.17 m), widened so a mesh's thin face between two vertices of the grid
## (the Crâne's) is always met (half a cell's diagonal: 0.35 m).
const BODY_R := 0.38
const PASSAGE_R := 0.6        # a passage the plan wants open: 1.2 m wide at the least…
const DOOR_M := 4.0           # …its doors 4 m
const STAND_DEG := 46.0       # Player3D.floor_max_angle: steeper, she slides
const KNEE_M := 0.4           # what stops her stands between a step (0.35 m) and her head
const HEAD_M := 1.5
const WORLD_AND_WATER := 1 | 16   # Layers3D.WORLD | Layers3D.WATER (what stops Chloé)
## In the Crâne's mouth, behind its seal as the model has it (the plan's tool drew a rectangle there):
## reached once it opens, not before (the story's scene walks the Alpha out through them).
const BEHIND_SEAL := ["scene_crane[1]", "scene_crane[2]"]
## The obstacles themselves (the plan's tool counted them behind, under its masks): she walks up to
## them, to use her dino's ability (not checked either way).
const OBSTACLE_ANCHORS := ["RocherGrotte", "PorteCrane"]
const BEHIND_NEAR := 2        # an anchor behind a passage counts as reached within 1 m (2 vertices)
## What opens the passages: the 2.5D's Obstacles' flags, the Crâne's (and the full moon, the ford's).
const PASSAGE_FLAGS: Array[StringName] = [&"tronc_bosquet_tranche", &"rocher_grotte_brise", &"porte_ambre_ouverte", &"crane_ouvert"]
const PROVISIONAL := "passage_provisoire_3d_%s"   # StoryObstacles3D.PROVISIONAL_FLAG
const FULL_MOON_DAY := 2      # GameState.FULL_MOON_FIRST
## The passages, where to measure their width once open, and the way across them (ZERO: square to
## the path through them).
const DOORS := [["le tronc (haie du bosquet)", Vector2(58, 86), Vector2.ZERO], ["l'encoche du rocher", Vector2(116, 50.5), Vector2.ZERO],
	["la porte d'ambre (gorge)", Vector2(190, 64), Vector2.ZERO], ["la gueule du Crâne", Vector2(172, 100), Vector2.RIGHT],
	["le gué de lune", Vector2(134, 119), Vector2.RIGHT]]
## Each closed obstacle, run into by Chloé herself (her own body, 0.17 m: the walk's grid uses a wider
## one): [what, from, to, the obstacle's middle] — she stays on her side of it.
const HELD := [
	["the tronc", Vector2(64, 93), Vector2(52, 77), Vector2(58, 86)], ["…beside it", Vector2(65.2, 92.1), Vector2(53.2, 76.1), Vector2(59.2, 85.1)],
	["the rocher", Vector2(116, 55), Vector2(116, 44), Vector2(116, 49.2)], ["…its rubble", Vector2(113.5, 55), Vector2(113.5, 44), Vector2(113.5, 49.2)],
	["the porte d'ambre", Vector2(190, 71), Vector2(190, 57), Vector2(190, 64)], ["…by the gorge's wall", Vector2(191.8, 71), Vector2(191.8, 57), Vector2(191.8, 64)],
	["the Crâne's seal", Vector2(172, 108), Vector2(172, 94), Vector2(172, 103.7)], ["…by the jaw", Vector2(173.6, 108), Vector2(173.6, 94), Vector2(173.6, 103.7)],
	["the gué de lune (by day)", Vector2(134, 114.5), Vector2(134, 123.5), Vector2(134, 116)], ["…along its side", Vector2(136.2, 114.5), Vector2(136.2, 123.5), Vector2(136.2, 116)],
]
## Round the Crâne's jaw, under its cheeks (the model leaves room there, at the parvis' level), and
## on into its mouth behind the seal: [what, the way she tries, where she must not get to].
const CHEEKS := [["east", [Vector2(177, 108), Vector2(177, 99), Vector2(174.5, 96), Vector2(172, 94)], Vector2(172, 94)],
	["west", [Vector2(167, 108), Vector2(167, 99), Vector2(169.5, 96), Vector2(172, 94)], Vector2(172, 94)]]
## The places the 2.5D's rules had cut off once the relief was remodelled (its report): walked.
const CUT_OFF := {"le corridor du passage 3": "route_corridor", "la sente de la rive sud": "sente_rive_sud",
	"l'est (la grande boucle)": "sente_est", "les éboulis": "sente_eboulis", "la cascade": "sente_cascade"}
const VIEWS := [
	{"name": "01_seuil_revelation", "at": Vector2(120, 162), "look": Vector2(0.15, -1), "pitch": -26.0, "dist": 18.0},
	# (from the carrefour where the route du Crâne leaves it, the camera over the parvis' edge: 6.5 m, above
	# the eye at the carrefour's 3.3 m, it hides the skull's foot from lower down)
	{"name": "02_carrefour_vers_crane", "at": Vector2(121, 103), "look": Vector2(51, -3), "pitch": -16.0, "dist": 9.0},
	{"name": "03_parvis_vers_etang", "at": Vector2(155, 112), "look": Vector2(-0.89, 0.45), "pitch": -32.0, "dist": 11.0},
	{"name": "04_porte_ambre", "at": Vector2(190, 70), "look": Vector2(0, -1), "pitch": -10.0, "dist": 7.0},
]

var _layout := {}
var _nx := 0
var _nz := 0
var _hv := PackedFloat32Array()      # the ground at the grid's vertices
var _slope := PackedFloat32Array()   # its slope (degrees)
var _was := {}                       # the day and the hour before the passages were opened


## The remodelled Prairie: on its new ground (scenery, story obstacles, the story's actors), its water,
## then what stops Chloé walked over on the game's own collisions — passages closed (nothing behind
## them reached, everything before), Chloé running where the 2.5D's rules had cut her off, passages
## open (everything reached, the paths 1.2 m clear, the doors' widths) — and four views.
func _remodelled(zone: Node) -> void:
	_layout = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	var terrain: Node3D = zone.get("terrain")
	_grid(terrain)
	_on_new_ground(zone, terrain)
	_water_check(zone, terrain)
	await physics_frame
	await physics_frame
	var space := (zone as Node3D).get_world_3d().direct_space_state
	var ground: RID = _ground_rid(terrain)
	if not ground.is_valid():
		print("SIGNALÉ  collision de Terrain3D introuvable : la marche compte le sol sous le genou (pentes > 46° comptées fermées)")
	var t0 := Time.get_ticks_msec()
	var closed := _free_grid(space, ground, BODY_R)
	var port := _anchor("spawn_DepuisPort")
	var seen := _reach(closed, port)
	var behind: Array = load(RELIEF_TEST).get_script_constant_map()["BEHIND"]
	var bypass: Array[String] = []
	var before: Array[String] = []
	for a in _anchors():
		if a["id"] in OBSTACLE_ANCHORS:
			continue
		var back: bool = a["id"] in behind or a["id"] in BEHIND_SEAL
		if back and _reached(seen, a["at"], BEHIND_NEAR):
			bypass.append(a["id"])
		elif not back and not _reached(seen, a["at"]):
			before.append(a["id"])
	print("MESURE  marche sur les collisions du jeu (%d sommets, corps de %.1f m) : %d ms" % [_nx * _nz, BODY_R * 2.0, Time.get_ticks_msec() - t0])
	print("SIGNALÉ  ancres dans la gueule du Crâne, derrière le sceau du modèle (atteintes une fois ouvert) : %s ; les obstacles eux-mêmes, approchés : %s" % [BEHIND_SEAL, OBSTACLE_ANCHORS])
	_check("passages closed (tronc, rocher, porte, sceau du Crâne, gué de lune, haie), nothing behind them is reached", bypass.is_empty(), "%s" % [bypass])
	_check("…and every anchor before them is", before.is_empty(), "%s" % [before])
	var missed: Array[String] = []
	for place: String in CUT_OFF:
		for p in _path(CUT_OFF[place]):
			if not _reached(seen, p):
				missed.append("%s %s" % [place, p])
				break
	_check("the places the 2.5D's rules cut off are reached (corridor, rive sud, est, éboulis, cascade)", missed.is_empty(), "%s" % [missed])
	var from_crane := _reach(closed, Vector2(172, 105))
	missed.clear()
	for leg in [["le tronc", Vector2(58, 89)], ["le rocher de Charge", Vector2(116, 54)], ["la porte d'ambre", Vector2(190, 67)]]:
		if not _reached(from_crane, leg[1]):
			missed.append(leg[0])
	_check("…from the porte du Crâne she walks to each passage", missed.is_empty(), "manque %s" % [missed])
	await _walks(zone)
	await _held_back(zone)
	await _provisional_use(zone)
	await _passages(true)
	var opened := _free_grid(space, ground, BODY_R, closed)
	seen = _reach(opened, port)
	var unreachable: Array[String] = []
	for a in _anchors():
		if not _reached(seen, a["at"]):
			unreachable.append(a["id"])
	_check("passages open (flags set, full moon), every anchor is reached", unreachable.is_empty(), "%s" % [unreachable])
	var count := 0
	for k in seen.size():
		count += seen[k]
	print("MESURE  sol praticable depuis le port, passages ouverts, sur les collisions du jeu : %.0f %% de la zone" % (100.0 * count / seen.size()))
	_path_clearance(space, ground)
	_door_widths(space, ground)
	await _passages(false)
	await _views(zone)


## The relief at the grid's vertices, and its slopes.
func _grid(terrain: Node3D) -> void:
	var size: Vector2 = _demo.get("source").call("size_m")
	_nx = int(size.x / GRID) + 1
	_nz = int(size.y / GRID) + 1
	_hv.resize(_nx * _nz)
	for j in _nz:
		for i in _nx:
			_hv[j * _nx + i] = float(terrain.call("height_at", i * GRID, j * GRID))
	_slope.resize(_hv.size())
	for j in range(1, _nz - 1):
		for i in range(1, _nx - 1):
			var gx := (_hv[j * _nx + i + 1] - _hv[j * _nx + i - 1]) / (2.0 * GRID)
			var gz := (_hv[(j + 1) * _nx + i] - _hv[(j - 1) * _nx + i]) / (2.0 * GRID)
			_slope[j * _nx + i] = rad_to_deg(atan(Vector2(gx, gz).length()))


## The 2.5D's scenery, the story's obstacles and the story's actors stand on the new ground.
func _on_new_ground(zone: Node, terrain: Node3D) -> void:
	var scatter: Node = zone.get("scatter")
	var worst := 0.0
	var placed := 0
	for kind: String in scatter.call("counts"):
		for it: Array in scatter.call("placed", kind):
			var at: Vector3 = it[0]
			worst = maxf(worst, absf(at.y - float(terrain.call("height_at", at.x, at.z))))
			placed += 1
	_check("the scenery stands on the new ground (none buried, none floating)", worst < 0.01, "%d objets, écart max %.3f m" % [placed, worst])
	var story: Node = zone.get("blockers").get("story")
	var obstacles: Dictionary = story.get("obstacles") if story else {}
	worst = 0.0
	for id: String in obstacles:
		var at: Vector3 = obstacles[id]["at"]
		worst = maxf(worst, absf(at.y - float(terrain.call("height_at", at.x, at.z))))
	_check("…the story's obstacles too (tronc, rocher, porte, Crâne, gué)", obstacles.size() == 5 and worst < 0.01, "%s, écart max %.3f m" % [obstacles.keys(), worst])
	var world: Node = load(STORY_WORLD).new()
	world.set("zone", zone)
	zone.add_child(world)
	var src: RefCounted = zone.get("source")
	var s: float = src.get("scale")
	worst = 0.0
	var deepest := 0.0
	var actors := 0
	for a: Dictionary in _layout["anchors"]:
		var olds: Array = [a["old"]] if a.has("old") else []
		olds.append_array(a.get("old_points", []))
		for old: Array in olds:
			var px := Vector2(float(old[0]), float(old[1])) / s * 48.0
			var at: Vector3 = world.call("to_3d", px)
			var ground := float(terrain.call("height_at", at.x, at.z))
			worst = maxf(worst, absf(at.y - ground))
			deepest = minf(deepest, float((src.call("to_3d", px) as Vector3).y) - ground)
			actors += 1
	world.queue_free()
	_check("the story's actors are put on the new ground (StoryWorld3D.to_3d), at their places", actors > 60 and worst < 0.001,
		"%d places, écart max %.4f m (la hauteur du 2,5D les mettait jusqu'à %.1f m sous le sol)" % [actors, worst, -deepest])


## The relief's water: its sea at 0 m and its pond at 2.4 m, each its own sheet; the ru and the
## source's rill as Waterways rivers; no water left of the 2.5D's pond (now under the parvis); deep
## water stops her, the ford's shoal and the islet as the plan has them.
func _water_check(zone: Node, terrain: Node3D) -> void:
	var levels: Array = (terrain.get("waters") as Array).map(func(w: Node3D) -> float: return snappedf(w.position.y, 0.01))
	levels.sort()
	_check("the water of the relief: the sea's sheet at 0 m, the pond's at 2.4 m", levels == [0.0, 2.4], "%s" % [levels])
	var brooks: Array = terrain.get("brooks")
	var meshed := brooks.filter(func(r: Node) -> bool:
		var m: MeshInstance3D = r.get("mesh_instance")
		return m != null and m.mesh != null and m.mesh.get_surface_count() > 0)
	_check("…the ru and the source's rill as Waterways rivers", brooks.size() == 2 and meshed.size() == 2, "%d rivières, %d maillées" % [brooks.size(), meshed.size()])
	var ghost := 0
	for shape: Node3D in zone.get("blockers").get("water").get_children():
		if Vector2(shape.position.x, shape.position.z).distance_to(Vector2(158, 96)) < 12.0:
			ghost += 1
	var dry := float(terrain.call("water_depth_at", 158.0, 96.0))
	_check("…no water left of the 2.5D's pond (158, 96: the parvis now)", ghost == 0 and dry <= 0.0, "%d mur(s) d'eau, eau %.2f m" % [ghost, maxf(dry, 0.0)])
	var space := (zone as Node3D).get_world_3d().direct_space_state
	var deep := []
	for p: Vector2 in [Vector2(128, 123), Vector2(20, 170)]:
		var q := PhysicsPointQueryParameters3D.new()
		q.position = Vector3(p.x, float(terrain.call("height_at", p.x, p.y)) + 1.0, p.y)
		q.collision_mask = 16
		deep.append(not space.intersect_point(q, 1).is_empty())
	_check("…deep water stops her (the pond's middle, the crique)", deep == [true, true], "%s" % [deep])
	var ford := float(terrain.call("water_depth_at", 134.0, 119.0))
	var islet := float(terrain.call("water_depth_at", 134.0, 124.0))
	_check("…the ford's shoal shallow (walked once it opens), the islet dry", ford > 0.0 and ford < 0.3 and islet <= 0.0, "gué %.2f m d'eau, îlot %.2f" % [ford, islet])


## The Terrain3D ground's collision (left out of the walk's queries: the slopes are the relief's).
func _ground_rid(terrain: Node3D) -> RID:
	var ground: Node = terrain.get("ground3d")
	var t3d: Object = ground.get("terrain") if ground else null
	var col: Object = t3d.get("collision") if t3d else null
	if col and col.has_method("get_rid"):
		return col.call("get_rid")
	return RID()


## 1 where nothing of the game's collisions (the world and the water, the ground left out) stands
## within `radius` between her knee and her head; the zone's rim closed. `known`: vertices known free.
func _free_grid(space: PhysicsDirectSpaceState3D, ground: RID, radius: float, known := PackedByteArray()) -> PackedByteArray:
	var params := PhysicsShapeQueryParameters3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = HEAD_M - KNEE_M
	params.shape = cyl
	params.collision_mask = WORLD_AND_WATER
	if ground.is_valid():
		params.exclude = [ground]
	var free := PackedByteArray()
	free.resize(_nx * _nz)
	for j in _nz:
		for i in _nx:
			var k := j * _nx + i
			if i == 0 or j == 0 or i == _nx - 1 or j == _nz - 1:
				continue
			if not known.is_empty() and known[k]:
				free[k] = 1
				continue
			params.transform = Transform3D(Basis.IDENTITY, Vector3(i * GRID, _hv[k] + (KNEE_M + HEAD_M) * 0.5, j * GRID))
			free[k] = 1 if space.intersect_shape(params, 1).is_empty() else 0
	return free


## Reachable vertices from `start` (tools/test_relief_plaines.gd's walk): between free vertices, up
## what she can stand on (46°), and down anything (she steps off an edge, slides to its foot).
func _reach(free: PackedByteArray, start: Vector2) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(free.size())
	var s := _nearest_free(free, start)
	if s < 0:
		return seen
	var climb := tan(deg_to_rad(STAND_DEG))
	var queue := PackedInt32Array([s])
	seen[s] = 1
	var head := 0
	var steps := [[1, 0, GRID], [-1, 0, GRID], [0, 1, GRID], [0, -1, GRID], [1, 1, GRID * 1.4142], [1, -1, GRID * 1.4142], [-1, 1, GRID * 1.4142], [-1, -1, GRID * 1.4142]]
	while head < queue.size():
		var k := queue[head]
		head += 1
		var i := k % _nx
		@warning_ignore("integer_division")
		var j := k / _nx
		var steep_here := _slope[k] > STAND_DEG
		for st: Array in steps:
			var ii: int = i + st[0]
			var jj: int = j + st[1]
			if ii < 0 or jj < 0 or ii >= _nx or jj >= _nz:
				continue
			var n := jj * _nx + ii
			if seen[n] or not free[n]:
				continue
			var rise := _hv[n] - _hv[k]
			var fine := rise < 0.0 if (steep_here or _slope[n] > STAND_DEG) else rise <= climb * float(st[2])
			if fine:
				seen[n] = 1
				queue.append(n)
	return seen


## Reached near `at`: a vertex within `near` vertices (3 m) on about its own level (not the rim of a
## wall above it).
func _reached(seen: PackedByteArray, at: Vector2, near := 6) -> bool:
	var i0 := roundi(at.x / GRID)
	var j0 := roundi(at.y / GRID)
	var own := _hv[clampi(j0, 0, _nz - 1) * _nx + clampi(i0, 0, _nx - 1)]
	for j in range(maxi(j0 - near, 0), mini(j0 + near, _nz - 1) + 1):
		for i in range(maxi(i0 - near, 0), mini(i0 + near, _nx - 1) + 1):
			if seen[j * _nx + i] and absf(_hv[j * _nx + i] - own) < 1.0 and Vector2(i - i0, j - j0).length() <= near:
				return true
	return false


func _nearest_free(free: PackedByteArray, at: Vector2) -> int:
	var i0 := roundi(at.x / GRID)
	var j0 := roundi(at.y / GRID)
	for r in 12:
		for j in range(j0 - r, j0 + r + 1):
			for i in range(i0 - r, i0 + r + 1):
				if i >= 0 and j >= 0 and i < _nx and j < _nz and free[j * _nx + i] and _slope[j * _nx + i] <= STAND_DEG:
					return j * _nx + i
	return -1


## Every path of the plan, passages open: 1.2 m clear all along — at each point, room for a body
## 1.2 m wide (PASSAGE_R) somewhere across the path's own width, nothing of the game's collisions in it
## between her knee and her head.
func _path_clearance(space: PhysicsDirectSpaceState3D, ground: RID) -> void:
	var params := PhysicsShapeQueryParameters3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = PASSAGE_R
	cyl.height = HEAD_M - KNEE_M
	params.shape = cyl
	params.collision_mask = WORLD_AND_WATER
	if ground.is_valid():
		params.exclude = [ground]
	var narrow: Array[String] = []
	var samples := 0
	for p: Dictionary in _layout["paths"]:
		var line: Array = _path(p["id"])
		var first := Vector2.INF
		var n := 0
		for i in line.size() - 1:
			var a: Vector2 = line[i]
			var b: Vector2 = line[i + 1]
			var steps := maxi(1, ceili(a.distance_to(b) / GRID))
			for k in steps:
				var q := a.lerp(b, float(k) / steps)
				if q.x <= 1.0 or q.y <= 1.0 or q.x >= (_nx - 1) * GRID - 1.0 or q.y >= (_nz - 1) * GRID - 1.0:
					continue   # (the zone's edges: its ways out come later)
				samples += 1
				if not _room_across(space, params, q, (b - a).normalized(), float(p["width_m"]) * 0.5):
					n += 1
					if first == Vector2.INF:
						first = q
		if n > 0:
			narrow.append("%s (%d, vers %s)" % [p["id"], n, first])
	_check("passages open, every path of the plan is 1.2 m clear all along", narrow.is_empty(), "%d points, étroits : %s" % [samples, narrow])


## Room for the query's body at `q` or across the path from it (up to `half` either side).
func _room_across(space: PhysicsDirectSpaceState3D, params: PhysicsShapeQueryParameters3D, q: Vector2, way: Vector2, half: float) -> bool:
	var across := Vector2(-way.y, way.x)
	var terrain: Node3D = _demo.get("terrain")
	var offset := 0.0
	while offset <= half + 0.001:
		for side in ([0.0] if offset == 0.0 else [-1.0, 1.0]):
			var c: Vector2 = q + across * offset * float(side)
			params.transform = Transform3D(Basis.IDENTITY, Vector3(c.x, float(terrain.call("height_at", c.x, c.y)) + (KNEE_M + HEAD_M) * 0.5, c.y))
			if space.intersect_shape(params, 1).is_empty():
				return true
		offset += 0.25
	return false


## The width of each passage once open: from its middle, across its way, until something of the game
## stops her or the ground rises or falls away (a wall of the relief). 1.2 m at the least; the plan's 4 m said.
func _door_widths(space: PhysicsDirectSpaceState3D, ground: RID) -> void:
	var terrain: Node3D = _demo.get("terrain")
	var params := PhysicsShapeQueryParameters3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.05
	cyl.height = HEAD_M - KNEE_M
	params.shape = cyl
	params.collision_mask = WORLD_AND_WATER
	if ground.is_valid():
		params.exclude = [ground]
	var widths: Array[String] = []
	var narrow: Array[String] = []
	var tight: Array[String] = []
	for door: Array in DOORS:
		var at: Vector2 = door[1]
		var way: Vector2 = terrain.call("path_way_at", at.x, at.y)
		var across: Vector2 = door[2] if door[2] != Vector2.ZERO else (Vector2(-way.y, way.x) if way != Vector2.ZERO else Vector2.RIGHT)
		var own := float(terrain.call("height_at", at.x, at.y))
		var width := 0.0
		for side in [-1.0, 1.0]:
			var d := 0.0
			while d < 12.0:
				var p: Vector2 = at + across * float(side) * (d + 0.1)
				var h := float(terrain.call("height_at", p.x, p.y))
				params.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, h + (KNEE_M + HEAD_M) * 0.5, p.y))
				if absf(h - own) > 1.0 or _slope_at(p) > STAND_DEG or not space.intersect_shape(params, 1).is_empty():
					break
				d += 0.1
			width += d
		widths.append("%s %.1f m" % [door[0], width])
		if width < PASSAGE_R * 2.0:
			narrow.append(door[0])
		elif width < DOOR_M - 0.25:
			tight.append("%s %.1f m" % [door[0], width])
	print("MESURE  largeur des passages ouverts : %s" % ", ".join(widths))
	_check("…each passage at least 1.2 m wide once open", narrow.is_empty(), "%s" % [narrow])
	if not tight.is_empty():
		print("SIGNALÉ  passages sous les 4 m du plan : %s" % ", ".join(tight))


func _slope_at(p: Vector2) -> float:
	return _slope[clampi(roundi(p.y / GRID), 0, _nz - 1) * _nx + clampi(roundi(p.x / GRID), 0, _nx - 1)]


## Opens (or closes again) every passage as the game would: the flags set, the night of a full moon.
func _passages(open: bool) -> void:
	var game := root.get_node("Game")
	_demo.call("place", &"DepuisPort")   # (off the ford: it never closes under her)
	if open:
		_was = {"day": game.get("day"), "clock": game.get("clock")}
		game.set("day", FULL_MOON_DAY)
		game.set("clock", 22.0 * 60.0)
	else:
		game.set("day", _was.get("day", 1))
		game.set("clock", _was.get("clock", 10.0 * 60.0))
	for f in PASSAGE_FLAGS:
		game.call("set_flag", f, open)
	for u: Array in USES:   # (the provisional rule's own flags: off again)
		game.call("set_flag", StringName(PROVISIONAL % u[0]), false)
	await create_timer(0.8).timeout   # (the moon is looked at twice a second)
	await physics_frame
	await physics_frame
	var story: Node = _demo.get("blockers").get("story")
	var states := {}
	for id: String in story.get("obstacles"):
		states[id] = story.call("is_open", id)
	_check("the passages %s (%s)" % ["open" if open else "close again", "drapeaux posés, pleine lune" if open else "drapeaux ôtés, jour"],
		states.values().all(func(v: bool) -> bool: return v == open), "%s" % [states])


## Chloé runs where the 2.5D's rules had cut her off (the dinos out of her way for it).
func _walks(zone: Node) -> void:
	var layers := {}
	for d: Node in zone.get("dinos"):
		if is_instance_valid(d):
			layers[d] = d.get("collision_layer")
			d.set("collision_layer", 0)
	await _run_along("Chloé runs the corridor of passage 3, from the carrefour to the gorge", _path("route_corridor"))
	await _run_along("…the sente of the pond's south shore", _path("sente_rive_sud"))
	var east: Array = _path("sente_est").slice(0, 7)
	east.append_array(_path("sente_eboulis").slice(1))
	await _run_along("…the east: the foot of the rempart, the éboulis", east)
	await _run_along("…the spur to the cascade", _path("sente_cascade"))
	for d: Node in layers:
		if is_instance_valid(d):
			d.set("collision_layer", layers[d])


## Chloé runs into each closed obstacle (HELD): she stays on her side of it.
func _held_back(zone: Node) -> void:
	var terrain: Node3D = zone.get("terrain")
	var through: Array[String] = []
	var report: Array[String] = []
	for h: Array in HELD:
		var from: Vector2 = h[1]
		var to: Vector2 = h[2]
		var at: Vector2 = h[3]
		var dir := (to - from).normalized()
		_player.call("place_at", Vector3(from.x, float(terrain.call("height_at", from.x, from.y)) + 0.3, from.y), 0.0)
		_pivot.call("set_view", rad_to_deg(atan2(-dir.x, -dir.y)), -18.0, 5.0)
		await create_timer(0.3).timeout
		Input.action_press(&"run")
		Input.action_press(&"move_up")
		var t0 := Time.get_ticks_msec()
		var furthest := -INF
		while Time.get_ticks_msec() - t0 < int((from.distance_to(to) / 5.0 + 1.5) * 1000.0):
			var here := _player.global_position
			var aim := to - Vector2(here.x, here.z)
			_pivot.call("set_view", rad_to_deg(atan2(-aim.x, -aim.y)), -18.0, 5.0)
			await physics_frame
			furthest = maxf(furthest, (Vector2(_player.global_position.x, _player.global_position.z) - at).dot(dir))
		Input.action_release(&"move_up")
		Input.action_release(&"run")
		await create_timer(0.2).timeout
		report.append("%s %+.1f m" % [h[0], furthest])
		if furthest > 0.0:
			through.append(h[0])
	_check("passages closed, Chloé herself runs into each obstacle and stays on her side (tronc, rocher, porte, sceau, gué)", through.is_empty(),
		"passée : %s ; au plus loin, par rapport au milieu de l'obstacle : %s" % [through, ", ".join(report)])
	var inside: Array[String] = []
	var stops: Array[String] = []
	for c: Array in CHEEKS:
		var end: Vector3 = await _try_route(c[1], 4.0)
		var goal: Vector2 = c[2]
		stops.append("%s (%.1f, %.1f)" % [c[0], end.x, end.z])
		if Vector2(end.x, end.z).distance_to(goal) < 2.5:
			inside.append(c[0])
	_check("…nor gets round the jaw, under the Crâne's cheeks, into its mouth", inside.is_empty(), "arrêtée en %s" % ", ".join(stops))


## The provisional rule (StoryObstacles3D, RÈGLE PROVISOIRE): Chloé, in front of each closed obstacle,
## uses it (E) and it opens — by the 2.5D's rule if her team can, else provisionally.
const USES := [["tronc_tranche", Vector2(58, 86), Vector2(-0.6, -0.8), 1.7], ["rocher_charge", Vector2(116, 49.2), Vector2(0, -1), 2.4],
	["porte_ambre", Vector2(190, 64), Vector2(0, -1), 1.6], ["grand_crane", Vector2(172, 103.9), Vector2(0, -1), 1.3]]

func _provisional_use(zone: Node) -> void:
	var terrain: Node3D = zone.get("terrain")
	var story: Node = zone.get("blockers").get("story")
	var dialogue := root.get_node("Dialogue")
	var game := root.get_node("Game")
	var report: Array[String] = []
	var shut: Array[String] = []
	for u: Array in USES:
		var id: String = u[0]
		var dir: Vector2 = u[2]
		var at: Vector2 = (u[1] as Vector2) - dir.normalized() * float(u[3])
		_player.call("place_at", Vector3(at.x, float(terrain.call("height_at", at.x, at.y)) + 0.1, at.y), atan2(dir.x, dir.y))
		_pivot.call("set_view", rad_to_deg(atan2(-dir.x, -dir.y)), -18.0, 5.0)
		await create_timer(0.6).timeout
		var it: Node = _player.call("nearest_interactable")
		var found := it != null and String(it.name) == "Utiliser_%s" % id
		_press(&"interact")
		await create_timer(0.6).timeout
		var presses := 0
		while dialogue.get("active") and presses < 15:
			_press(&"interact")
			presses += 1
			await create_timer(0.5).timeout
		await create_timer(0.4).timeout
		var how := "provisoire" if game.call("flag", StringName(PROVISIONAL % id)) else ("règle du 2,5D" if story.call("is_open", id) else "fermé")
		report.append("%s : %s%s" % [id, how, "" if found else " (pas à portée)"])
		if not story.call("is_open", id) or not found:
			shut.append(id)
	_check("the provisional rule: Chloé uses each closed passage (E) and it opens (tronc, rocher, porte, Crâne)", shut.is_empty(), ", ".join(report))


## Chloé runs along `points` (giving up on a leg after `leg_s`); where she ends.
func _try_route(points: Array, leg_s: float) -> Vector3:
	var terrain: Node3D = _demo.get("terrain")
	var start: Vector2 = points[0]
	_player.call("place_at", Vector3(start.x, float(terrain.call("height_at", start.x, start.y)) + 0.3, start.y), 0.0)
	await create_timer(0.3).timeout
	Input.action_press(&"move_up")
	for target: Vector2 in points.slice(1):
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < int(leg_s * 1000.0):
			var here := _player.global_position
			var to := target - Vector2(here.x, here.z)
			if to.length() < 0.6:
				break
			_pivot.call("set_view", rad_to_deg(atan2(-to.x, -to.y)), -18.0, 5.0)
			await physics_frame
	Input.action_release(&"move_up")
	await create_timer(0.2).timeout
	return _player.global_position


## Chloé runs along `points` from the first (the camera turned towards the next one): she gets to
## each, on the ground (tools/test_relief_plaines.gd's walk).
func _run_along(what: String, points: Array) -> void:
	var terrain: Node3D = _demo.get("terrain")
	var start: Vector2 = points[0]
	_player.call("place_at", Vector3(start.x, float(terrain.call("height_at", start.x, start.y)) + 0.3, start.y), 0.0)
	await create_timer(0.4).timeout
	Input.action_press(&"run")
	Input.action_press(&"move_up")
	var reached := 0
	var stuck_at := Vector3.INF
	var t0 := Time.get_ticks_msec()
	for target: Vector2 in points.slice(1):
		var leg_t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - leg_t0 < 25000:
			var here := _player.global_position
			var to := target - Vector2(here.x, here.z)
			if to.length() < 1.6:
				break
			_pivot.call("set_view", rad_to_deg(atan2(-to.x, -to.y)), -18.0, 5.0)
			await physics_frame
		var at := _player.global_position
		if (target - Vector2(at.x, at.z)).length() >= 1.6:
			stuck_at = at
			break
		reached += 1
	Input.action_release(&"move_up")
	Input.action_release(&"run")
	await create_timer(0.3).timeout
	var feet := absf(_player.global_position.y - float(terrain.call("height_at", _player.global_position.x, _player.global_position.z)))
	_check(what, reached == points.size() - 1 and feet < 0.2, "%d points sur %d en %.1f s%s" % [reached, points.size() - 1, (Time.get_ticks_msec() - t0) / 1000.0,
		"" if stuck_at == Vector3.INF else ", arrêtée en (%.1f, %.1f)" % [stuck_at.x, stuck_at.z]])


## The four views of the remodelled Prairie, at 10 h in clear weather, passages closed.
func _views(zone: Node) -> void:
	var game := root.get_node("Game")
	game.set("clock", 10.0 * 60.0)
	game.call("set_weather", &"clear")
	var weather: Node = zone.get("weather")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() < t0 + 12000 and not (float(weather.get("rain_amount")) < 0.01 and float(weather.get("mist_amount")) < 0.01 and float(weather.get("storm_amount")) < 0.01):
		await process_frame
	await create_timer(2.0).timeout
	var terrain: Node3D = zone.get("terrain")
	for v: Dictionary in VIEWS:
		if not _views_only.is_empty() and not String(v["name"]).left(2) in _views_only:
			continue
		var at: Vector2 = v["at"]
		var look: Vector2 = (v["look"] as Vector2).normalized()
		var yaw := rad_to_deg(atan2(-look.x, -look.y))
		_player.call("place_at", Vector3(at.x, float(terrain.call("height_at", at.x, at.y)) + 0.05, at.y), deg_to_rad(yaw + 180.0))
		_pivot.call("set_view", yaw, v["pitch"], v["dist"])
		_pivot.call("snap")
		await create_timer(1.2).timeout
		await _shot(v["name"])
		print("IMAGE  %s" % ProjectSettings.globalize_path(_out.path_join("%s.png" % v["name"])))


## The plan's anchors at their new places: [{id, at}] (a group's points as id[k]).
func _anchors() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for a: Dictionary in _layout["anchors"]:
		if a.has("new"):
			out.append({"id": a["id"], "at": Vector2(float(a["new"][0]), float(a["new"][1]))})
		elif a.has("new_points"):
			for k in (a["new_points"] as Array).size():
				out.append({"id": "%s[%d]" % [a["id"], k], "at": Vector2(float(a["new_points"][k][0]), float(a["new_points"][k][1]))})
	return out


func _anchor(id: String) -> Vector2:
	for a in _anchors():
		if a["id"] == id:
			return a["at"]
	return Vector2(120, 176.4)


## A path of the plan, its points (Vector2).
func _path(id: String) -> Array:
	for p: Dictionary in _layout["paths"]:
		if p["id"] == id:
			return (p["points"] as Array).map(func(q: Array) -> Vector2: return Vector2(float(q[0]), float(q[1])))
	return []


## Phase 5: the game in the 3D Prairie — a new game (Vif), the game's HUD, Vif walking with Chloé,
## the day and the night (the 2.5D's light), the dinos of the time of day (Parasaurolophus by day),
## a raptor met at night starting the game's own battle (left by running away), the save keeping
## Chloé's place in the 2.5D's units.
func _phase5() -> void:
	_caption("Phase 5 — la boucle de jeu : partie, HUD, compagnon, jour/nuit, rencontre, combat, sauvegarde")
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
	_check("the night falls (Sky3D, at the game's hour)", night < day * 0.5, "soleil %.2f → %.2f" % [day, night])
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


## Phase 7 (the Prairie's species): every species of its habitats has a 3D sheet; each is out at its
## time of day as in the 2.5D (Encounter.when); a herd keeps together; the plant-eaters graze; one
## of a herd run at sets the others off; a picture of each species close up.
const PRAIRIE := [&"velociraptor", &"parasaurolophus", &"compsognathus", &"psittacosaurus", &"dimorphodon", &"ankylosaurus"]


func _phase7() -> void:
	_caption("Phases 6-7 — la Prairie peuplée : espèces du moment, troupeaux qui broutent, fuite groupée")
	var zone := _demo
	var game := root.get_node("Game")
	_quiet(zone)
	var sheets := PRAIRIE.filter(func(id: StringName) -> bool: return ResourceLoader.exists("res://world3d/creatures/species/%s.tres" % id))
	_check("every species of the Prairie has its 3D sheet", sheets.size() == PRAIRIE.size(), "%s" % [sheets])
	var seen := {}
	for hour in [13.0, 6.2, 22.5]:   # day, dawn, night
		game.set("clock", hour * 60.0)
		await create_timer(0.8).timeout
		zone.call("respawn_dinos")
		_quiet(zone)
		await create_timer(0.5).timeout
		var out := {}
		for d in zone.get("dinos"):
			out[d.get("species").get("id")] = true
		print("     %02d h (%s) : %s" % [int(hour), game.call("phase"), out.keys()])
		for id in out:
			seen[id] = true
	_check("each is out at some time of day (the 2.5D's habitats)", seen.size() == sheets.size(), "%s" % [seen.keys()])
	# by day: a herd of Parasaurolophus
	game.set("clock", 13.0 * 60.0)
	await create_timer(0.8).timeout
	zone.call("respawn_dinos")
	_quiet(zone)
	var herd: Array = []
	for d in zone.get("dinos"):
		if d.get("species").get("id") == &"parasaurolophus" and (d.get("herd") as Array).size() > 1:
			herd = d.get("herd")
			break
	_check("the Parasaurolophus live in herds", herd.size() > 1, "%d" % herd.size())
	if herd.size() > 1:
		var grazed := false
		var spread := 0.0
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() < t0 + 25000:
			await create_timer(0.25).timeout
			for m in herd:
				grazed = grazed or m.call("state") == &"graze"
			spread = maxf(spread, (herd[0] as Node3D).global_position.distance_to((herd[1] as Node3D).global_position))
		_check("…they graze now and then", grazed, "")
		_check("…and keep together", spread < 20.0, "jusqu'à %.1f m l'un de l'autre" % spread)
		var lead: Node3D = herd[0]
		_player.call("place_at", lead.global_position + Vector3(0, 0.3, -9.0), 0.0)
		_pivot.call("set_view", 180.0, -18.0, 8.0)
		await create_timer(0.5).timeout
		Input.action_press(&"run")
		Input.action_press(&"move_up")
		var all_ran := false
		t0 = Time.get_ticks_msec()
		while Time.get_ticks_msec() < t0 + 4000 and not all_ran:
			await physics_frame
			all_ran = herd.all(func(m: Node) -> bool: return m.call("state") == &"flee")
		Input.action_release(&"move_up")
		Input.action_release(&"run")
		_check("run at one, the whole herd runs off", all_ran, "%s" % [herd.map(func(m: Node) -> StringName: return m.call("state"))])
		await _shot("50_troupeau_fuit")
	# a picture of each species, close up, by its time of day
	for hour in [13.0, 6.2, 22.5]:
		game.set("clock", hour * 60.0)
		await create_timer(0.8).timeout
		zone.call("respawn_dinos")
		_quiet(zone)
		await create_timer(0.6).timeout
		var shown := {}
		for d in zone.get("dinos"):
			var id: StringName = d.get("species").get("id")
			if shown.has(id) or FileAccess.file_exists(_out.path_join("51_%s.png" % id)):
				continue
			shown[id] = true
			d.set_physics_process(false)
			var size: float = maxf(float(d.get("length_m")), 1.0)
			_player.call("place_at", d.global_position + Vector3(size * 0.6 + 1.0, 0.3, -1.5), -PI * 0.5)
			_pivot.set("target", d)
			_pivot.call("set_view", 70.0, -10.0, clampf(size * 1.4 + 2.0, 3.5, 12.0))
			_pivot.call("snap")
			await create_timer(0.7).timeout
			await _shot("51_%s" % id)
			_pivot.set("target", _player)
			d.set_physics_process(true)


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


## What this run tests, written on the view and left there (Greg, 04/10): one caption for the
## whole phase, not one per shot — those went by too fast to read.
func _caption(text: String) -> void:
	if _caption_layer:
		_caption_layer.queue_free()
	_caption_layer = ShotCaption.show_on(self, text)
