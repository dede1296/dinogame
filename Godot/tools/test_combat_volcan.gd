extends SceneTree
## Les combats de la Plaine Volcanique (chapitre 8) : (a) le volcan à l'écran (BattleVolcan) : dans ses cinq
## zones (ou la règle « volcan »), pas ailleurs ; son fond (volcan.jpg, ou un repli réchauffé), les braises ;
## (b) les combats de l'histoire (VolcanBattles) : l'équipe de Brac (Cabosse, Grognon, Mastoc, puis Fournaise
## corrompu, apaisement long), les corrompus numérotés, le T-Rex de Magma (niv. 48, Feu, combat d'honneur) et
## sa leçon, vraie sur la table des types ; (c) l'antidote (« Ambre clair ») : seulement dans le dernier combat
## (règle « antidote »), sur un corrompu, une dose : les veines s'effacent d'un coup, le corrompu n'agit pas ;
## (d) l'équilibrage (le moteur réel, 120 combats par cas) : le T-Rex contre une équipe de 45, Brac contre une
## équipe de 44 ; (e) à l'écran : le T-Rex aux coulées (capture), puis Fournaise apaisé par l'antidote au Sac.
##   godot --path Godot --script res://tools/test_combat_volcan.gd --resolution 1600x900 -- out=<dossier> [titre=…]
## (Script compilé avant les autoloads : le combat et les dinos sont chargés par leur chemin.)

const CAPTION := "Combats du Volcan : fond et braises, Brac et Fournaise, T-Rex de Magma niv. 48 (leçon vraie), antidote au dernier combat, équilibrage"
const SCENE := "res://battle/battle_scene.gd"
const LOOK := "res://battle/battle_volcan.gd"
const BATTLES := "res://battle/volcan_battles.gd"
const ENGINE := "res://battle/battle_engine.gd"
const DINO := "res://game/dino.gd"
const MOVES := "res://data/moves_db.gd"
const RUNS := 120

var _out := "user://test_combat_volcan"
var _caption := CAPTION
var _failed := 0
var _game: Node
var _dino
var _battles


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("titre="):
			_caption = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	var banner := ShotCaption.show_on(self, _caption)
	root.get_node("Save").set("path", "user://test_combat_volcan_save.json")
	_game = root.get_node("Game")
	_game.call("new_game")
	_game.call("set_flag", &"prologue_done")
	_game.call("set_flag", &"tuto_commandes")
	_dino = load(DINO)
	_battles = load(BATTLES)
	_look_rules()
	_story_battles()
	_antidote()
	_balance()
	await _screen()
	banner.queue_free()
	print("TEST combats du Volcan : %s (%d échec(s))" % ["OK" if _failed == 0 else "ÉCHEC", _failed])
	quit(1 if _failed else 0)


# ------------------------------------------------------------------ (a) le volcan à l'écran

func _look_rules() -> void:
	print("— (a) le volcan")
	var look = load(LOOK)
	var all := [&"champs_cendres", &"forges_ombre", &"coulees_lave", &"sanctuaire_magma", &"porte_cratere"]
	_check("ses cinq zones sont au volcan", all.all(func(z: StringName) -> bool: return look.applies({}, z)))
	_check("ailleurs non (Cieux) ; la règle « volcan » force ou coupe", not look.applies({}, &"cieux")
		and look.applies({"volcan": true}, &"monts") and not look.applies({"volcan": false}, &"coulees_lave"))
	var pick: Array = look.backdrop()
	var own := ResourceLoader.exists(look.BACKDROP)
	_check("son fond : %s" % ("volcan.jpg" if own else "repli réchauffé (volcan.jpg pas encore livré)"), pick[0] is Texture2D
		and (pick[0].resource_path == look.BACKDROP) == own)


# ------------------------------------------------------------------ (b) les combats de l'histoire

