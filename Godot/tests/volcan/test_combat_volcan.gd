extends GdUnitTestSuite
## Les combats de la Plaine Volcanique (chapitre 8), sans fenêtre : la logique de
## tools/test_combat_volcan.gd (la règle « volcan » et le choix du fond, l'équipe de Brac, les
## corrompus numérotés, le T-Rex de Magma et sa leçon vraie sur la table des types, l'antidote,
## l'équilibrage par simulation sur le moteur réel), sans le combat à l'écran (partie (e) de
## l'ancien test : fond affiché, braises, Sac touché, captures).

const BATTLE_LOOK := "res://battle/battle_volcan.gd"
const MONTS_STAGE := preload("res://story/monts_stage.gd")
## Comme l'ancien test : 120 combats par cas, graine 48, le meilleur coup, jamais de soin.
const RUNS := 120
const SEED := 48
const TREX_MIN := 70
const TREX_MAX := 100
const BRAC_MIN := 70
const STARTERS: Array[StringName] = [&"velociraptor", &"ankylosaurus", &"parasaurolophus"]
## Le 3e petit de l'équipe type : celui que l'Ombre a volé (le départ de l'un est le volé de l'autre).
const STOLEN := {&"velociraptor": &"parasaurolophus", &"ankylosaurus": &"velociraptor", &"parasaurolophus": &"ankylosaurus"}
const MAX_TURNS := 90
const SAVE_PATH := "user://test_gdunit_combat_save.json"

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
	Game.set_flag(&"tuto_commandes")


# ------------------------------------------------------------------ (a) le volcan (règle, fond)

func test_regle_volcan_cinq_zones_pas_ailleurs() -> void:
	var look: GDScript = load(BATTLE_LOOK)
	for zone: StringName in [&"champs_cendres", &"forges_ombre", &"coulees_lave", &"sanctuaire_magma", &"porte_cratere"]:
		assert_bool(look.applies({}, zone)).override_failure_message("%s : pas au volcan" % zone).is_true()
	assert_bool(look.applies({}, &"cieux")).override_failure_message("les Cieux sont au volcan").is_false()
	assert_bool(look.applies({"volcan": true}, &"monts")).override_failure_message("la règle « volcan » ne force pas").is_true()
	assert_bool(look.applies({"volcan": false}, &"coulees_lave")).override_failure_message("la règle « volcan » ne coupe pas").is_false()
	var pick: Array = look.backdrop()
	var own := ResourceLoader.exists(look.BACKDROP)
	if not own:
		prints("   fond : repli réchauffé (volcan.jpg pas encore livré)")
	assert_bool(pick[0] is Texture2D).is_true()
	assert_bool((pick[0] as Texture2D).resource_path == look.BACKDROP).override_failure_message(
		"fond : %s (volcan.jpg %s)" % [(pick[0] as Texture2D).resource_path, "livré" if own else "absent"]).is_equal(own)


# ------------------------------------------------------------------ (b) Brac, les numéros, le T-Rex

func test_equipe_de_brac() -> void:
	var team: Array = VolcanBattles.brac_team()
	var names: Array = team.map(func(m: Array) -> String: return m[2])
	assert_array(names).override_failure_message("l'équipe de Brac : %s" % [names]).contains_exactly(["Cabosse", "Grognon", "Mastoc", "Fournaise"])
	var levels: Array = team.map(func(m: Array) -> int: return m[1])
	assert_array(levels).override_failure_message("niveaux de l'équipe de Brac : %s (43, 43, 44, 45 simulés)" % [levels]).contains_exactly([43, 43, 44, 45])
	assert_bool(team.all(func(m: Array) -> bool: return (m[3] as Dictionary).has("before"))) \
		.override_failure_message("un dino de Brac entre sans sa réplique").is_true()
	var last: Dictionary = team[3][3]
	assert_str(String(team[3][0])).is_equal("daspletosaurus")
	assert_bool(last.get("corrupted", false) and last.get("long_calm", false)) \
		.override_failure_message("Fournaise : pas corrompu ou pas d'apaisement long").is_true()
	assert_str(String(last.get("lesson", [""])[0])).contains("s'apaise")


func test_fournaise_rejoint_chloe() -> void:
	var f := VolcanBattles.fournaise()
	assert_str(f.nickname).is_equal("Fournaise")
	assert_int(f.level).is_equal(45)
	assert_int(f.bond).override_failure_message("Fournaise sans son cœur de Lien").is_equal(1)
	assert_bool(Abilities.usable(f, &"cuir_de_feu")).override_failure_message("Fournaise ne porte pas Chloé sur la lave").is_true()


