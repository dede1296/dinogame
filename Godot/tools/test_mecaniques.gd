extends SceneTree
## Headless checks of the game's mechanics: the Lien (Dino.bond), calming a corrupted dino
## (bonuses, "long_calm"), Coup de crâne, StoryTrigger. Prints each check, quits with 1 on
## a failure:
##   godot --headless --path Godot --script res://tools/test_mecaniques.gd
## The game's scripts are loaded at run time (they need the autoloads, which a --script main
## loop only gets after it is compiled), so everything here is untyped.

const TILE := 48.0
## Scripts touched by the mechanics: each must compile.
const SCRIPTS := [
	"res://game/dino.gd", "res://core/game_state.gd", "res://data/abilities.gd", "res://battle/battle_engine.gd",
	"res://battle/battle_scene.gd", "res://world/obstacle.gd", "res://world/story_trigger.gd",
	"res://tools/zone_builder.gd", "res://ui/dino_card.gd", "res://ui/party_bar.gd", "res://actors/companion.gd",
]
## Battles simulated per case (seeds 1…N): the calm must win every time.
const RUNS := 50
const MAX_TURNS := 80

var _checks := 0
var _failures := 0
var DinoS: GDScript
var EngineS: GDScript
var AbilitiesS: GDScript
var game: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("— Mécaniques : tests headless —")
	for path: String in SCRIPTS:
		var s: GDScript = load(path)
		_check(s != null and s.can_instantiate(), "compile %s" % path)
	DinoS = load("res://game/dino.gd")
	EngineS = load("res://battle/battle_engine.gd")
	AbilitiesS = load("res://data/abilities.gd")
	game = root.get_node_or_null("Game")
	_check(game != null, "autoload Game présent")
	if game == null or _failures > 0:
		_finish()
		return
	_test_bond_save()
	_test_bond_growth()
	_test_game_bond()
	_test_calm_bonus()
	_test_long_calm()
	_test_endure()
	_test_calm_battles()
	_test_coup_crane()
	await _test_bond_display()
	await _test_battle_rules()
	await _test_story_trigger()
	_finish()