func _story_battles() -> void:
	print("— (b) Brac, les numéros, le T-Rex")
	var team: Array = _battles.brac_team()
	var names: Array = team.map(func(m: Array) -> String: return m[2])
	_check("l'équipe de Brac : Cabosse, Grognon, Mastoc, puis Fournaise", names == ["Cabosse", "Grognon", "Mastoc", "Fournaise"], str(names))
	var last: Dictionary = team[3][3]
	_check("Fournaise : Daspletosaurus corrompu, apaisement long, la leçon « il s'apaise »", team[3][0] == &"daspletosaurus"
		and last.get("corrupted", false) and last.get("long_calm", false) and String(last["lesson"][0]).contains("s'apaise"))
	_check("niveaux 43, 43, 44, 45 (simulés)", team.map(func(m: Array) -> int: return m[1]) == [43, 43, 44, 45])
	_check("chacun a sa réplique de Brac avant d'entrer", team.all(func(m: Array) -> bool: return (m[3] as Dictionary).has("before")))
	var f = _battles.fournaise()
	_check("Fournaise rejoint Chloé : Daspletosaurus niv. 45, un cœur, Cuir de feu", f.nickname == "Fournaise" and f.level == 45
		and f.bond == 1 and load("res://data/abilities.gd").usable(f, &"cuir_de_feu"))
	for n in [3, 7, 11, 12]:
		var d = _battles.numero(n)
		_check("Numéro %d : %s niv. %d, corrompu, pas de collier" % [n, d.species().display_name, d.level], d.corrupted
			and not _battles.numero_rules(n).get("catch", true))
	var trex = _battles.trex()
	var rules: Dictionary = _battles.trex_rules()
	_check("le T-Rex de Magma : niv. 48, Feu, combat d'honneur, taille ×1,2", trex.level == 48 and trex.type() == "feu"
		and not rules["catch"] and not rules["run"] and is_equal_approx(rules["size"], 1.2) and rules.has("music"))
	var moves = load(MOVES)
	var lesson := " ".join(rules["lesson"])
	var strong: Array = ["eau", "terre"].filter(func(t: String) -> bool: return moves.effectiveness(t, "feu") > 1.0)
	var hurt: Array = ["vent", "nature"].filter(func(t: String) -> bool: return moves.effectiveness("feu", t) > 1.0)
	var hold: Array = ["pierre", "eau"].filter(func(t: String) -> bool: return moves.effectiveness("feu", t) < 1.0)
	_check("sa leçon est vraie : l'Eau et la Terre le touchent fort", strong.size() == 2 and lesson.contains("l'Eau et la Terre le touchent fort"))
	_check("…ses flammes brûlent le Vent et la Nature, la Pierre et l'Eau tiennent bon", hurt.size() == 2 and hold.size() == 2
		and lesson.contains("Vent et de Nature") and lesson.contains("la Pierre et l'Eau"))


# ------------------------------------------------------------------ (c) l'antidote

func _antidote() -> void:
	print("— (c) l'antidote")
	var party: Array = _game.get("party")
	party.clear()
	var vif = _dino.create(&"velociraptor", 45, "Vif")
	party.append(vif)
	_game.call("give_item", "antidote_ambre")
	var corrupted = _battles.numero(3)
	var plain = load(ENGINE).new(party, corrupted, {})
	_check("hors du dernier combat : impossible (la dose est gardée)", not plain.can_use_antidote() and plain.turn({"type": "antidote"}).is_empty()
		and _game.call("item_count", "antidote_ambre") == 1)
	var wild = _dino.create(&"styracosaurus", 43)
	var on_wild = load(ENGINE).new(party, wild, {"antidote": true})
	_check("sur un dino qui n'est pas corrompu : impossible", not on_wild.can_use_antidote())
	var foe = _dino.create(&"daspletosaurus", 45, "Fournaise")
	foe.corrupted = true
	var e = load(ENGINE).new(party, foe, {"antidote": true, "long_calm": true})
	var hp_before: int = vif.hp
	_check("le dernier combat, un corrompu, la dose dans le sac : possible", e.can_use_antidote())
	var ev: Array = e.turn({"type": "antidote"})
	var kinds: Array = ev.map(func(x: Dictionary) -> String: return x["type"])
	_check("une goutte : les veines s'effacent d'un coup (apaisé)", e.over and e.result == "calmed" and not foe.corrupted
		and kinds.has("antidote") and kinds.has("calmed"), str(kinds))
	_check("le corrompu n'a pas agi ce tour-là", vif.hp == hp_before and not kinds.has("move"))
	_check("la dose est partie (une seule)", _game.call("item_count", "antidote_ambre") == 0)


# ------------------------------------------------------------------ (d) l'équilibrage

func _balance() -> void:
	print("— (d) l'équilibrage (%d combats par cas, le meilleur coup, jamais de soin)" % RUNS)
	for starter: StringName in [&"velociraptor", &"ankylosaurus", &"parasaurolophus"]:
		var trex := _rate(starter, 45, [[&"trex_magma", 48, "T-Rex de Magma", false, false]])
		var brac := _rate(starter, 44, _battles.brac_team().map(func(m: Array) -> Array:
			return [m[0], m[1], m[2], (m[3] as Dictionary).get("corrupted", false), (m[3] as Dictionary).get("long_calm", false)]))
		_check("%s : T-Rex 48 contre une équipe de 45 : %d %% (difficile, jamais impossible)" % [starter, trex], trex >= 70 and trex <= 100)
		_check("%s : Brac contre une équipe de 44 : %d %%" % [starter, brac], brac >= 70)