func test_les_corrompus_numerotes() -> void:
	for n in [3, 7, 11, 12]:
		var d := VolcanBattles.numero(n)
		assert_bool(d.corrupted).override_failure_message("Numéro %d (%s) pas corrompu" % [n, d.species().display_name]).is_true()
		assert_bool(VolcanBattles.numero_rules(n).get("catch", true)).override_failure_message("Numéro %d : un collier possible" % n).is_false()
		assert_int(d.level).override_failure_message("Numéro %d : niv. %d hors du volcan" % [n, d.level]).is_between(42, 48)


func test_trex_de_magma_niveau_48_combat_d_honneur() -> void:
	var trex := VolcanBattles.trex()
	var rules := VolcanBattles.trex_rules()
	assert_int(trex.level).is_equal(48)
	assert_str(trex.type()).is_equal("feu")
	assert_bool(rules["catch"]).override_failure_message("un collier possible sur le T-Rex").is_false()
	assert_bool(rules["run"]).override_failure_message("on peut fuir le T-Rex").is_false()
	assert_float(rules["size"]).is_equal_approx(1.2, 0.001)
	assert_bool(rules.has("music")).override_failure_message("pas de musique des Alphas").is_true()


## La leçon du T-Rex, vraie sur la table des types : il craint l'Eau et la Terre ; ses flammes brûlent
## le Vent et la Nature ; la Pierre et l'Eau tiennent bon.
func test_lecon_du_trex_vraie_sur_la_table_des_types() -> void:
	var lesson := " ".join(VolcanBattles.trex_rules()["lesson"])
	for t in ["eau", "terre"]:
		assert_float(MovesDB.effectiveness(t, "feu")).override_failure_message("la table : %s contre Feu n'est pas fort" % t).is_greater(1.0)
	for t in ["vent", "nature"]:
		assert_float(MovesDB.effectiveness("feu", t)).override_failure_message("la table : Feu contre %s n'est pas fort" % t).is_greater(1.0)
	for t in ["pierre", "eau"]:
		assert_float(MovesDB.effectiveness("feu", t)).override_failure_message("la table : %s ne résiste pas au Feu" % t).is_less(1.0)
	assert_str(lesson).contains("l'Eau et la Terre le touchent fort")
	assert_str(lesson).contains("Vent et de Nature")
	assert_str(lesson).contains("la Pierre et l'Eau")
	# Rien d'autre que l'Eau et la Terre ne le touche fort (la leçon n'en oublie pas).
	var strong: Array = MovesDB.TYPE_NAMES.keys().filter(func(t: String) -> bool: return MovesDB.effectiveness(t, "feu") > 1.0)
	assert_array(strong).override_failure_message("touchent fort le Feu : %s" % [strong]).contains_exactly_in_any_order(["eau", "terre"])


## La leçon que la scène du sanctuaire calcule (VolcanSanctuaire.lesson, depuis la table des types),
## et celle que le combat montre vraiment (les règles de VolcanBattles l'emportent : Volcan.from_battles).
func test_lesson_du_sanctuaire_coherente_avec_la_table() -> void:
	var trex := VolcanBattles.trex()
	var lines := VolcanSanctuaire.lesson(trex)
	assert_array(lines).override_failure_message("VolcanSanctuaire.lesson : aucune leçon pour le T-Rex").is_not_empty()
	if lines.is_empty():
		return
	var line := String(lines[0])
	assert_str(line).override_failure_message("lesson() : « %s »" % line).starts_with("L'Eau et la Terre le touchent fort")
	for t: String in MovesDB.TYPE_CHART:
		var word: String = MONTS_STAGE.TYPE_WORDS[t]
		var resists := MovesDB.effectiveness(t, "feu") < 1.0
		var said := line.split(";")[-1].containsn(word) if line.contains(";") else false
		assert_bool(said).override_failure_message("lesson() : « %s » dit %s pour %s (×%.1f contre le Feu)" % [
			line, "qu'il le traverse" if said else "rien", word, MovesDB.effectiveness(t, "feu")]).is_equal(resists)
	var rules := {"lesson": lines}
	rules.merge(Volcan.from_battles(&"trex_rules", [], {}), true)
	assert_array(rules["lesson"]).override_failure_message("le combat du sanctuaire ne montre pas la leçon de VolcanBattles").contains_exactly(VolcanBattles.TREX_LESSON)


# ------------------------------------------------------------------ (c) l'antidote