func _finish() -> void:
	print("— %d vérifications, %d échec(s) —" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print(("  ok    " if ok else "  ÉCHEC ") + what)


# ------------------------------------------------------------------ the Lien

func _test_bond_save() -> void:
	var d = DinoS.create(&"velociraptor", 8)
	_check(d.bond == 0 and d.bond_points == 0, "Lien à 0 par défaut")
	d.bond = 3
	d.bond_points = 123
	var saved = JSON.parse_string(JSON.stringify(d.to_dict()))   # as in the save file
	var back = DinoS.from_dict(saved)
	_check(back.bond == 3 and back.bond_points == 123, "Lien sauvegardé puis relu (3 ♥, 123 points)")
	var old: Dictionary = saved.duplicate()
	old.erase("bond")
	old.erase("bond_points")
	_check(DinoS.from_dict(old).bond == 0, "vieille sauvegarde sans Lien : 0 ♥")
	saved["bond"] = 9
	_check(DinoS.from_dict(saved).bond == DinoS.MAX_BOND, "Lien relu plafonné à %d" % DinoS.MAX_BOND)


func _test_bond_growth() -> void:
	var d = DinoS.create(&"velociraptor", 8)
	_check(d.gain_bond_points(DinoS.BOND_FIRST - 1) == 0 and d.bond == 0, "599 pas : pas encore de cœur")
	_check(d.gain_bond_points(1) == 1 and d.bond == 1 and d.bond_points == 0, "600 pas : 1 ♥")
	_check(d.bond_to_next() == DinoS.BOND_FIRST + DinoS.BOND_STEP_MORE, "cœur suivant : %d points" % d.bond_to_next())
	var steps := 0
	while d.bond < DinoS.MAX_BOND and steps < 100000:
		d.gain_bond_points(1)
		steps += 1
	_check(d.bond == DinoS.MAX_BOND, "de 1 à 5 ♥ en %d pas (≈ %d min de marche)" % [steps, roundi(steps / 4.3 / 60.0)])
	_check(d.gain_bond_points(1000) == 0 and d.bond == DinoS.MAX_BOND and d.bond_points == 0, "plafonné à 5 ♥")
	var e = DinoS.create(&"velociraptor", 8)
	_check(e.add_hearts(2) == 2 and e.bond == 2, "add_hearts(2) : 2 ♥")
	_check(e.add_hearts(9) == 3 and e.bond == 5, "add_hearts plafonné (3 gagnés)")


func _test_game_bond() -> void:
	game.new_game()
	var starter = game.give_starter(&"velociraptor")
	_check(starter.bond == game.BOND_STARTER, "le dino de départ commence à %d ♥" % game.BOND_STARTER)
	_check(game.starter_dino() == starter, "Game.starter_dino() le retrouve")
	var gained := [0]
	var on_bond := func(_d, hearts: int) -> void: gained[0] += hearts
	game.bond_changed.connect(on_bond)
	_check(game.add_bond(starter, 2) == 2 and starter.bond == 3 and gained[0] == 2, "Game.add_bond(d, 2) : 3 ♥, signal bond_changed")
	_check(game.add_bond(null, 1) == 0, "Game.add_bond(null) sans erreur")
	starter.hp = 1
	var before: int = starter.bond_points
	game.give_item("baie", 1)
	game.feed_berry(starter)
	_check(starter.bond_points == before + game.BOND_BERRY, "une baie : +%d points de Lien" % game.BOND_BERRY)
	starter.hp = 1
	game.give_item("fougere", 1)
	game.feed_fern(starter)
	_check(starter.bond_points == before + game.BOND_BERRY + game.BOND_FERN, "une fougère : +%d points de Lien" % game.BOND_FERN)
	game.bond_changed.disconnect(on_bond)


# ------------------------------------------------------------------ calming

## A party of `species` at `level` (the first with `bond` hearts) against a corrupted foe.
func _engine(species: Array, level: int, bond: int, foe_species: StringName, foe_level: int, rules := {}):
	var team: Array[Dino] = []
	for s: StringName in species:
		team.append(DinoS.create(s, level))
	team[0].bond = bond
	var foe = DinoS.create(foe_species, foe_level)
	foe.corrupted = true
	return EngineS.new(team, foe, rules)


func _test_calm_bonus() -> void:
	var weak = _engine([&"ankylosaurus"], 16, 0, &"utahraptor", 16)
	var strong = _engine([&"ankylosaurus"], 16, 5, &"utahraptor", 16)
	_check(is_equal_approx(strong.calm_chance() - weak.calm_chance(), 5 * EngineS.CALM_BOND_CHANCE),
		"Lien 5 : chance d'apaiser %.0f %% → %.0f %%" % [weak.calm_chance() * 100.0, strong.calm_chance() * 100.0])
	_check(strong.calm_step() - weak.calm_step() == 5 * EngineS.CALM_BOND_STEP,
		"Lien 5 : calme par apaisement %d → %d" % [weak.calm_step(), strong.calm_step()])
	var kin = _engine([&"velociraptor"], 16, 0, &"utahraptor", 16)
	_check(kin.calm_step() == EngineS.CALM_STEP + EngineS.CALM_KIN_BONUS, "même famille : +%d" % EngineS.CALM_KIN_BONUS)
	var worn = _engine([&"ankylosaurus"], 16, 5, &"utahraptor", 16)
	worn.foe.hp = 1
	_check(worn.calm_chance() <= EngineS.CALM_MAX_CHANCE + 0.0001, "chance plafonnée à %.0f %%" % (EngineS.CALM_MAX_CHANCE * 100.0))


func _test_long_calm() -> void:
	var normal = _engine([&"ankylosaurus"], 16, 0, &"utahraptor", 18)
	var long = _engine([&"ankylosaurus"], 16, 0, &"utahraptor", 18, {"long_calm": true, "starter": &"velociraptor"})
	_check(normal.calm_full == EngineS.CALM_FULL and long.calm_full == roundi(EngineS.CALM_FULL * EngineS.LONG_CALM_FACTOR), "long_calm : jauge %d → %d" % [normal.calm_full, long.calm_full])
	_check(not long.starter_helps(), "long_calm : un autre dino n'a pas le bonus du dino de départ")
	var with_starter = _engine([&"ankylosaurus"], 16, 0, &"utahraptor", 18, {"long_calm": true, "starter": &"ankylosaurus"})
	_check(with_starter.starter_helps() and with_starter.calm_step() == long.calm_step() + EngineS.CALM_STARTER_BONUS,
		"long_calm + dino de départ : +%d de calme" % EngineS.CALM_STARTER_BONUS)
	var plain = _engine([&"ankylosaurus"], 16, 0, &"utahraptor", 18, {"starter": &"ankylosaurus"})
	_check(not plain.starter_helps(), "sans long_calm : pas de bonus du dino de départ")
	# The line « Bastion se met entre Chloé et l'Utahraptor corrompu… », once.
	with_starter.rng.seed = 3
	var said := []
	for i in 3:
		for e: Dictionary in with_starter.turn({"type": "calm"}):
			if e.get("text", "").contains("se met entre Chloé"):
				said.append(e["text"])
		if with_starter.over:
			break
	_check(said.size() == 1, "réplique du dino de départ dite une fois : « %s »" % (said[0] if said.size() > 0 else "—"))


func _test_endure() -> void:
	var e = _engine([&"ankylosaurus", &"velociraptor"], 16, 5, &"utahraptor", 18)
	var d = e.player()
	d.hp = 10
	_check(e._hurt("player", 999) and d.hp == 1, "Lien 5 : tient à 1 PV")
	d.hp = 10
	_check(not e._hurt("player", 999) and d.hp == 0, "…une seule fois par combat")
	var f = _engine([&"ankylosaurus"], 16, 4, &"utahraptor", 18)
	f.player().hp = 10
	_check(not f._hurt("player", 999) and f.player().hp == 0, "Lien 4 : ne tient pas")
	_check(not f._hurt("foe", 999) and f.foe.hp == 1, "un corrompu reste à 1 PV")


## Only calming (the simplest play): must end "calmed" in every run; prints the turns taken.
func _simulate(label: String, species: Array, level: int, bond: int, foe_species: StringName, foe_level: int, rules := {}) -> void:
	var turns: Array[int] = []
	var results := {}
	for run in RUNS:
		game.new_game()
		var e = _engine(species, level, bond, foe_species, foe_level, rules)
		game.party = e.team
		e.rng.seed = run + 1
		seed(run + 1)   # the foe's move choice (pick_random)
		var n := 0
		while not e.over and n < MAX_TURNS:
			e.turn({"type": "calm"})
			n += 1
		results[e.result] = results.get(e.result, 0) + 1
		if e.result == "calmed":
			turns.append(n)
	turns.sort()
	var calmed: int = results.get("calmed", 0)
	var text := "%s : apaisé %d/%d" % [label, calmed, RUNS]
	if not turns.is_empty():
		text += " en %d à %d tours (médiane %d)" % [turns[0], turns[-1], turns[int(turns.size() / 2.0)]]
	if calmed < RUNS:
		text += " — autres : %s" % str(results)
	_check(calmed == RUNS, text)


func _test_calm_battles() -> void:
	var party := [&"ankylosaurus", &"velociraptor", &"protoceratops", &"parasaurolophus", &"compsognathus"]
	_simulate("Protoceratops corrompu niv. 8, équipe niv. 8, Lien 1", party, 8, 1, &"protoceratops", 8)
	_simulate("Utahraptor corrompu niv. 18 (long_calm), dino de départ en tête, Lien 1", party, 16, 1, &"utahraptor", 18,
		{"long_calm": true, "starter": &"ankylosaurus"})
	_simulate("Utahraptor corrompu niv. 18 (long_calm), dino de départ en tête, Lien 3", party, 16, 3, &"utahraptor", 18,
		{"long_calm": true, "starter": &"ankylosaurus"})
	_simulate("Utahraptor corrompu niv. 18 (long_calm), sans le dino de départ, Lien 0", party, 16, 0, &"utahraptor", 18,
		{"long_calm": true, "starter": &"parasaurolophus"})
	_simulate("Ankylosaurus corrompu niv. 16 (champion de Brac), Lien 1", party.slice(1), 16, 1, &"ankylosaurus", 16,
		{"starter": &"velociraptor"})


# ------------------------------------------------------------------ Coup de crâne

func _test_coup_crane() -> void:
	var pachy = DinoS.create(&"pachycephalosaurus", 14)
	_check(AbilitiesS.has(pachy, &"coup_crane") and AbilitiesS.usable(pachy, &"coup_crane"), "Pachycephalosaurus : Coup de crâne")
	_check(AbilitiesS.of(pachy).has(&"coup_crane"), "sa fiche l'affiche (Abilities.of : %s)" % str(AbilitiesS.of(pachy)))
	_check(AbilitiesS.display_name(&"coup_crane") == "Coup de crâne", "nom « Coup de crâne »")
	_check(AbilitiesS.DEFS[&"coup_crane"]["species"].has(&"stygimoloch"), "Stygimoloch aussi (espèce pas encore dans le jeu)")
	_check(not AbilitiesS.has(DinoS.create(&"velociraptor", 14), &"coup_crane"), "Velociraptor : pas de Coup de crâne")
	var obstacle: GDScript = load("res://world/obstacle.gd")
	_check(obstacle.get_script_constant_map()["SFX"].has(&"coup_crane"), "Obstacle : son du Coup de crâne")
	# Its part of the sheet (the portrait needs the textures, which a headless run lacks).
	var card = load("res://ui/dino_card.gd").make(pachy)
	var chips: Node = card._abilities()
	var found := [false]
	_find_text(chips, "Coup de crâne", found)
	_check(found[0], "la fiche (DinoCard, « Sur le terrain ») montre « Coup de crâne »")
	chips.free()
	card.free()


func _find_text(node: Node, text: String, found: Array) -> void:
	if node is Label and (node as Label).text == text:
		found[0] = true
	for child in node.get_children():
		_find_text(child, text, found)


# ------------------------------------------------------------------ StoryTrigger

func _test_story_trigger() -> void:
	var zone := Node2D.new()
	var entities := Node2D.new()
	entities.name = "Entities"
	zone.add_child(entities)
	root.add_child(zone)
	var builder: GDScript = load("res://tools/zone_builder.gd")
	var t = builder.trigger(zone, 60, 62, 3, &"masque_passerelle", {"required_flag": &"test_sceau", "once_flag": &"test_vu"})
	_check(t.get_parent() == entities and t.position == Vector2(60, 62) * TILE, "ZoneBuilder.trigger : dans Entities, en (60, 62)")
	_check(t.required_flag == &"test_sceau" and t.once_flag == &"test_vu" and t.event == &"masque_passerelle", "…avec ses drapeaux et son événement")
	await process_frame
	var shape: CollisionShape2D = t.get_child(0, true)
	_check(shape != null and is_equal_approx((shape.shape as CircleShape2D).radius, 3 * TILE), "cercle de 3 cases")
	_check(t.get_child_count() == 0, "forme interne (jamais sauvegardée dans la scène)")
	var player: Node2D = load("res://actors/player.tscn").instantiate()
	player.position = t.position + Vector2(TILE, 0)
	entities.add_child(player)
	for i in 4:
		await physics_frame
	_check(t._inside == player, "Chloé entre dans le cercle : détectée")
	t.set_process(false)   # the checks below, not the scene itself
	game.flags.erase("test_sceau")
	_check(not t.is_ready_to_play(), "drapeau requis absent : rien")
	game.flags["test_sceau"] = true
	_check(t.is_ready_to_play(), "drapeau requis posé : la scène jouerait")
	player.busy = true
	_check(not t.is_ready_to_play(), "Chloé occupée : attend")
	player.busy = false
	game.flags["test_vu"] = true
	_check(not t.is_ready_to_play(), "drapeau « déjà vu » posé : plus jamais")
	game.flags.erase("test_sceau")
	game.flags.erase("test_vu")
	player.position = t.position + Vector2(10 * TILE, 0)
	for i in 4:
		await physics_frame
	_check(t._inside == null, "Chloé sort du cercle")
	zone.free()


# ------------------------------------------------------------------ the Lien on screen

func _test_bond_display() -> void:
	game.new_game()
	var d = game.give_starter(&"ankylosaurus")
	# The hearts (DinoCard.hearts, also in the party bar's menu), drawn for real.
	var card_s: GDScript = load("res://ui/dino_card.gd")
	var hearts: Control = card_s.hearts(3, 22.0)
	root.add_child(hearts)
	await process_frame
	await process_frame
	_check(hearts.custom_minimum_size.x >= 5 * 22.0, "5 cœurs dessinés (DinoCard.hearts)")
	hearts.free()
	var pts := PackedVector2Array()
	for i in 32:
		var t := i * TAU / 32.0
		pts.append(Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))))
	_check(not Geometry2D.triangulate_polygon(pts).is_empty(), "forme du cœur valide (triangulable)")
	var card = card_s.make(d)
	var row: Control = card._bond_row()
	var found := [false]
	_find_text(row, "1 / 5", found)
	_check(found[0], "fiche : ligne « Lien » à 1 / 5")
	row.free()
	card.free()
	# The party bar: « +1 ♥ » next to its portrait, and its hearts in its menu.
	var bar = load("res://ui/party_bar.gd").new()
	var line: Control = bar._bond_line(d)
	_check(line.get_child_count() == 2 and (line.get_child(0) as Label).text == "Lien", "menu du dino : « Lien » et ses cœurs")
	line.free()
	bar._on_bond(d, 1)
	_check(bar._pending.size() == 1 and bar._pending[0][1] == "+1 ♥", "barre d'équipe : « +1 ♥ » en attente")
	bar.free()
	# Walking with it: the companion counts the steps.
	var player: Node2D = load("res://actors/player.tscn").instantiate()
	var companion: Node2D = load("res://actors/companion.tscn").instantiate()
	companion.player = player
	root.add_child(player)
	root.add_child(companion)
	var hearts_before: int = d.bond
	var points_before: int = d.bond_points
	for i in 10:
		player.stepped.emit(&"grass")
	_check(d.bond_points == points_before + 10 * game.BOND_STEP, "10 pas avec lui en tête : +10 points")
	player.busy = true
	player.stepped.emit(&"grass")
	player.busy = false
	_check(d.bond_points == points_before + 10 * game.BOND_STEP, "pendant une scène : rien")
	for i in d.bond_to_next():
		player.stepped.emit(&"grass")
	_check(d.bond == hearts_before + 1, "en marchant : un cœur de plus (%d ♥)" % d.bond)
	companion.free()
	player.free()


