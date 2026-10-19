extends GdUnitTestSuite
## L'équilibrage des deux derniers combats, par simulation sur le moteur réel (ApexEngine), sans fenêtre. Mêmes
## hypothèses que tests/volcan/test_combat_volcan.gd : 120 combats par cas, graine 48, l'équipe type (départ L, le 3e
## petit L-1, Nessie L-1, Bouée L-2, Ptéro L-2), le meilleur coup, jamais de soin (sauf le Sceau du Marais), « Apaiser »
## un corrompu à mi-vie ; un K.O. : le premier dino debout entre.
## - Isaure (47/47/48/49, Carène hésite) contre une équipe de fin du Volcan (47) : 85-95 %, jamais un mur.
## - Le Souverain (50, jauge 300, l'Ambre clair à deux tiers ; le dino de départ à Lien 5) contre une équipe de 48 :
##   sans les Sceaux, 15-25 tours ; avec les cinq bien placés, 8-12 ; jamais perdu (on se relève).

const SAVE_PATH := "user://test_gdunit_apex_equilibrage_save.json"
const RUNS := 120
const SEED := 48
const MAX_TURNS := 120
const STARTERS: Array[StringName] = [&"velociraptor", &"ankylosaurus", &"parasaurolophus"]
const NAMES := {&"velociraptor": "Vif", &"ankylosaurus": "Bastion", &"parasaurolophus": "Écho"}
const STOLEN := {&"velociraptor": &"parasaurolophus", &"ankylosaurus": &"velociraptor", &"parasaurolophus": &"ankylosaurus"}
const ISAURE_LEVEL := 47
const ISAURE_MIN := 85
const ISAURE_MAX := 95
const EACH_MIN := 80
const SOUVERAIN_LEVEL := 48
## Tours (moyenne), sans les Sceaux et avec les cinq.
const ALONE := Vector2(15.0, 25.0)
const HELPED := Vector2(8.0, 12.0)
const USED_FIRST_MAX := 16.0
const MIN_SAVED := 4.0
const FIVE: Array[String] = ["sceau_marais", "sceau_desert", "sceau_cote", "sceau_monts", "sceau_volcan"]
## Le Lien des autres dinos de l'équipe à la fin du jeu.
const OTHERS_BOND := 2
## Les deux façons de jouer simulées : l'user d'abord (le meilleur coup jusqu'à mi-vie, puis « Apaiser »), ou comme
## dit la leçon (« Appelle-les… Et parle-lui ») : « Apaiser » dès le début, les Sceaux du calme tout de suite.
const HOW := {false: "l'user puis parler", true: "parler tout de suite"}

var _saved_path: String
## Ce qui s'est passé dans le combat en cours (« faint » de Chloé, « caillou »).
var _seen: Array[String] = []


func before() -> void:
	_saved_path = Save.path
	Save.path = SAVE_PATH   # (jamais la partie de Greg)


func after() -> void:
	Save.path = _saved_path
	Game.new_game()


func before_test() -> void:
	Game.new_game()
	Game.set_flag(&"prologue_done")


# ------------------------------------------------------------------ Isaure

## En moyenne sur les trois dinos de départ : 85-95 % ; chacun au moins EACH_MIN (le 3e petit de l'équipe de Bastion
## est Vif, un raptor du Vent : contre quatre dinos de la mer, presque toujours gagné) ; un niveau plus bas, jamais
## un mur.
func test_isaure_contre_une_equipe_de_fin_du_volcan() -> void:
	var total := 0
	for starter in STARTERS:
		var rate := _isaure_rate(starter, ISAURE_LEVEL)
		var harder := _isaure_rate(starter, ISAURE_LEVEL - 1)
		var easier := _isaure_rate(starter, ISAURE_LEVEL + 1)
		total += rate
		prints("   %s : Isaure contre une équipe de %d : %d %% (de %d : %d %% ; de %d : %d %%)" % [NAMES[starter], ISAURE_LEVEL, rate,
			ISAURE_LEVEL - 1, harder, ISAURE_LEVEL + 1, easier])
		assert_int(rate).override_failure_message("%s : Isaure contre une équipe de %d : %d %% (au moins %d)" % [
			NAMES[starter], ISAURE_LEVEL, rate, EACH_MIN]).is_greater_equal(EACH_MIN)
		assert_int(harder).override_failure_message("%s : un niveau plus bas, %d %% : un mur" % [NAMES[starter], harder]).is_greater_equal(60)
	var mean := roundi(total / float(STARTERS.size()))
	prints("   Isaure, en moyenne : %d %%" % mean)
	assert_int(mean).override_failure_message("Isaure en moyenne : %d %% (attendu %d-%d)" % [mean, ISAURE_MIN, ISAURE_MAX]).is_between(ISAURE_MIN, ISAURE_MAX)


