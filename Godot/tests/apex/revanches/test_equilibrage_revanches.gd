extends GdUnitTestSuite
## L'équilibrage des revanches (docs/post-game-plan.md § 3 : « 6-10 tours, 70-85 % de victoire sans Sceaux, pas un
## mur ») par simulation sur le moteur réel, sans fenêtre. Mêmes hypothèses que tests/apex/mecaniques/
## test_equilibrage_apex.gd : 120 combats par cas, l'équipe type à la fin du jeu (départ L à Lien 5, le 3e petit L-1,
## Nessie L-1, Bouée L-2, Ptéro L-2, les autres à 2 cœurs), le meilleur coup, jamais de soin ; un K.O. : le premier
## dino debout entre. L = 50 (le niveau maximum : l'équipe de fin), et 48 pour dire « pas un mur ».
## - chaque Alpha seul (son moteur : sous l'eau et l'abîme pour Minuit) : la part de victoires et les tours ;
## - le pari d'Isaure et le défi n° 6 de Maïa : leurs dinos à la suite, sans soin entre eux ;
## - avec les Sceaux libres (le branchement de BattleEngine, patch_C.md § 1) : combien ils aident.
## Les résultats sont cités tels quels dans RevancheBattles.EQUILIBRAGE.

const SAVE_PATH := "user://test_gdunit_revanches_equilibrage_save.json"
const RUNS := 120
const SEED := 50
const MAX_TURNS := 80
const STARTERS: Array[StringName] = [&"velociraptor", &"ankylosaurus", &"parasaurolophus"]
const NAMES := {&"velociraptor": "Vif", &"ankylosaurus": "Bastion", &"parasaurolophus": "Écho"}
const STOLEN := {&"velociraptor": &"parasaurolophus", &"ankylosaurus": &"velociraptor", &"parasaurolophus": &"ankylosaurus"}
const LEVEL := 50
const HARDER := 48
const OTHERS_BOND := 2
## Les cibles : la moyenne des trois dinos de départ (plan : 70-85 % ; deux Alphas à 86-87 %, tolérés), chaque départ
## au moins EACH_MIN ; à 48, la moyenne au moins WALL (« pas un mur ») ; les tours : 6-10 au plan, mais le Tricératops
## et le Spinosaure encaissent (12 et 15 tours) : TURNS dit « jamais interminable ».
const WIN := Vector2i(70, 88)
const EACH_MIN := 60
const WALL := 50
const TURNS := Vector2(6.0, 16.0)
## Les duels de dresseurs (quatre dinos à la suite) : comme Isaure au chapitre 9 (85-95 %), Maïa perd « de peu ».
const DUEL := Vector2i(85, 95)
const DUEL_WALL := 60
const ALL_SEALS: Array[String] = ["sceau_plaines", "sceau_foret", "sceau_marais", "sceau_desert", "sceau_cote", "sceau_monts", "sceau_volcan"]

var _saved_path: String


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)


func after() -> void:
	Save.path = _saved_path
	Game.new_game()


func before_test() -> void:
	Game.new_game()
	Game.set_flag(&"prologue_done")
	Game.set_flag(&"post_game")
	Game.set_flag(&"maia_starter", "parasaurolophus")


# ------------------------------------------------------------------ les Alphas

func test_chaque_alpha_70_a_85_pourcent_en_6_a_10_tours() -> void:
	for id in RevancheBattles.ids():
		var total := 0
		var low := 0
		var turns := 0.0
		for starter in STARTERS:
			var r := _alpha(id, starter, LEVEL)
			var harder := _alpha(id, starter, HARDER)
			total += r["win"]
			low += harder["win"]
			turns += r["turns"]
			prints("   %s, %s : équipe de %d : %d %% en %.1f tours (%.1f K.O.) ; de %d : %d %%" % [id, NAMES[starter], LEVEL,
				r["win"], r["turns"], r["kos"], HARDER, harder["win"]])
			assert_int(r["win"]).override_failure_message("%s, %s : %d %% (au moins %d)" % [id, NAMES[starter], r["win"], EACH_MIN]).is_greater_equal(EACH_MIN)
		var mean := roundi(total / float(STARTERS.size()))
		var mean_low := roundi(low / float(STARTERS.size()))
		var mean_turns := turns / STARTERS.size()
		prints("   %s, en moyenne : %d %% en %.1f tours ; de %d : %d %%" % [id, mean, mean_turns, HARDER, mean_low])
		assert_int(mean_low).override_failure_message("%s : de %d, %d %% : un mur" % [id, HARDER, mean_low]).is_greater_equal(WALL)
		assert_int(mean).override_failure_message("%s : %d %% (attendu %d-%d)" % [id, mean, WIN.x, WIN.y]).is_between(WIN.x, WIN.y)
		assert_float(mean_turns).override_failure_message("%s : %.1f tours (attendu %d-%d)" % [id, mean_turns, TURNS.x, TURNS.y]).is_between(TURNS.x, TURNS.y)


