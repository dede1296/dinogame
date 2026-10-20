extends GdUnitTestSuite
## Les Sceaux libres (ApexEngine.LIBRES, ApexEngine.Libres ; docs/post-game-plan.md § 3), sans fenêtre : quand un combat
## les a (l'insigne et un Sceau éveillé ; jamais au Relais ni au dernier combat), la carte de chacun (dans l'ordre de
## l'île ; jamais contre l'Alpha lui-même ; un appel par jour), l'appel (le tour gardé, les sept effets, dont les deux
## nouveaux : la Charge du Tricératops et la Meute du Chef), les textes (rien de « {…} » qui reste, l'adversaire nommé).
## Le branchement dans le moteur commun (BattleEngine : turn, _damage, _use_move) : test_sceaux_branches.gd.

const SAVE_PATH := "user://test_gdunit_sceaux_libres_save.json"
const ALL: Array[String] = ["sceau_plaines", "sceau_foret", "sceau_marais", "sceau_desert", "sceau_cote", "sceau_monts", "sceau_volcan"]

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
	Game.give_item(ApexEngine.INSIGNE)
	Game.day = 7


func _wake(ids: Array) -> void:
	for id: String in ids:
		Game.set_flag(ApexEngine.woken_flag(id))


func _team() -> Array[Dino]:
	var team: Array[Dino] = [Dino.create(&"velociraptor", 50, "Vif"), Dino.create(&"plesiosaurus", 49, "Nessie"),
		Dino.create(&"pteranodon", 48, "Ptéro")]
	return team


func _libres(alpha := "") -> ApexEngine.Libres:
	var e := BattleEngine.new(_team(), Dino.create(&"triceratops", 45), {})
	return ApexEngine.libres_for(e, alpha)


# ------------------------------------------------------------------ quand un combat les a

func test_libres_ok() -> void:
	assert_bool(ApexEngine.libres_ok({})).override_failure_message("aucun Sceau éveillé").is_false()
	_wake(["sceau_desert"])
	assert_bool(ApexEngine.libres_ok({})).is_true()
	assert_bool(ApexEngine.libres_ok({"catch": false, "run": false, "trainer": "Maïa"})).is_true()
	assert_bool(ApexEngine.libres_ok({"sceaux_libres": false})).override_failure_message("au Relais").is_false()
	assert_bool(ApexEngine.libres_ok(ApexBattles.souverain_rules())).override_failure_message("au dernier combat").is_false()
	Game.use_item(ApexEngine.INSIGNE)
	assert_bool(ApexEngine.libres_ok({})).override_failure_message("sans l'insigne").is_false()


func test_sept_sceaux_dans_l_ordre_de_l_ile() -> void:
	var ids: Array = ApexEngine.LIBRES.map(func(s: Dictionary) -> String: return s["id"])
	assert_array(ids).is_equal(ALL)
	for s: Dictionary in ApexEngine.LIBRES:
		assert_bool(SpeciesDB.PATHS.has(s["alpha"])).override_failure_message("%s : Alpha %s inconnu" % [s["id"], s["alpha"]]).is_true()
		for key in ["name", "what", "effect", "text"]:
			assert_bool(s.has(key)).override_failure_message("%s sans « %s »" % [s["id"], key]).is_true()
	var mine: Array = RevancheBattles.ALPHAS.values().map(func(a: Dictionary) -> String: return a["sceau"])
	assert_array(mine).override_failure_message("les Sceaux des revanches et ceux du combat").is_equal(ALL)


func test_la_carte_les_sceaux_eveilles_dans_l_ordre() -> void:
	_wake(["sceau_volcan", "sceau_plaines", "sceau_desert"])
	var l := _libres()
	var ids: Array = l.owned_sceaux().map(func(s: Dictionary) -> String: return s["id"])
	assert_array(ids).is_equal(["sceau_plaines", "sceau_desert", "sceau_volcan"])
	assert_bool(l.can_call_any()).is_true()
	assert_bool(l.can_call("sceau_foret")).override_failure_message("pas éveillé").is_false()