## BattleScene gives its rules to the engine: a long calm, Chloé's hatchling.
func _test_battle_rules() -> void:
	game.new_game()
	game.give_starter(&"velociraptor")
	var foe = DinoS.create(&"utahraptor", 18)
	foe.corrupted = true
	var battle = load("res://battle/battle_scene.gd").new()
	root.add_child(battle)
	battle.run(foe, {"long_calm": true})   # not awaited: only its start
	_check(battle.engine.long_calm and battle.engine.calm_full == roundi(100 * battle.engine.LONG_CALM_FACTOR), "BattleScene : long_calm transmis (jauge longue)")
	_check(battle.engine.starter == &"velociraptor" and battle.engine.starter_helps(), "BattleScene : dino de départ reconnu")
	_check(is_equal_approx(battle._foe_panel["calm"].max_value, float(battle.engine.calm_full)), "barre de Calme à la jauge longue")
	battle.free()
	root.get_node("Audio").pop_music()   # its battle theme
	var plain = load("res://battle/battle_scene.gd").new()
	root.add_child(plain)
	var wild = DinoS.create(&"protoceratops", 5)
	wild.corrupted = true
	plain.run(wild)
	_check(not plain.engine.long_calm and plain.engine.calm_full == 100, "BattleScene sans règle : jauge 100")
	plain.free()
	root.get_node("Audio").pop_music()
	await process_frame