## Sans les crans « chez lui », un Alpha de 50 à 53 seul contre l'équipe de fin tombe presque toujours : c'est pour ça
## qu'ils sont là (le cité de RevancheBattles.EQUILIBRAGE).
func test_sans_les_crans_chez_lui_trop_facile() -> void:
	var easy := 0
	for id in RevancheBattles.ids():
		var total := 0
		for starter in STARTERS:
			total += _alpha(id, starter, LEVEL, false, false)["win"]
		var mean := roundi(total / float(STARTERS.size()))
		prints("   %s, sans les crans : %d %%" % [id, mean])
		if mean > WIN.y:
			easy += 1
	assert_int(easy).override_failure_message("les crans ne servent à rien").is_greater_equal(5)


# ------------------------------------------------------------------ Isaure, Maïa

func test_le_pari_d_isaure_et_le_defi_de_maia() -> void:
	var rules := RevancheBattles.isaure_rules()
	rules["trainer"] = RevancheBattles.ISAURE
	var maia := {"trainer": ApexBattles.MAIA}
	for duel: Array in [["Isaure", RevancheBattles.isaure_team(), rules], ["Maïa", ApexBattles.maia_team(), maia]]:
		var total := 0
		var low := 0
		for starter in STARTERS:
			var rate := _duel(duel[1], duel[2], starter, LEVEL)
			var harder := _duel(duel[1], duel[2], starter, HARDER)
			total += rate
			low += harder
			prints("   %s, %s : équipe de %d : %d %% ; de %d : %d %%" % [duel[0], NAMES[starter], LEVEL, rate, HARDER, harder])
		var mean := roundi(total / float(STARTERS.size()))
		var mean_low := roundi(low / float(STARTERS.size()))
		prints("   %s, en moyenne : %d %% ; de %d : %d %%" % [duel[0], mean, HARDER, mean_low])
		assert_int(mean_low).override_failure_message("%s : de %d, %d %% : un mur" % [duel[0], HARDER, mean_low]).is_greater_equal(DUEL_WALL)
		assert_int(mean).override_failure_message("%s : %d %% (attendu %d-%d)" % [duel[0], mean, DUEL.x, DUEL.y]).is_between(DUEL.x, DUEL.y)


# ------------------------------------------------------------------ avec les Sceaux libres

## Les sept Sceaux éveillés (sauf celui de l'Alpha combattu), appelés comme un enfant qui a compris : la Charge, la
## Meute, Piment, Toupet et Cheminée tout de suite, le Spinosaure quand l'équipe souffre, Minuit avant un gros coup.
## Ils aident (plus de victoires, moins de tours), sans tout écraser : un appel par jour.
func test_avec_les_sceaux(do_skip := not _patched(), skip_reason := "patch_C.md § 1 (BattleEngine.libres) pas appliqué") -> void:
	Game.give_item(ApexEngine.INSIGNE)
	for id in RevancheBattles.ids():
		var alone := 0
		var helped := 0
		var turns := 0.0
		for starter in STARTERS:
			alone += _alpha(id, starter, LEVEL)["win"]
			var r := _alpha(id, starter, LEVEL, true)
			helped += r["win"]
			turns += r["turns"]
		var a := roundi(alone / float(STARTERS.size()))
		var h := roundi(helped / float(STARTERS.size()))
		prints("   %s : sans Sceaux %d %%, avec %d %% en %.1f tours" % [id, a, h, turns / STARTERS.size()])
		assert_int(h).override_failure_message("%s : les Sceaux n'aident pas (%d → %d %%)" % [id, a, h]).is_greater_equal(a)


# ------------------------------------------------------------------ outils

static func _patched() -> bool:
	var team: Array[Dino] = [Dino.create(&"velociraptor", 5)]
	return "libres" in BattleEngine.new(team, Dino.create(&"velociraptor", 5), {})


## L'équipe type à la fin du jeu (comme test_equilibrage_apex.gd).
func _team(starter: StringName, lvl: int) -> Array[Dino]:
	var team: Array[Dino] = []
	var s := Dino.create(starter, lvl, NAMES[starter])
	s.bond = Dino.MAX_BOND
	team.append(s)
	team.append(Dino.create(STOLEN[starter], lvl - 1))
	team.append(Dino.create(&"plesiosaurus", lvl - 1, "Nessie"))
	team.append(Dino.create(&"baryonyx", lvl - 2, "Bouée"))
	team.append(Dino.create(&"pteranodon", lvl - 2, "Ptéro"))
	for d in team.slice(1):
		d.bond = OTHERS_BOND
	return team