## Part de victoires (%) d'une équipe type (départ L, 3e petit L-1, Nessie L-1, Bouée L-2, Ptéro L-2).
func _rate(starter: StringName, lvl: int, foes: Array) -> int:
	var stolen := {&"velociraptor": &"parasaurolophus", &"ankylosaurus": &"velociraptor", &"parasaurolophus": &"ankylosaurus"}
	var rng := RandomNumberGenerator.new()
	rng.seed = 48
	var wins := 0
	for t in RUNS:
		var team: Array[Dino] = []
		var s = _dino.create(starter, lvl, "Départ")
		s.bond = 3
		team.append(s)
		team.append(_dino.create(stolen[starter], lvl - 1))
		team.append(_dino.create(&"plesiosaurus", lvl - 1, "Nessie"))
		team.append(_dino.create(&"baryonyx", lvl - 2, "Bouée"))
		team.append(_dino.create(&"pteranodon", lvl - 2, "Ptéro"))
		var ok := true
		for f: Array in foes:
			var foe = _dino.create(f[0], f[1], f[2])
			foe.corrupted = f[3]
			var e = load(ENGINE).new(team, foe, {"starter": starter, "long_calm": f[4], "trainer": "Brac" if foes.size() > 1 else ""})
			e.rng.seed = rng.randi()
			var turns := 0
			while not e.over and turns < 90:
				turns += 1
				if e.must_switch:
					for i in team.size():
						if e.can_switch_to(i):
							e.turn({"type": "switch", "index": i})
							break
					continue
				if foe.corrupted and foe.hp <= foe.max_hp() / 2:
					e.turn({"type": "calm"})
				else:
					e.turn({"type": "move", "index": _best(e.player(), foe)})
			if e.result != "win" and e.result != "calmed":
				ok = false
				break
		if ok:
			wins += 1
	return roundi(100.0 * wins / RUNS)


func _best(d, foe) -> int:
	var moves = load(MOVES)
	var best := 0
	var best_v := 0.0
	for i in d.moves.size():
		if d.moves[i]["pp"] <= 0:
			continue
		var m: Dictionary = moves.move(d.moves[i]["id"])
		var v: float = m["power"] * m["accuracy"] * (1.25 if m["type"] == d.type() else 1.0) * moves.effectiveness(m["type"], foe.type())
		if v > best_v:
			best_v = v
			best = i
	return best


# ------------------------------------------------------------------ (e) à l'écran

func _screen() -> void:
	print("— (e) à l'écran")
	_game.set("region_id", &"coulees_lave")
	var party: Array = _game.get("party")
	party.clear()
	party.append(_dino.create(&"plesiosaurus", 46, "Nessie"))
	var scene: CanvasLayer = load(SCENE).new()
	root.add_child(scene)
	scene.call("run", _battles.trex(), _battles.trex_rules())
	for i in 18:
		await create_timer(0.25).timeout
		_press(&"interact")
	var backdrop: TextureRect = scene.get("_backdrop")
	var looks: Array = scene.find_children("*", "Control", true, false).filter(func(c: Control) -> bool:
		return c.get_script() != null and c.get_script().resource_path == LOOK)
	_check("aux coulées, le fond du volcan (%s)" % backdrop.texture.resource_path.get_file(), backdrop.texture.resource_path.get_file() in ["volcan.jpg", "desert.jpg"])
	_check("…et les braises qui montent", looks.size() == 1 and looks[0].find_children("*", "CPUParticles2D", true, false).size() > 0)
	await _shot("combat_trex_magma")
	scene.queue_free()
	await process_frame
	# Fournaise, dans le dernier combat (essai) : l'antidote au Sac, choisi comme le ferait un doigt.
	_game.call("give_item", "antidote_ambre")
	var foe = _dino.create(&"daspletosaurus", 45, "Fournaise")
	foe.corrupted = true
	var last: CanvasLayer = load(SCENE).new()
	root.add_child(last)
	var done := [false, ""]
	var runner := func() -> void:
		done[1] = await last.call("run", foe, {"catch": false, "run": false, "antidote": true, "long_calm": true, "trainer": "Brac"})
		done[0] = true
	runner.call()
	var hud = null
	for i in 40:
		await create_timer(0.25).timeout
		hud = last.get("_hud")
		if hud and hud.call("is_open"):
			break
		_press(&"interact")
	_check("le Sac s'ouvre (l'Ambre clair dedans)", hud != null and hud.call("tap", "sac"))
	await create_timer(0.5).timeout
	await _shot("antidote_sac")
	_check("« Ambre clair » se choisit", hud.call("tap", "item:antidote_ambre"))
	for i in 40:
		if done[0]:
			break
		await create_timer(0.25).timeout
		_press(&"interact")
	_check("Fournaise est apaisé d'un coup (%s)" % done[1], done[0] and done[1] == "calmed")
	last.queue_free()


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
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, shot_name])
