extends SceneTree
## Les combats dans le vent des Cieux (chapitre 7) : (a) les règles (SkyEngine) : une attaque Vent frappe
## ×1,25 et une attaque Terre ×0,75 par rapport au même combat ailleurs (mêmes tirages), dit une fois dans le
## combat ; tout combat d'une zone des Cieux est dans le vent, la règle « cieux » le force ou le coupe ;
## (b) à l'écran (BattleSky) : le fond des Cieux, le 1er combat dit ses règles, le Quetzalcoatlus Roi et le
## Pteranodon de Chloé planent au-dessus de leur plateforme, ailes battantes ; la carte d'une attaque Vent porte
## « ▲ au vent ». Une capture du combat contre le Roi.
##   godot --path Godot --script res://tools/test_combat_cieux.gd --resolution 1600x900 -- out=<dossier>
## (Script compilé avant les autoloads : le combat et les dinos sont chargés par leur chemin.)

const CAPTION := "Combats dans le vent (Cieux) : Vent ×1,25, Terre ×0,75, dit une fois ; zones des Cieux ; le Roi et le Pteranodon planent ; ▲ au vent"
const SCENE := "res://battle/battle_scene.gd"
const SKY := "res://battle/sky_engine.gd"
const ENGINE := "res://battle/battle_engine.gd"
const DINO := "res://game/dino.gd"

