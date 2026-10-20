extends GdUnitTestSuite
## Le branchement des revanches dans le moteur commun (patch_C.md § 1, battle/battle_engine.gd), sans fenêtre, sur le
## vrai moteur : la règle « sceaux_libres » (BattleEngine.libres, jamais contre l'Alpha de la règle « alpha »),
## l'appel par turn() (le tour gardé), la Charge (le prochain coup compte double, une fois), la Meute (deux coups en
## un tour), le chant de Minuit (le prochain coup reçu adouci), Cheminée (l'adversaire ne bouge pas), le moteur sous
## l'eau aussi ; « foe_stages » (l'Alpha chez lui) ; « foe_faint » (« Il s'arrête. Il a vu. », jamais « K.O. ») ; le
## texte des crans (« L'attaque du Tricératops », plus « de Le »). Échoue tant que le correctif n'est pas appliqué.

const SAVE_PATH := "user://test_gdunit_sceaux_branches_save.json"
const PATCH := "patch_C.md § 1 (battle/battle_engine.gd) pas appliqué"

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
	Game.day = 3
	for s: Dictionary in ApexEngine.LIBRES:
		Game.set_flag(ApexEngine.woken_flag(s["id"]))


func _team() -> Array[Dino]:
	var team: Array[Dino] = [Dino.create(&"velociraptor", 50, "Vif"), Dino.create(&"plesiosaurus", 49, "Nessie"),
		Dino.create(&"pteranodon", 48, "Ptéro")]
	return team


func _engine(rules := {"sceaux_libres": true}, seed_value := 11) -> BattleEngine:
	var e := BattleEngine.new(_team(), Dino.create(&"triceratops", 50), rules)
	e.rng.seed = seed_value
	return e


## Le correctif est-il là ? (sinon les autres tests sont sautés, et celui-ci échoue en le disant)
static func _patched() -> bool:
	var team: Array[Dino] = [Dino.create(&"velociraptor", 5)]
	return "libres" in BattleEngine.new(team, Dino.create(&"velociraptor", 5), {})


func test_la_regle_pose_les_sceaux_libres() -> void:
	var e := _engine()
	assert_bool("libres" in e).override_failure_message(PATCH).is_true()
	if not _patched():
		return
	assert_object(e.get(&"libres")).is_not_null()
	assert_object(_engine({}).get(&"libres")).override_failure_message("sans la règle").is_null()
	var against := _engine({"sceaux_libres": true, "alpha": "sceau_plaines"})
	assert_bool(against.get(&"libres").can_call("sceau_plaines")).override_failure_message("contre lui-même").is_false()
	var under := UnderwaterEngine.new(_team(), Dino.create(&"plesiosaurus", 50), {"sceaux_libres": true})
	assert_object(under.get(&"libres")).override_failure_message("sous l'eau").is_not_null()


func test_l_appel_par_turn_garde_le_tour(do_skip := not _patched(), skip_reason := PATCH) -> void:
	var e := _engine()
	var hp := [e.player().hp, e.foe.hp]
	var ev := e.turn({"type": "sceau", "id": "sceau_desert"})
	assert_str(String(ev[0]["type"])).is_equal("sceau")
	assert_bool(ev.any(func(x: Dictionary) -> bool: return x["type"] == "move")).override_failure_message("quelqu'un a agi").is_false()
	assert_array([e.player().hp, e.foe.hp]).is_equal(hp)
	assert_int(e.stages["foe"]["atk"]).is_equal(-2)
	var said := " ".join(ev.map(func(x: Dictionary) -> String: return String(x.get("text", ""))))
	assert_str(said).contains("L'attaque du Tricératops baisse beaucoup")
	assert_str(said).not_contains("de Le ")
	assert_array(e.turn({"type": "sceau", "id": "sceau_desert"})).override_failure_message("deux fois le même jour").is_empty()


func test_la_charge_double_le_prochain_coup(do_skip := not _patched(), skip_reason := PATCH) -> void:
	var a := _engine({"sceaux_libres": true}, 5)
	var b := _engine({}, 5)
	a.turn({"type": "sceau", "id": "sceau_plaines"})
	var move := MovesDB.move(a.player().moves[0]["id"])
	var doubled: int = a._damage("player", "foe", move)["damage"]
	var plain: int = b._damage("player", "foe", move)["damage"]
	assert_int(doubled).is_equal(plain * 2)
	assert_int(a._damage("player", "foe", move)["damage"]).override_failure_message("doublé deux fois").is_less(doubled)


func test_minuit_adoucit_le_prochain_coup_recu(do_skip := not _patched(), skip_reason := PATCH) -> void:
	var a := _engine({"sceaux_libres": true}, 6)
	var b := _engine({}, 6)
	a.turn({"type": "sceau", "id": "sceau_cote"})
	var move := MovesDB.move(a.foe.moves[0]["id"])
	assert_int(a._damage("foe", "player", move)["damage"]).is_equal(maxi(1, roundi(b._damage("foe", "player", move)["damage"] * 0.5)))


func test_la_meute_deux_coups_en_un_tour(do_skip := not _patched(), skip_reason := PATCH) -> void:
	var e := _engine()
	e.foe.hp = e.foe.max_hp()
	e.turn({"type": "sceau", "id": "sceau_foret"})
	var ev := e.turn({"type": "move", "index": 0})
	var mine := ev.filter(func(x: Dictionary) -> bool: return x["type"] == "move" and x["side"] == "player")
	assert_int(mine.size()).is_equal(2)
	var next := e.turn({"type": "move", "index": 0}) if not e.over else []
	assert_int(next.filter(func(x: Dictionary) -> bool: return x["type"] == "move" and x["side"] == "player").size()).is_less_equal(1)


func test_cheminee_l_adversaire_ne_bouge_pas(do_skip := not _patched(), skip_reason := PATCH) -> void:
	var e := _engine()
	e.turn({"type": "sceau", "id": "sceau_volcan"})
	var ev := e.turn({"type": "move", "index": 0})
	assert_bool(ev.any(func(x: Dictionary) -> bool: return x["type"] == "move" and x["side"] == "foe")).override_failure_message(
		"il a bougé").is_false()
	assert_bool(ev.any(func(x: Dictionary) -> bool: return String(x.get("text", "")).contains("regarde Cheminée"))).is_true()


func test_l_alpha_chez_lui_et_sa_chute(do_skip := not _patched(), skip_reason := PATCH) -> void:
	var rules := RevancheBattles.alpha_rules(&"foret")
	var e := BattleEngine.new(_team(), RevancheBattles.alpha(&"foret"), rules)
	for stat: String in rules["foe_stages"]:
		assert_int(e.stages["foe"][stat]).override_failure_message("%s : pas chez lui (%s)" % [stat, PATCH]).is_equal(rules["foe_stages"][stat])
	e.foe.hp = 1
	var ev: Array = []
	e._hurt("foe", 10)
	e._check_faints(ev)
	assert_str(String(ev[0]["text"])).is_equal("Il s'arrête. Il a vu.")
	var wild := _engine({})
	wild.foe.hp = 0
	var ev2: Array = []
	wild._check_faints(ev2)
	assert_str(String(ev2[0]["text"])).contains("K.O.")


func test_le_dernier_combat_n_a_pas_les_libres() -> void:
	var e := ApexEngine.new(_team(), ApexBattles.souverain(), ApexBattles.souverain_rules())
	assert_object(e.get(&"libres")).is_null()
	assert_bool(ApexEngine.libres_ok(ApexBattles.souverain_rules())).is_false()