# ------------------------------------------------------------------ le Souverain

func test_souverain_sans_les_sceaux_long_jamais_perdu() -> void:
	for talk in [false, true]:
		for starter in STARTERS:
			var r := _souverain(starter, SOUVERAIN_LEVEL, false, talk)
			_tell("sans Sceaux", starter, talk, r)
			assert_float(r["mean"]).override_failure_message("%s, %s : sans Sceaux, %.1f tours (attendu %d-%d)" % [
				NAMES[starter], HOW[talk], r["mean"], ALONE.x, ALONE.y]).is_between(ALONE.x, ALONE.y)
			assert_int(r["calmed"]).override_failure_message("%s : pas toujours apaisé (%d %%)" % [NAMES[starter], r["calmed"]]).is_equal(100)


## Les cinq Sceaux bien placés (comme dit la leçon : on parle, on appelle ceux du calme tout de suite, le Marais et la
## Côte quand l'équipe souffre) : 8-12 tours. En l'usant d'abord, c'est plus long, mais les Sceaux font gagner au
## moins MIN_SAVED tours, et jamais plus de USED_FIRST_MAX.
func test_souverain_avec_les_cinq_sceaux() -> void:
	for starter in STARTERS:
		var alone := _souverain(starter, SOUVERAIN_LEVEL, false, false)
		for id in FIVE:
			Game.give_item(id)
		for talk in [true, false]:
			var r := _souverain(starter, SOUVERAIN_LEVEL, true, talk)
			_tell("avec les cinq Sceaux", starter, talk, r)
			assert_int(r["calmed"]).is_equal(100)
			if talk:
				assert_float(r["mean"]).override_failure_message("%s, %s : avec les Sceaux, %.1f tours (attendu %d-%d)" % [
					NAMES[starter], HOW[talk], r["mean"], HELPED.x, HELPED.y]).is_between(HELPED.x, HELPED.y)
			else:
				assert_float(r["mean"]).override_failure_message("%s, %s : avec les Sceaux, %.1f tours (au plus %d)" % [
					NAMES[starter], HOW[talk], r["mean"], USED_FIRST_MAX]).is_less_equal(USED_FIRST_MAX)
				assert_float(alone["mean"] - r["mean"]).override_failure_message("%s : les Sceaux ne font gagner que %.1f tours" % [
					NAMES[starter], alone["mean"] - r["mean"]]).is_greater_equal(MIN_SAVED)


func _tell(what: String, starter: StringName, talk: bool, r: Dictionary) -> void:
	prints("   %s : le Souverain %s, %s : %.1f tours (%d-%d) ; K.O. %.1f, Caillou %d %%, relèves %.2f, apaisé %d %%" % [
		NAMES[starter], what, HOW[talk], r["mean"], r["p10"], r["p90"], r["kos"], r["caillou"], r["rallies"], r["calmed"]])


# ------------------------------------------------------------------ outils

## L'équipe type. `the_end` : à la fin du jeu, le dino de départ à Lien 5 (l'histoire l'y monte) et les autres à 2
## cœurs (des heures de marche et de combats ensemble) ; sinon comme au Volcan (départ 3 cœurs, les autres 0).
func _team(starter: StringName, lvl: int, the_end: bool) -> Array[Dino]:
	var team: Array[Dino] = []
	var s := Dino.create(starter, lvl, NAMES[starter])
	s.bond = Dino.MAX_BOND if the_end else 3
	team.append(s)
	team.append(Dino.create(STOLEN[starter], lvl - 1))
	team.append(Dino.create(&"plesiosaurus", lvl - 1, "Nessie"))
	team.append(Dino.create(&"baryonyx", lvl - 2, "Bouée"))
	team.append(Dino.create(&"pteranodon", lvl - 2, "Ptéro"))
	if the_end:
		for d in team.slice(1):
			d.bond = OTHERS_BOND
	return team