func test_antidote_seulement_au_dernier_combat_sur_un_corrompu() -> void:
	var vif := Dino.create(&"velociraptor", 45, "Vif")
	Game.party.append(vif)
	Game.give_item(BattleEngine.ANTIDOTE)
	var plain := BattleEngine.new(Game.party, VolcanBattles.numero(3), {})
	assert_bool(plain.can_use_antidote()).override_failure_message("hors du dernier combat : l'antidote se verse").is_false()
	assert_array(plain.turn({"type": "antidote"})).is_empty()
	assert_int(Game.item_count(BattleEngine.ANTIDOTE)).override_failure_message("hors du dernier combat : la dose est partie").is_equal(1)
	var on_wild := BattleEngine.new(Game.party, Dino.create(&"styracosaurus", 43), {"antidote": true})
	assert_bool(on_wild.can_use_antidote()).override_failure_message("sur un dino pas corrompu : l'antidote se verse").is_false()
	var foe := Dino.create(&"daspletosaurus", 45, "Fournaise")
	foe.corrupted = true
	var e := BattleEngine.new(Game.party, foe, {"antidote": true, "long_calm": true})
	var hp := vif.hp
	assert_bool(e.can_use_antidote()).override_failure_message("le dernier combat, un corrompu, la dose : impossible").is_true()
	var kinds: Array = e.turn({"type": "antidote"}).map(func(x: Dictionary) -> String: return x["type"])
	assert_bool(e.over and e.result == "calmed").override_failure_message("une goutte : pas apaisé d'un coup (%s, %s)" % [e.over, e.result]).is_true()
	assert_bool(foe.corrupted).override_failure_message("les veines ne s'effacent pas").is_false()
	assert_array(kinds).contains(["antidote", "calmed"]).not_contains(["move"])
	assert_int(vif.hp).override_failure_message("le corrompu a agi ce tour-là").is_equal(hp)
	assert_int(Game.item_count(BattleEngine.ANTIDOTE)).override_failure_message("la dose n'est pas partie (une seule)").is_equal(0)
	assert_bool(e.can_use_antidote()).is_false()


# ------------------------------------------------------------------ (d) l'équilibrage

func test_equilibrage_trex_48_contre_une_equipe_de_45() -> void:
	for starter in STARTERS:
		var rate := _rate(starter, 45, [[&"trex_magma", 48, "T-Rex de Magma", false, false]])
		prints("   %s : T-Rex 48 contre une équipe de 45 : %d %%" % [starter, rate])
		assert_int(rate).override_failure_message("%s : T-Rex 48 contre une équipe de 45 : %d %% (attendu %d-%d : difficile, jamais impossible)" % [
			starter, rate, TREX_MIN, TREX_MAX]).is_between(TREX_MIN, TREX_MAX)


func test_equilibrage_brac_contre_une_equipe_de_44() -> void:
	var foes: Array = VolcanBattles.brac_team().map(func(m: Array) -> Array:
		return [m[0], m[1], m[2], (m[3] as Dictionary).get("corrupted", false), (m[3] as Dictionary).get("long_calm", false)])
	for starter in STARTERS:
		var rate := _rate(starter, 44, foes)
		prints("   %s : Brac contre une équipe de 44 : %d %%" % [starter, rate])
		assert_int(rate).override_failure_message("%s : Brac contre une équipe de 44 : %d %% (attendu ≥ %d)" % [starter, rate, BRAC_MIN]).is_greater_equal(BRAC_MIN)


# ------------------------------------------------------------------ outils

## Part de victoires (%) d'une équipe type (départ L, 3e petit L-1, Nessie L-1, Bouée L-2, Ptéro L-2)
## contre `foes` à la suite ([espèce, niveau, nom, corrompu, apaisement long]) : le meilleur coup,
## « Apaiser » un corrompu à mi-vie, jamais de soin. Le même calcul que tools/test_combat_volcan.gd.
func _rate(starter: StringName, lvl: int, foes: Array) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var wins := 0
	for t in RUNS:
		var team: Array[Dino] = []
		var s := Dino.create(starter, lvl, "Départ")
		s.bond = 3
		team.append(s)
		team.append(Dino.create(STOLEN[starter], lvl - 1))
		team.append(Dino.create(&"plesiosaurus", lvl - 1, "Nessie"))
		team.append(Dino.create(&"baryonyx", lvl - 2, "Bouée"))
		team.append(Dino.create(&"pteranodon", lvl - 2, "Ptéro"))
		var ok := true
		for f: Array in foes:
			var foe := Dino.create(f[0], f[1], f[2])
			foe.corrupted = f[3]
			var e := BattleEngine.new(team, foe, {"starter": starter, "long_calm": f[4], "trainer": "Brac" if foes.size() > 1 else ""})
			e.rng.seed = rng.randi()
			var turns := 0
			while not e.over and turns < MAX_TURNS:
				turns += 1
				if e.must_switch:
					for i in team.size():
						if e.can_switch_to(i):
							e.turn({"type": "switch", "index": i})
							break
					continue
				if foe.corrupted and foe.hp <= floori(foe.max_hp() / 2.0):
					e.turn({"type": "calm"})
				else:
					e.turn({"type": "move", "index": _best(e.player(), foe)})
			if e.result != "win" and e.result != "calmed":
				ok = false
				break
		if ok:
			wins += 1
	return roundi(100.0 * wins / RUNS)


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