## Le moteur d'une revanche : celui de son lieu (sous l'eau pour Minuit), ses règles.
func _alpha_engine(id: StringName, team: Array[Dino], starter: StringName, seals: bool, at_home := true) -> BattleEngine:
	var rules := RevancheBattles.alpha_rules(id)
	rules["starter"] = starter
	if not at_home:
		rules.erase("foe_stages")
	if seals:
		rules["sceaux_libres"] = true
	var e: BattleEngine = UnderwaterEngine.new(team, RevancheBattles.alpha(id), rules) if rules.get("underwater", false) \
		else BattleEngine.new(team, RevancheBattles.alpha(id), rules)
	var home: Dictionary = rules.get("foe_stages", {})
	for stat: String in home:   # (ce que fait la règle « foe_stages » une fois patch_C.md § 1 appliqué : la même chose)
		e.stages["foe"][stat] = int(home[stat])
	return e


## Une revanche RUNS fois : {"win" (%), "turns" (moyenne, combats gagnés), "kos" (K.O. de l'équipe par combat)}.
func _alpha(id: StringName, starter: StringName, lvl: int, seals := false, at_home := true) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	seed(SEED)   # (le moteur tire aussi au hasard global : pick_random)
	var wins := 0
	var turns := 0
	var kos := 0
	for t in RUNS:
		if seals:
			for s in ALL_SEALS:
				Game.set_flag(ApexEngine.woken_flag(s))
				Game.set_flag(ApexEngine.day_flag(s), 0)
		var e := _alpha_engine(id, _team(starter, lvl), starter, seals, at_home)
		e.rng.seed = rng.randi()
		var r := _fight(e, seals)
		kos += r[1]
		if e.result == "win":
			wins += 1
			turns += r[0]
	return {"win": roundi(100.0 * wins / RUNS), "turns": float(turns) / maxi(1, wins), "kos": float(kos) / RUNS}


## Part de victoires (%) contre les dinos d'un dresseur à la suite (pas de soin entre eux), RUNS fois.
func _duel(def: Array, rules: Dictionary, starter: StringName, lvl: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	seed(SEED)
	var wins := 0
	var r := rules.duplicate()
	r["starter"] = starter
	for t in RUNS:
		var team := _team(starter, lvl)
		var ok := true
		for m: Array in def:
			var e := BattleEngine.new(team, Dino.create(m[0], m[1], m[2]), r)
			e.rng.seed = rng.randi()
			_fight(e, false)
			if e.result != "win":
				ok = false
				break
		if ok:
			wins += 1
	return roundi(100.0 * wins / RUNS)


## Un combat joué jusqu'au bout : [tours (sans les entrées après un K.O. ni les Sceaux), K.O. de l'équipe].
func _fight(e: BattleEngine, seals: bool) -> Array:
	var turns := 0
	var actions := 0
	var kos := 0
	while not e.over and turns < MAX_TURNS and actions < MAX_TURNS * 3:
		actions += 1
		if e.must_switch:
			for i in e.team.size():
				if e.can_switch_to(i):
					e.turn({"type": "switch", "index": i})
					break
			continue
		var action := _choose(e, seals)
		if action["type"] != "sceau":
			turns += 1
		for x: Dictionary in e.turn(action):
			if x["type"] == "faint" and x["side"] == "player":
				kos += 1
	return [turns, kos]


## Ce que joue l'enfant simulé : le meilleur coup ; avec les Sceaux, ceux qui servent tout de suite, le Spinosaure quand
## l'équipe souffre, Minuit quand son dino est entamé.
func _choose(e: BattleEngine, seals: bool) -> Dictionary:
	if seals:
		var l = e.get(&"libres")
		if l != null:
			var me := e.player()
			var down := e.team.any(func(d: Dino) -> bool: return d.hp <= 0)
			if l.can_call("sceau_marais") and (me.hp < me.max_hp() * 0.4 or down):
				return {"type": "sceau", "id": "sceau_marais"}
			if l.can_call("sceau_cote") and me.hp < me.max_hp() * 0.6:
				return {"type": "sceau", "id": "sceau_cote"}
			for id in ["sceau_volcan", "sceau_desert", "sceau_monts", "sceau_plaines", "sceau_foret"]:
				if l.can_call(id):
					return {"type": "sceau", "id": id}
	return {"type": "move", "index": _best(e.player(), e.foe)}


func _best(d: Dino, foe: Dino) -> int:
	var best := 0
	var best_v := 0.0
	for i in d.moves.size():
		if d.moves[i]["pp"] <= 0:
			continue
		var m := MovesDB.move(d.moves[i]["id"])
		var v: float = m["power"] * m["accuracy"] * (1.25 if m["type"] == d.type() else 1.0) * MovesDB.effectiveness(m["type"], foe.type())
		if v > best_v:
			best_v = v
			best = i
	return best