## Part de victoires (%) contre les quatre dinos d'Isaure à la suite (pas de soin entre eux).
func _isaure_rate(starter: StringName, lvl: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	seed(SEED)   # (le moteur tire aussi au hasard global : pick_random)
	var wins := 0
	var rules := ApexBattles.isaure_rules()
	rules["trainer"] = ApexBattles.ISAURE
	rules["starter"] = starter
	for t in RUNS:
		var team := _team(starter, lvl, false)
		var ok := true
		for m: Array in ApexBattles.isaure_team():
			var foe := Dino.create(m[0], m[1], m[2])
			var e := ApexEngine.new(team, foe, rules)
			e.rng.seed = rng.randi()
			_fight(e, false)
			if e.result != "win":
				ok = false
				break
		if ok:
			wins += 1
	return roundi(100.0 * wins / RUNS)


## Le combat du Souverain, RUNS fois : {"mean", "p10", "p90" (tours), "kos" (K.O. par combat), "caillou" (% des
## combats où Caillou a pris un coup), "rallies" (relèves par combat), "calmed" (%)}.
func _souverain(starter: StringName, lvl: int, sceaux: bool, talk: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	seed(SEED)   # (le moteur tire aussi au hasard global : pick_random)
	var turns: Array[int] = []
	var rallies := 0
	var calmed := 0
	var kos := 0
	var caillou := 0
	var rules := ApexBattles.souverain_rules()
	rules["starter"] = starter
	for t in RUNS:
		Game.items[BattleEngine.ANTIDOTE] = 1
		var e := ApexEngine.new(_team(starter, lvl, true), ApexBattles.souverain(), rules)
		e.rng.seed = rng.randi()
		_seen.clear()
		turns.append(_fight(e, sceaux, talk))
		kos += _seen.count("faint")
		caillou += 1 if _seen.has("caillou") else 0
		rallies += e.rallies
		if e.result == "calmed":
			calmed += 1
	turns.sort()
	var total := 0
	for n in turns:
		total += n
	return {"mean": float(total) / RUNS, "p10": turns[int(RUNS * 0.1)], "p90": turns[int(RUNS * 0.9)],
		"kos": float(kos) / RUNS, "caillou": roundi(100.0 * caillou / RUNS), "rallies": float(rallies) / RUNS,
		"calmed": roundi(100.0 * calmed / RUNS)}


## Un combat joué jusqu'au bout ; retourne les tours (ni les entrées après un K.O., ni les Sceaux : ils ne coûtent
## pas le tour).
func _fight(e: ApexEngine, sceaux: bool, talk := false) -> int:
	var turns := 0
	var actions := 0
	while not e.over and turns < MAX_TURNS and actions < MAX_TURNS * 2:
		actions += 1
		if e.must_switch:
			for i in e.team.size():
				if e.can_switch_to(i):
					e.turn({"type": "switch", "index": i})
					break
			continue
		var action := _choose(e, sceaux, talk)
		if action["type"] != "sceau":
			turns += 1
		for x: Dictionary in e.turn(action):
			if x["type"] == "caillou" or x["type"] == "faint" and x["side"] == "player":
				_seen.append(x["type"])
	return turns


## Ce que joue l'enfant simulé : l'Ambre clair dès qu'il agit ; les Sceaux bien placés (le Marais quand l'équipe
## souffre, la Côte avant un gros coup, le givre puis le calme une fois qu'il écoute à mi-vie) ; sinon le meilleur coup
## jusqu'à mi-vie, puis « Apaiser ».
func _choose(e: ApexEngine, sceaux: bool, talk := false) -> Dictionary:
	var foe := e.foe
	if e.can_use_antidote():
		return {"type": "antidote"}
	var listening: bool = talk or foe.hp <= floori(foe.max_hp() / 2.0)
	if sceaux:
		var me := e.player()
		var down := e.team.any(func(d: Dino) -> bool: return d.hp <= 0)
		if e.can_call("sceau_marais") and (me.hp < me.max_hp() * 0.4 or down):
			return {"type": "sceau", "id": "sceau_marais"}
		if e.can_call("sceau_cote") and me.hp < me.max_hp() * 0.6:
			return {"type": "sceau", "id": "sceau_cote"}
		if foe.corrupted and listening:
			for id in ["sceau_monts", "sceau_volcan", "sceau_desert"]:
				if e.can_call(id):
					return {"type": "sceau", "id": id}
	if foe.corrupted and listening:
		return {"type": "calm"}
	return {"type": "move", "index": _best(e.player(), foe)}


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