func test_jamais_contre_l_alpha_lui_meme() -> void:
	_wake(["sceau_plaines", "sceau_foret"])
	var l := _libres("sceau_plaines")
	assert_bool(l.can_call("sceau_plaines")).is_false()
	assert_str(l.why_not("sceau_plaines")).is_equal(ApexEngine.NOT_HIMSELF)
	assert_bool(l.can_call("sceau_foret")).is_true()
	assert_array(l.call_sceau("sceau_plaines")).is_empty()


func test_un_appel_par_alpha_et_par_jour() -> void:
	_wake(["sceau_marais", "sceau_cote"])
	var l := _libres()
	assert_array(l.call_sceau("sceau_marais")).is_not_empty()
	assert_int(int(Game.flag(&"sceau_marais_jour"))).is_equal(Game.day)
	assert_bool(l.can_call("sceau_marais")).is_false()
	assert_str(l.why_not("sceau_marais")).is_equal(ApexEngine.TOMORROW)
	assert_array(l.call_sceau("sceau_marais")).override_failure_message("deux fois le même jour").is_empty()
	assert_bool(_libres().can_call("sceau_marais")).override_failure_message("dans le combat suivant, le même jour").is_false()
	assert_bool(l.can_call("sceau_cote")).override_failure_message("un Alpha bloque l'autre").is_true()
	Game.day += 1
	assert_bool(_libres().can_call("sceau_marais")).override_failure_message("le lendemain").is_true()


func test_pas_pendant_un_k_o_ni_combat_fini() -> void:
	_wake(["sceau_marais"])
	var l := _libres()
	l.engine.must_switch = true
	assert_bool(l.can_call("sceau_marais")).is_false()
	l.engine.must_switch = false
	l.engine.over = true
	assert_bool(l.can_call("sceau_marais")).is_false()


# ------------------------------------------------------------------ l'appel : le tour gardé, les effets

func test_l_appel_garde_le_tour() -> void:
	_wake(ALL)
	for id in ALL:
		Game.day += 1
		var l := _libres()
		var hp := [l.engine.player().hp, l.engine.foe.hp]
		var ev := l.call_sceau(id)
		assert_str(String(ev[0]["type"])).is_equal("sceau")
		assert_str(String(ev[-1]["type"])).is_equal("sceau_end")
		assert_bool(ev.any(func(x: Dictionary) -> bool: return x["type"] in ["move", "damage", "faint"])).override_failure_message(
			"%s : quelqu'un a agi" % id).is_false()
		if id != "sceau_marais":
			assert_array([l.engine.player().hp, l.engine.foe.hp]).is_equal(hp)
		for x: Dictionary in ev:
			var t := String(x.get("text", ""))
			assert_str(t).override_failure_message("%s : « %s »" % [id, t]).not_contains("{")


func test_le_tricératops_le_prochain_coup_compte_double() -> void:
	_wake(["sceau_plaines"])
	var l := _libres()
	var ev := l.call_sceau("sceau_plaines")
	assert_str(String(ev[0]["text"])).contains("le prochain coup de Vif compte double")
	assert_int(l.scale("foe", 30)).override_failure_message("le coup de l'adversaire doublé").is_equal(30)
	assert_int(l.scale("player", 30)).is_equal(60)
	assert_int(l.scale("player", 30)).override_failure_message("doublé deux fois").is_equal(30)


func test_la_meute_il_agit_deux_fois_une_fois() -> void:
	_wake(["sceau_foret"])
	var l := _libres()
	assert_bool(l.twice()).is_false()
	var ev := l.call_sceau("sceau_foret")
	assert_str(String(ev[0]["text"])).contains("Vif agit deux fois")
	assert_bool(l.twice()).is_true()
	assert_bool(l.twice()).is_false()


