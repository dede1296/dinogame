extends SceneTree
## Headless checks of la Plongée (chapter 5): its rules (Dive: the mask, a grown diver, what is
## missing), underwater zones, Chloé carried by her diver under the water (Player.diving), the
## battles under the sea (UnderwaterEngine: Water stronger, Fire stifled, non-swimmers slower,
## the marks on the moves' cards) and the Mosasaure Abyssal's rhythm (it sinks into the dark,
## Chloé's moves are lost, it surges, it is exposed: a sure critical hit), then a simulation of
## its battle against a team of the Côte's level. Prints each check, quits with 1 on a failure:
##   godot --headless --path Godot --script res://tools/test_plongee.gd
## The parts that need the shared files patched (patch_ch5_mecaniques.md) are skipped, with a
## word, when the patch is not there. Scripts are loaded at run time (autoloads), so untyped.

const SCRIPTS := [
	"res://world/dive.gd", "res://world/dive_spot.gd", "res://ui/dive_button.gd", "res://world/view3d/underwater.gd",
	"res://battle/underwater_engine.gd", "res://battle/battle_underwater.gd", "res://world/view3d/world_view.gd",
	"res://battle/battle_scene.gd", "res://world/world.gd", "res://actors/player.gd", "res://data/abilities.gd",
	"res://world/sea_current.gd", "res://world/bubble_column.gd", "res://world/dark_nook.gd", "res://world/nook_find.gd",
	"res://world/sea_lessons.gd", "res://world/view3d/sea_features.gd",
]
## The Mosasaure's battle: its level, the team's (the Côte: niv. 28-35), how many battles.
const MOSA_LEVEL := 34
const TEAM_LEVEL := 30
const BATTLES := 40
const MAX_TURNS := 60

var _checks := 0
var _failures := 0
var game: Node
var DiveS: GDScript
var EngineS: GDScript
var PlainS: GDScript
var DinoS: GDScript
var SpeciesS: GDScript
var MovesS: GDScript


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("— La Plongée : tests headless —")
	for path: String in SCRIPTS:
		var s: GDScript = load(path)
		_check(s != null and s.can_instantiate(), "compile %s" % path)
	_check(load("res://world/view3d/light_shaft.gdshader") is Shader, "shader des rayons de lumière")
	_check(load("res://world/view3d/current_streak.gdshader") is Shader, "shader des traînées de courant")
	game = root.get_node_or_null("Game")
	if game == null or _failures > 0:
		_finish()
		return
	DiveS = load("res://world/dive.gd")
	EngineS = load("res://battle/underwater_engine.gd")
	PlainS = load("res://battle/battle_engine.gd")
	DinoS = load("res://game/dino.gd")
	SpeciesS = load("res://data/species_db.gd")
	MovesS = load("res://data/moves_db.gd")
	_test_patch()
	_test_dive_rules()
	_test_zone_state()
	_test_water_rules()
	_test_abyss()
	_test_hearts_light()
	_simulate_mosasaure()
	_finish()