var _out := "user://test_combat_cieux"
var _failed := 0
var _game: Node
var _dino


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	var banner := ShotCaption.show_on(self, CAPTION)
	_game = root.get_node("Game")
	_game.call("new_game")
	_game.call("set_flag", &"prologue_done")
	_game.call("set_flag", &"tuto_commandes")
	_dino = load(DINO)
	_rules()
	await _screen()
	banner.queue_free()
	print("TEST combats dans le vent : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


# ------------------------------------------------------------------ (a) les règles

func _rules() -> void:
	print("— (a) les règles du vent")
	var sky = load(SKY)
	_check("une zone des Cieux est dans le vent (cieux, nids_geants, arche_du_vent)",
		sky.applies({}, &"cieux") and sky.applies({}, &"nids_geants") and sky.applies({}, &"arche_du_vent"))
	_check("ailleurs, non (Monts) ; la règle « cieux » force ou coupe", not sky.applies({}, &"monts")
		and sky.applies({"cieux": true}, &"monts") and not sky.applies({"cieux": false}, &"cieux"))
	for pair: Array in [["vent", &"pteranodon", 1.25], ["terre", &"triceratops", 0.75], ["eau", &"plesiosaurus", 1.0]]:
		var ratio := _ratio(pair[1], pair[0])
		_check("une attaque %s dans le vent : ×%.2f" % [pair[0], pair[2]], absf(ratio - pair[2]) < 0.03, "×%.3f" % ratio)
	var told := _told_once()
	_check("la règle est dite une fois dans le combat (« Le vent porte le coup »)", told == 1, "%d fois" % told)


## Dégâts moyens d'une attaque du type `kind` (du dino `species`) contre un Tapejara, dans le vent / ailleurs.
func _ratio(species: StringName, kind: String) -> float:
	var sky_total := 0.0
	var plain_total := 0.0
	for i in 60:
		var a := _first_hit(load(SKY), species, kind, i)
		var b := _first_hit(load(ENGINE), species, kind, i)
		sky_total += a
		plain_total += b
	return sky_total / maxf(plain_total, 1.0)


func _first_hit(engine_script, species: StringName, kind: String, seed: int) -> float:
	var d: Dino = _dino.create(species, 40)
	var team: Array[Dino] = [d]
	var e = engine_script.new(team, _dino.create(&"tapejara", 40), {})
	e.rng.seed = seed
	var moves_db = load("res://data/moves_db.gd")
	for i in d.moves.size():
		var mv: Dictionary = moves_db.move(d.moves[i]["id"])
		if mv["type"] == kind and mv["power"] > 0:
			var hit: Dictionary = e.call("_damage", "player", "foe", mv)
			return float(hit["damage"])
	return 0.0


## Un combat d'un Pteranodon contre un Tapejara : combien de fois la règle du vent est dite.
func _told_once() -> int:
	var team: Array[Dino] = [_dino.create(&"pteranodon", 40)]
	var e = load(SKY).new(team, _dino.create(&"tapejara", 40), {})
	e.rng.seed = 3
	var count := 0
	for t in 6:
		if e.over:
			break
		var best := 0
		for i in team[0].moves.size():
			if load("res://data/moves_db.gd").move(team[0].moves[i]["id"])["type"] == "vent" \
					and load("res://data/moves_db.gd").move(team[0].moves[i]["id"])["power"] > 0:
				best = i
		for ev: Dictionary in e.turn({"type": "move", "index": best}):
			if String(ev.get("text", "")).begins_with("Le vent porte le coup"):
				count += 1
	return count


# ------------------------------------------------------------------ (b) à l'écran

func _screen() -> void:
	print("— (b) à l'écran : le Roi")
	_game.set("region_id", &"nids_geants")
	var flags: Dictionary = _game.get("flags")
	flags.erase("combat_cieux_vu")
	var party: Array = _game.get("party")
	party.clear()
	party.append(_dino.create(&"pteranodon", 40, "Ptéro"))
	var scene: CanvasLayer = load(SCENE).new()
	root.add_child(scene)
	var roi = _dino.create(&"quetzalcoatlus", 44, "Quetzalcoatlus Roi")
	scene.call("run", roi, {"catch": false, "run": false, "size": 1.2, "intro": "Le Quetzalcoatlus Roi s'élève et crie !"})
	var lesson_seen := false
	for i in 40:
		await create_timer(0.25).timeout
		var rules: Dictionary = scene.get("_rules")
		if (rules.get("lesson", []) as Array).any(func(l: String) -> bool: return l.contains("dans le vent")):
			lesson_seen = true
		_press(&"interact")
	var engine = scene.get("engine")
	_check("dans les Nids géants, le combat est dans le vent (SkyEngine)", engine != null and engine.get_script().resource_path == SKY)
	_check("le 1er combat dans le vent dit ses règles", lesson_seen and _game.call("flag", &"combat_cieux_vu"))
	var foe: AnimatedSprite2D = scene.get("_foe_sprite")
	var mine: AnimatedSprite2D = scene.get("_player_sprite")
	_check("le Roi plane (ailes battantes, au-dessus de sa plateforme)", String(foe.animation).begins_with("fly") and foe.offset.y < -60.0,
		"%s, %.0f" % [foe.animation, foe.offset.y])
	_check("le Pteranodon de Chloé plane aussi", String(mine.animation).begins_with("fly") or mine.animation == &"attack", "%s" % mine.animation)
	var backdrop: TextureRect = scene.get("_backdrop")
	print("   fond : %s" % (backdrop.texture.resource_path if backdrop.texture else "?"))
	await _show_moves(scene)
	await _shot("combat_cieux_roi")
	scene.queue_free()


## Ouvre la liste des attaques (pour la capture et le « ▲ au vent »).
func _show_moves(scene: CanvasLayer) -> void:
	var hud = scene.get("_hud")
	if hud and hud.has_method("show_panel"):
		hud.call("show_panel", "moves")
		await create_timer(0.6).timeout
		var texts: Array = hud.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
		_check("une carte d'attaque Vent porte « ▲ au vent »", texts.any(func(t: String) -> bool: return t.contains("▲ au vent")))


# ------------------------------------------------------------------ outils

func _press(action: StringName) -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _check(what: String, ok: bool, detail := "") -> void:
	if not ok:
		_failed += 1
	print("%s  %s%s" % ["PASS" if ok else "FAIL", what, "  (%s)" % detail if detail != "" else ""])


func _shot(shot_name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, shot_name])