func test_le_spinosaure_soigne_toute_l_equipe_meme_au_sol() -> void:
	_wake(["sceau_marais"])
	var l := _libres()
	l.engine.team[0].hp = 3
	l.engine.team[0].status = "saigne"
	l.engine.team[2].hp = 0
	var ev := l.call_sceau("sceau_marais")
	for d in l.engine.team:
		assert_int(d.hp).is_equal(d.max_hp())
	assert_str(l.engine.team[0].status).is_empty()
	assert_bool(ev.any(func(x: Dictionary) -> bool: return x["type"] == "heal")).is_true()


func test_piment_et_toupet_baissent_l_attaque_et_la_vitesse() -> void:
	_wake(["sceau_desert", "sceau_monts"])
	var l := _libres()
	var roar := l.call_sceau("sceau_desert")
	assert_int(l.engine.stages["foe"]["atk"]).is_equal(-2)
	assert_bool(roar.any(func(x: Dictionary) -> bool: return x["type"] == "stat" and x["side"] == "foe")).is_true()
	var frost := l.call_sceau("sceau_monts")
	assert_int(l.engine.stages["foe"]["spd"]).is_equal(-2)
	assert_str(_said(frost)).contains("les pattes du Tricératops")
	assert_int(l.engine.stages["player"]["atk"]).is_equal(0)


func test_minuit_le_prochain_coup_adouci() -> void:
	_wake(["sceau_cote"])
	var l := _libres()
	var ev := l.call_sceau("sceau_cote")
	assert_str(_said(ev)).contains("Le prochain coup du Tricératops sera deux fois plus doux")
	assert_int(l.scale("player", 30)).is_equal(30)
	assert_int(l.scale("foe", 30)).is_equal(15)
	assert_int(l.scale("foe", 30)).is_equal(30)
	l.call_sceau("sceau_cote")   # (déjà venu aujourd'hui : rien)
	assert_int(l.scale("foe", 1)).override_failure_message("jamais 0").is_equal(1)


func test_cheminee_il_ne_bouge_pas_a_sa_prochaine_action() -> void:
	_wake(["sceau_volcan"])
	var l := _libres()
	var ev := l.call_sceau("sceau_volcan")
	assert_str(_said(ev)).contains("à côté du Tricératops,")
	var held: Array = []
	assert_bool(l.holds("player", held)).override_failure_message("Chloé arrêtée").is_false()
	assert_bool(l.holds("foe", held)).is_true()
	assert_str(_said(held)).is_equal("Le Tricératops regarde Cheminée, et ne bouge pas.")
	assert_bool(l.holds("foe", held)).override_failure_message("deux fois").is_false()


func test_un_dresseur_ou_un_alpha_nommes() -> void:
	_wake(["sceau_volcan"])
	var e := BattleEngine.new(_team(), Dino.create(&"triceratops", 51, "Caillou"), {"trainer": "Maïa"})
	var ev := ApexEngine.libres_for(e).call_sceau("sceau_volcan")
	assert_str(_said(ev)).contains("à côté de Caillou")
	Game.day += 1
	var alpha := BattleEngine.new(_team(), RevancheBattles.alpha(&"desert"), {})
	var ev2 := ApexEngine.libres_for(alpha).call_sceau("sceau_volcan")
	assert_str(_said(ev2)).contains("à côté du Carnotaurus Rouge")


func test_le_dernier_combat_garde_les_siens() -> void:
	var e := ApexEngine.new(_team(), ApexBattles.souverain(), ApexBattles.souverain_rules())
	assert_str(e.why_not("sceau_marais")).is_equal("Déjà venu")
	assert_int(ApexEngine.SCEAUX.size()).override_failure_message("les cinq du Souverain ont changé").is_equal(5)


static func _said(ev: Array) -> String:
	return " ".join(ev.map(func(x: Dictionary) -> String: return String(x.get("text", ""))))