func _finish() -> void:
	print("— %d vérifications, %d échec(s) —" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print(("  ok    " if ok else "  ÉCHEC ") + what)


func _has(species: StringName) -> bool:
	return SpeciesS.PATHS.has(species)


func _patched() -> bool:
	var p = load("res://actors/player.gd").new()
	var yes: bool = "diving" in p
	p.free()
	return yes


# ------------------------------------------------------------------ the patch, the rules

func _test_patch() -> void:
	if not _patched():
		print("  (patch_ch5_mecaniques non appliqué : Player.diving, Region.underwater, WorldView.dive_sink… sautés)")
		return
	var abilities: GDScript = load("res://data/abilities.gd")
	var def: Dictionary = abilities.DEFS[&"plongee"]
	_check(not def.has("soon") and &"plesiosaurus" in def.get("species", []), "Plongée jouable, par espèce (Plésiosaure…)")
	_check(load("res://data/items_db.gd").ITEMS.has("masque_plongee"), "objet « masque_plongee »")
	var region = load("res://world/region.gd").new()
	_check("underwater" in region and region.underwater == false, "Region.underwater (faux par défaut)")
	region.free()
	var view = load("res://world/view3d/world_view.gd").new()
	_check("dive_sink" in view, "WorldView.dive_sink")
	view.free()


func _test_dive_rules() -> void:
	game.new_game()
	game.give_starter(&"velociraptor")
	_check(not DiveS.can_dive() and DiveS.blocked_reason().contains("masque"), "ni masque ni plongeur : pas de plongée (%s)" % DiveS.blocked_reason())
	var kind := &"plesiosaurus" if _has(&"plesiosaurus") else &"koolasuchus"
	var abilities: GDScript = load("res://data/abilities.gd")
	var probe = DinoS.create(kind, 20)
	if not abilities.has(probe, &"plongee"):
		print("  (pas de plongeur disponible (%s) : règles du plongeur sautées)" % kind)
		return
	var young = DinoS.create(kind, 8, "Nessie")
	game.add_caught(young)
	_check(not DiveS.can_dive() and DiveS.blocked_reason().contains("masque") and DiveS.blocked_reason().contains("trop jeune"),
		"jeune plongeur sans masque : il manque le masque, et qu'il grandisse")
	young.level = 26
	_check(not DiveS.can_dive() and DiveS.blocked_reason().contains("sans masque"), "plongeur adulte sans masque : il manque le masque")
	young.level = 8
	game.give_item("masque_plongee")
	_check(not DiveS.can_dive() and DiveS.blocked_reason().contains("trop jeune"), "%s niv. 8 + masque : trop jeune" % kind)
	young.level = 26
	_check(DiveS.can_dive() and DiveS.diver() == young, "%s niv. 26 + masque : il plonge avec Chloé" % kind)
	game.items.erase("masque_plongee")
	game.set_flag(&"masque_plongee")
	_check(DiveS.can_dive(), "drapeau « masque_plongee » : vaut le masque")
	if kind == &"plesiosaurus" and _patched():
		_check(not abilities.has(DinoS.create(&"koolasuchus", 20), &"plongee"), "le Koolasuchus nage, mais ne plonge pas")


func _test_zone_state() -> void:
	var r := Node2D.new()
	_check(not DiveS.underwater(r) and not DiveS.underwater(null), "une zone ordinaire n'est pas sous l'eau")
	r.set_meta(&"underwater", true)
	_check(DiveS.underwater(r), "méta « underwater » : sous l'eau")
	r.free()
	if not _patched():
		return
	# Under the water, her diver carries her everywhere, even far from any water tile.
	var player = load("res://actors/player.tscn").instantiate()
	root.add_child(player)
	player.surface_at = func(_p: Vector2) -> StringName: return &"sand"
	var diver = game.party[game.party.size() - 1]
	player.swimmer = diver
	player.diving = true
	player._update_swim()
	_check(player.swimmer == diver and player.is_swimming(), "sous l'eau : le plongeur la porte, loin de toute eau")
	player.diving = false
	player._update_swim()
	_check(player.swimmer == null, "de retour en surface, hors de l'eau : à pied")
	player.queue_free()


# ------------------------------------------------------------------ the battle's rules

func _engines(mine: StringName, foe: StringName, rules := {}) -> Array:
	var team_a: Array[Dino] = [DinoS.create(mine, TEAM_LEVEL)]
	var team_b: Array[Dino] = [DinoS.create(mine, TEAM_LEVEL)]
	var under = EngineS.new(team_a, DinoS.create(foe, TEAM_LEVEL), rules)
	var plain = PlainS.new(team_b, DinoS.create(foe, TEAM_LEVEL), rules)
	return [under, plain]


func _test_water_rules() -> void:
	_check(is_equal_approx(EngineS.power("eau"), 1.25) and is_equal_approx(EngineS.power("feu"), 0.5) and EngineS.power("vent") == 1.0,
		"sous l'eau : Eau ×1,25, Feu ×0,5, le reste ×1")
	var pair := _engines(&"velociraptor", &"baryonyx")
	_check(pair[0].mark("eau") == "  ▲" and pair[0].mark("feu") == "  ▼" and pair[0].mark("pierre") == "", "cartes : ▲ Eau, ▼ Feu")
	var slow: float = pair[0]._speed("player") / pair[1]._speed("player")
	var swim: float = pair[0]._speed("foe") / pair[1]._speed("foe")
	_check(is_equal_approx(slow, EngineS.LAND_SLOW) and is_equal_approx(swim, 1.0), "Velociraptor plus lent sous l'eau (×%.2f), Baryonyx non (×%.2f)" % [slow, swim])
	for t: Array in [[&"machoireAquatique", 1.25], [&"crocsBrulants", 0.5], [&"morsure", 1.0]]:
		var move: Dictionary = MovesS.move(t[0])
		var p2 := _engines(&"baryonyx", &"triceratops")
		p2[0].rng.seed = 7
		p2[1].rng.seed = 7
		var a: int = p2[0]._damage("player", "foe", move)["damage"]
		var b: int = p2[1]._damage("player", "foe", move)["damage"]
		_check(absf(a - b * float(t[1])) <= 1.0, "%s : %d dégâts sous l'eau, %d dehors" % [move["name"], a, b])


# ------------------------------------------------------------------ the Mosasaure's rhythm

func _foe_kind() -> StringName:
	return &"mosasaure_abyssal" if _has(&"mosasaure_abyssal") else &"spinosaurus"


func _test_abyss() -> void:
	var team: Array[Dino] = [DinoS.create(&"velociraptor", TEAM_LEVEL, "Vif")]
	var foe = DinoS.create(_foe_kind(), MOSA_LEVEL, "Mosasaure Abyssal")
	var e = EngineS.new(team, foe, {"abyss": true})
	var attack := _sure_attack(team[0])
	var log: Array = []
	var deep: Array = []
	for turn in 4:
		team[0].hp = team[0].max_hp()
		foe.hp = foe.max_hp()
		log.append(e.turn({"type": "move", "index": attack}))
		deep.append(e.deep)
	var kinds := func(ev: Array) -> Array: return ev.filter(func(x: Dictionary) -> bool: return x["type"] == "abyss").map(func(x: Dictionary) -> String: return x["kind"])
	_check(kinds.call(log[0]).is_empty(), "tour 1 : rien de spécial")
	_check(kinds.call(log[1]) == ["hide"] and deep[1] == EngineS.Deep["HIDDEN"], "fin du tour 2 : il plonge dans le noir (annoncé)")
	var lost: bool = log[2].any(func(x: Dictionary) -> bool: return x["type"] == "miss" and x["side"] == "player" and x["text"] == EngineS.LOST)
	_check(lost, "tour 3 : l'attaque de Chloé se perd dans le noir")
	var order: Array = log[2].map(func(x: Dictionary) -> String: return x["type"] + ("/" + x["kind"] if x["type"] == "abyss" else ""))
	_check(order.find("miss") < order.find("abyss/surge") and order.has("abyss/exposed"), "tour 3 : puis il jaillit et frappe, et reste à découvert (%s)" % ", ".join(order))
	var crit: bool = log[3].any(func(x: Dictionary) -> bool: return x["type"] == "damage" and x["side"] == "foe" and x["crit"])
	_check(crit, "tour 4 : coup critique assuré sur le Mosasaure à découvert")
	# Before the surge, with a move on her own dino (Blindage): it works in the dark.
	var tank: Array[Dino] = [DinoS.create(&"ankylosaurus", TEAM_LEVEL, "Bastion")]
	var e2 = EngineS.new(tank, DinoS.create(_foe_kind(), MOSA_LEVEL), {"abyss": true})
	tank[0].moves[0] = {"id": &"blindage", "pp": 10}
	for turn in 2:
		tank[0].hp = tank[0].max_hp()
		e2.turn({"type": "move", "index": 1})
	tank[0].hp = tank[0].max_hp()
	var ev: Array = e2.turn({"type": "move", "index": 0})
	_check(ev.any(func(x: Dictionary) -> bool: return x["type"] == "stat" and x["side"] == "player"), "dans le noir, Blindage marche (sur son propre dino)")


## A move of `d` that never misses and hits (power > 0), else its first.
func _sure_attack(d) -> int:
	for i in d.moves.size():
		var m: Dictionary = MovesS.move(d.moves[i]["id"])
		if m["power"] > 0 and m["accuracy"] >= 1.0:
			return i
	return 0


# ------------------------------------------------------------------ dark nooks

## The Cœurs' light: none without one, wider with each.
func _test_hearts_light() -> void:
	var nook: GDScript = load("res://world/dark_nook.gd")
	game.items.erase("coeur_1")
	game.items.erase("coeur_2")
	_check(nook.hearts() == 0 and nook.light_radius_px() == 0.0, "sans Cœur : pas de lumière dans les recoins")
	game.give_item("coeur_1")
	var one: float = nook.light_radius_px()
	game.give_item("coeur_2")
	var two: float = nook.light_radius_px()
	_check(one > 0.0 and two > one, "un Cœur : %.0f px de lumière, deux : %.0f px" % [one, two])


# ------------------------------------------------------------------ the battle, played

## BATTLES battles against the Mosasaure, played as a child who listens to the lesson: the
## strongest move against it; in the dark, a move on her own dino if there is one.
func _simulate_mosasaure() -> void:
	var kinds: Array[StringName] = [&"velociraptor", &"triceratops", &"parasaurolophus"]
	kinds.append(&"plesiosaurus" if _has(&"plesiosaurus") else &"baryonyx")
	kinds.append(&"pteranodon" if _has(&"pteranodon") else &"deinonychus")
	var wins := 0
	var turns := 0
	var surges := 0
	var fallen := 0
	for n in BATTLES:
		var team: Array[Dino] = []
		for k in kinds:
			team.append(DinoS.create(k, TEAM_LEVEL))
		var e = EngineS.new(team, DinoS.create(_foe_kind(), MOSA_LEVEL, "Mosasaure Abyssal"), {"abyss": true})
		e.rng.seed = 1000 + n
		var t := 0
		while not e.over and t < MAX_TURNS:
			t += 1
			var ev: Array = e.turn({"type": "move", "index": _pick(e)})
			surges += ev.filter(func(x: Dictionary) -> bool: return x["type"] == "abyss" and x["kind"] == "surge").size()
		if e.result == "win":
			wins += 1
		turns += t
		fallen += team.filter(func(d) -> bool: return d.hp <= 0).size()
	var rate := wins / float(BATTLES)
	print("  Mosasaure niv. %d (%s) contre %s niv. %d : %d victoires sur %d, %.1f tours en moyenne, %.1f plongeons et %.1f dinos K.O. par combat" % [
		MOSA_LEVEL, _foe_kind(), ", ".join(kinds), TEAM_LEVEL, wins, BATTLES, turns / float(BATTLES), surges / float(BATTLES), fallen / float(BATTLES)])
	_check(rate >= 0.5, "combat gagnable au niveau de la Côte (%d %%)" % roundi(rate * 100.0))
	_check(surges > 0, "il plonge et jaillit pendant les combats (%d fois)" % surges)


func _pick(e) -> int:
	var d = e.player()
	if e.deep == EngineS.Deep["HIDDEN"]:
		for i in d.moves.size():
			var m: Dictionary = MovesS.move(d.moves[i]["id"])
			var fx: Dictionary = m.get("effect", {})
			if d.moves[i]["pp"] > 0 and m["power"] == 0 and (fx.has("self") or fx.has("heal")):
				return i
	var best := 0
	var best_power := -1.0
	for i in d.moves.size():
		var m: Dictionary = MovesS.move(d.moves[i]["id"])
		var power: float = m["power"] * MovesS.effectiveness(m["type"], e.foe.type()) * EngineS.power(m["type"]) * m["accuracy"]
		if d.moves[i]["pp"] > 0 and power > best_power:
			best_power = power
			best = i
	return best
