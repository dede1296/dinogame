extends GdUnitTestSuite
## Les règles des deux derniers combats (ApexEngine), sans fenêtre, sur le moteur réel : la jauge triple
## (calm_factor), le Souverain (jamais sous 1 PV, ni capturé ni fui, il frappe en reculant, « Il ne bouge pas » plus
## souvent quand il se calme, sa peur qui revient), les cinq Sceaux (chacun une fois, chacun son effet), Caillou (une
## fois), l'Ambre clair à deux tiers et les trois derniers gestes, pas de défaite (« Encore. »), Carène qui hésite.

const SAVE_PATH := "user://test_gdunit_apex_regles_save.json"
const STARTERS := {&"velociraptor": "Vif", &"ankylosaurus": "Bastion", &"parasaurolophus": "Écho"}
const FIVE: Array[String] = ["sceau_marais", "sceau_desert", "sceau_cote", "sceau_monts", "sceau_volcan"]

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
	Game.give_item(BattleEngine.ANTIDOTE)
	for id in FIVE:
		Game.give_item(id)


# ------------------------------------------------------------------ la jauge, ses règles

func test_jauge_triple_et_regles_d_apexbattles() -> void:
	var rules := ApexBattles.souverain_rules()
	for key in ["calm_factor", "sceaux", "caillou", "antidote", "antidote_min_calm", "rally", "long_calm"]:
		assert_bool(rules.has(key)).override_failure_message("souverain_rules sans « %s »" % key).is_true()
	assert_bool(rules["catch"] or rules["run"]).override_failure_message("on peut capturer ou fuir le Souverain").is_false()
	assert_bool(rules.has("lose_spawn")).override_failure_message("une défaite renvoie ailleurs (on reprend sur place)").is_false()
	assert_bool(rules.has("music")).override_failure_message("pas la musique des Alphas").is_true()
	assert_float(float(rules["antidote_min_calm"])).is_equal_approx(0.66, 0.001)
	var e := _souverain_battle(&"velociraptor")
	assert_int(e.calm_full).override_failure_message("jauge %d, attendu 300 (triple)" % e.calm_full).is_equal(300)
	assert_int(e.threshold()).override_failure_message("seuil de l'Ambre clair %d (deux tiers de 300)" % e.threshold()).is_between(198, 200)
	assert_bool(ApexEngine.applies(rules) and ApexEngine.applies(ApexBattles.isaure_rules())).is_true()
	assert_bool(ApexEngine.applies({"long_calm": true, "antidote": true})).override_failure_message("le chapitre 8 passe par ApexEngine").is_false()
	var plain := ApexEngine.new(_team(&"velociraptor", 48), ApexBattles.souverain(), {"long_calm": true})
	assert_int(plain.calm_full).override_failure_message("sans calm_factor : %d (l'apaisement long reste 160)" % plain.calm_full).is_equal(160)


func test_le_souverain_jamais_sous_1_pv_ni_capture_ni_fui() -> void:
	var e := _souverain_battle(&"velociraptor")
	e._hurt("foe", 9999)
	assert_int(e.foe.hp).is_equal(1)
	assert_str(e.name_of("foe")).is_equal("le Souverain")
	var hp := e.player().hp
	assert_array(e.turn({"type": "catch"})).override_failure_message("un collier sur le Souverain").is_empty()
	assert_array(e.turn({"type": "run"})).override_failure_message("on fuit le Souverain").is_empty()
	assert_bool(e.over).is_false()
	assert_int(e.player().hp).override_failure_message("il a agi pendant un tour gardé").is_equal(hp)


func test_il_frappe_en_reculant() -> void:
	var e := _souverain_battle(&"ankylosaurus")
	e.player().hp = e.player().max_hp()
	for i in e.foe.moves.size():
		var ev: Array = []
		e._use_move("foe", i, ev)
		var said: Array = ev.filter(func(x: Dictionary) -> bool: return x["type"] == "move")
		assert_int(said.size()).is_equal(1)
		if said.is_empty():
			continue
		var text := String(said[0]["text"])
		assert_str(text).override_failure_message("« %s »" % text).starts_with("Le Souverain")
		assert_str(text).override_failure_message("« %s » : il « utilise »" % text).not_contains("utilise")
		e.player().hp = e.player().max_hp()


func test_il_ne_bouge_pas_plus_souvent_quand_il_se_calme() -> void:
	var e := _souverain_battle(&"velociraptor")
	e.rng.seed = 9
	var still_at := func(calm: int) -> float:
		e.calm = calm
		var n := 0
		for k in 2000:
			if e.foe.moves[e._choose_foe_move()]["id"] == ApexEngine.STILL_MOVE:
				n += 1
		return n / 2000.0
	var scared: float = still_at.call(0)
	var listening: float = still_at.call(290)
	prints("   « Il ne bouge pas » : %.0f %% (calme 0), %.0f %% (calme 290)" % [scared * 100.0, listening * 100.0])
	assert_float(scared).is_between(0.15, 0.3)
	assert_float(listening).is_greater(scared + 0.3)


func test_sa_peur_revient_sauf_givre_et_jamais_sous_le_seuil() -> void:
	var e := _souverain_battle(&"velociraptor")
	e.calm = 100
	var ev: Array = []
	e._end_of_turn(ev)
	assert_int(e.calm).is_equal(100 - ApexEngine.FEAR_RETURNS)
	assert_bool(ev.any(func(x: Dictionary) -> bool: return x["type"] == "fear" and x.has("text"))).override_failure_message("la 1re fois, on ne dit pas pourquoi").is_true()
	e._frozen = 2
	e._end_of_turn([])
	e._frighten([])
	assert_int(e.calm).override_failure_message("sous le givre, son calme a baissé").is_equal(100 - ApexEngine.FEAR_RETURNS)
	e.calm = e.threshold()
	e._frozen = 0
	e._tell_listening(ev)
	e._end_of_turn([])
	e._frighten([])
	assert_int(e.calm).override_failure_message("une fois à l'écoute, il est retombé sous le seuil").is_equal(e.threshold())


# ------------------------------------------------------------------ les Sceaux

func test_cinq_sceaux_seulement_les_gardiens_de_coeurs() -> void:
	var ids: Array = ApexEngine.SCEAUX.map(func(s: Dictionary) -> String: return s["id"])
	assert_array(ids).contains_exactly(FIVE)
	var alphas: Array = ApexEngine.SCEAUX.map(func(s: Dictionary) -> StringName: return s["alpha"])
	assert_array(alphas).contains_exactly([&"spinosaurus", &"carnotaurus", &"mosasaure_abyssal", &"cryolophosaure_titan", &"trex_magma"])
	for not_here: StringName in [&"triceratops", &"utahraptor", &"quetzalcoatlus"]:
		assert_bool(not_here in alphas).override_failure_message("%s intervient en combat (décision de Greg : non)" % not_here).is_false()
	Game.give_item("sceau_foret")
	Game.give_item("sceau_cieux")
	Game.set_flag(&"sceau_plaines")
	var e := _souverain_battle(&"velociraptor")
	assert_int(e.owned_sceaux().size()).override_failure_message("Sceaux en combat : %s" % [e.owned_sceaux()]).is_equal(5)
	assert_bool(e.can_call("sceau_foret") or e.can_call("sceau_cieux") or e.can_call("sceau_plaines")).is_false()


func test_chaque_sceau_une_fois() -> void:
	for id in FIVE:
		var e := _souverain_battle(&"velociraptor")
		assert_bool(e.can_call(id)).override_failure_message("%s : ne s'appelle pas" % id).is_true()
		var ev := e.turn({"type": "sceau", "id": id})
		var kinds: Array = ev.map(func(x: Dictionary) -> String: return x["type"])
		assert_array(kinds).override_failure_message("%s : %s" % [id, kinds]).contains(["sceau", "sceau_end"])
		assert_bool(e.can_call(id)).override_failure_message("%s : appelé deux fois" % id).is_false()
		assert_array(e.turn({"type": "sceau", "id": id})).override_failure_message("%s : revient une 2e fois" % id).is_empty()
	var none := _souverain_battle(&"velociraptor")
	Game.items.erase("sceau_cote")
	assert_bool(none.can_call("sceau_cote")).override_failure_message("un Sceau que Chloé n'a pas").is_false()


func test_sceau_du_marais_soigne_toute_l_equipe() -> void:
	var e := _souverain_battle(&"velociraptor")
	for d in e.team:
		d.hp = 3
	e.team[2].hp = 0
	e.turn({"type": "sceau", "id": "sceau_marais"})
	assert_bool(e.team[2].hp > 0).override_failure_message("le dino au sol n'a pas bu").is_true()
	var low: Array = e.team.filter(func(d: Dino) -> bool: return d.hp < d.max_hp() * 0.5)
	assert_int(low.size()).override_failure_message("après l'eau du Spinosaure (et son coup), encore affaiblis : %s" % [low.map(func(d: Dino) -> String: return d.nickname)]).is_less_equal(1)


func test_un_sceau_ne_coute_pas_le_tour() -> void:
	for id in FIVE:
		var e := _souverain_battle(&"velociraptor")
		var hp := e.player().hp
		var ev := e.turn({"type": "sceau", "id": id})
		assert_bool(ev.any(func(x: Dictionary) -> bool: return x["type"] == "move")).override_failure_message("%s : le Souverain a frappé pendant que l'Alpha était là" % id).is_false()
		assert_int(e.player().hp).is_greater_equal(hp)


func test_sceaux_du_desert_et_du_volcan_le_calme() -> void:
	var e := _souverain_battle(&"velociraptor")
	e.calm = 50
	e.turn({"type": "sceau", "id": "sceau_desert"})
	assert_int(e.calm).override_failure_message("Piment : %d, attendu 90" % e.calm).is_equal(90)
	var v := _souverain_battle(&"velociraptor")
	v.calm = 50
	v.turn({"type": "sceau", "id": "sceau_volcan"})
	assert_int(v.calm).override_failure_message("Cheminée : %d" % v.calm).is_equal(110)
	var ev := v.turn({"type": "move", "index": 0})
	var his: Array = ev.filter(func(x: Dictionary) -> bool: return x["type"] == "move" and x["side"] == "foe")
	assert_bool(his.size() == 1 and his[0]["move"] == ApexEngine.STILL_MOVE).override_failure_message(
		"Cheminée couché à côté : le Souverain a agi (%s)" % [his]).is_true()


func test_sceau_de_la_cote_coup_deux_fois_plus_doux() -> void:
	var tail := MovesDB.move(&"queueSouveraine")
	var plain := _souverain_battle(&"velociraptor")
	var sung := _souverain_battle(&"velociraptor")
	sung._soften_next = true
	var a := 0
	var b := 0
	for k in 40:
		plain.rng.seed = k
		sung.rng.seed = k
		sung._soften_next = true
		a += plain._damage("foe", "player", tail)["damage"]
		b += sung._damage("foe", "player", tail)["damage"]
	assert_float(float(b) / a).override_failure_message("le chant de Minuit : ×%.2f" % (float(b) / a)).is_between(0.45, 0.55)
	assert_bool(sung._soften_next).override_failure_message("plus doux pour un seul coup").is_false()


func test_sceau_des_monts_le_calme_ne_retombe_plus_trois_tours() -> void:
	var e := _souverain_battle(&"velociraptor")
	e.calm = 100
	e.turn({"type": "sceau", "id": "sceau_monts"})
	for k in 3:
		e.turn({"type": "move", "index": 0})
	assert_int(e.calm).override_failure_message("sous le givre (3 tours, coups compris) : %d" % e.calm).is_equal(100)
	e.turn({"type": "move", "index": 0})
	assert_int(e.calm).override_failure_message("le givre ne fond pas après 3 tours").is_less(100)


# ------------------------------------------------------------------ Caillou

func test_caillou_prend_le_coup_une_fois() -> void:
	var e := _souverain_battle(&"velociraptor")
	e.player().bond = 0   # (pas de Lien 5 : il ne tiendrait pas tout seul)
	e.player().hp = 2
	var ev: Array = []
	e._use_move("foe", _index_of(e.foe, &"queueSouveraine"), ev)
	var kinds: Array = ev.map(func(x: Dictionary) -> String: return x["type"])
	if kinds.has("miss"):
		ev = []
		e.rng.seed = 3
		e._use_move("foe", _index_of(e.foe, &"tremblement"), ev)
		kinds = ev.map(func(x: Dictionary) -> String: return x["type"])
	assert_array(kinds).override_failure_message("Caillou : %s" % [kinds]).contains(["caillou"])
	assert_int(e.player().hp).override_failure_message("le coup pris par Caillou a porté").is_equal(2)
	assert_bool(ev.any(func(x: Dictionary) -> bool: return String(x.get("text", "")).begins_with("Maïa"))).is_true()
	ev = []
	e._use_move("foe", _index_of(e.foe, &"tremblement"), ev)
	assert_int(e.player().hp).override_failure_message("Caillou a pris un 2e coup").is_equal(0)


# ------------------------------------------------------------------ l'Ambre clair, le dernier geste

func test_ambre_clair_pas_avant_deux_tiers() -> void:
	var e := _souverain_battle(&"velociraptor")
	e.calm = e.threshold() - 1
	var hp := e.player().hp
	assert_bool(e.can_use_antidote()).is_false()
	assert_bool(e.antidote_waits()).override_failure_message("la carte de l'Ambre clair disparaît du Sac").is_true()
	var ev := e.turn({"type": "antidote"})
	assert_int(ev.size()).is_equal(1)
	assert_str(String(ev[0].get("text", ""))).contains("Il faut d'abord qu'il l'écoute")
	assert_int(Game.item_count(BattleEngine.ANTIDOTE)).override_failure_message("la dose est partie trop tôt").is_equal(1)
	assert_int(e.player().hp).override_failure_message("le tour gardé : il a agi").is_equal(hp)
	assert_bool(e.over).is_false()


func test_les_mots_seuls_ne_remplissent_pas_la_jauge_tant_que_la_dose_attend() -> void:
	var e := _souverain_battle(&"velociraptor")
	e.calm = e.calm_full - 5
	e.rng.seed = 1
	for k in 6:
		if e.over:
			break
		e.turn({"type": "calm"})
	assert_bool(e.over).override_failure_message("apaisé par les mots seuls, sans la goutte").is_false()
	assert_int(e.calm).is_less(e.calm_full)
	Game.items.erase(BattleEngine.ANTIDOTE)
	var w := _souverain_battle(&"velociraptor")
	w.calm = w.calm_full - 5
	for k in 20:
		if w.over:
			break
		w.turn({"type": "calm"})
	assert_str(w.result).override_failure_message("sans la dose, les mots ne finissent jamais").is_equal("calmed")


func test_le_dernier_geste_trois_variantes() -> void:
	for starter: StringName in STARTERS:
		Game.new_game()
		Game.give_item(BattleEngine.ANTIDOTE)
		var e := _souverain_battle(starter)
		var me: Dino = e.team[0]
		e.calm = e.threshold()
		var ev := e.turn({"type": "antidote"})
		var variant := String(ApexEngine.GESTURES[starter][0])
		var gestures: Array = ev.filter(func(x: Dictionary) -> bool: return x["type"] == "gesture")
		assert_int(gestures.size()).override_failure_message("%s : %d lignes de geste" % [starter, gestures.size()]).is_greater_equal(2)
		assert_bool(gestures.all(func(x: Dictionary) -> bool: return x["variant"] == variant)).is_true()
		assert_str(String(gestures[0]["text"])).override_failure_message("%s : le geste ne le nomme pas" % starter).contains(me.nickname)
		var drop: Array = ev.filter(func(x: Dictionary) -> bool: return x["type"] == "antidote")
		assert_str(String(drop[0]["text"])).contains("Une seule")
		assert_str(e.result).is_equal("calmed")
		assert_bool(e.foe.corrupted).is_false()
		assert_int(Game.item_count(BattleEngine.ANTIDOTE)).is_equal(0)
		assert_str(String(ev.filter(func(x: Dictionary) -> bool: return x["type"] == "calmed")[0]["text"])).contains("Le Souverain est apaisé")


func test_le_dino_de_depart_entre_ou_se_releve_pour_le_geste() -> void:
	var e := _souverain_battle(&"parasaurolophus")
	e.calm = e.threshold()
	e.active = 1
	e.team[0].hp = 0
	var ev := e.turn({"type": "antidote"})
	var texts: Array = ev.map(func(x: Dictionary) -> String: return String(x.get("text", "")))
	assert_bool(texts.any(func(t: String) -> bool: return t.contains("se relève. Pour Chloé"))).override_failure_message("Écho au sol ne se relève pas : %s" % [texts]).is_true()
	assert_bool(texts.any(func(t: String) -> bool: return t.contains("C'est à lui"))).override_failure_message("Écho n'entre pas : %s" % [texts]).is_true()
	assert_int(e.active).is_equal(0)
	assert_bool(e.team[0].hp > 0).is_true()
	assert_str(e.result).is_equal("calmed")


# ------------------------------------------------------------------ pas de défaite

func test_encore_l_equipe_se_releve_sur_place() -> void:
	var e := _souverain_battle(&"velociraptor")
	e.turn({"type": "sceau", "id": "sceau_desert"})
	e._caillou_used = true
	var calm := e.calm
	for d in e.team:
		d.hp = 0
	e.must_switch = false
	var ev: Array = []
	e._check_faints(ev)
	e._end_of_turn(ev)   # (la fin du tour où l'équipe est tombée : sa peur ne revient pas juste après « Encore. »)
	assert_bool(e.over).override_failure_message("perdu : le combat finit (pas de « rally »)").is_false()
	assert_int(e.rallies).is_equal(1)
	assert_bool(e.team.all(func(d: Dino) -> bool: return d.hp == d.max_hp())).override_failure_message("l'équipe ne s'est pas relevée soignée").is_true()
	assert_bool(e.can_call("sceau_desert")).override_failure_message("les Sceaux ne reviennent pas").is_true()
	assert_bool(e._caillou_used).override_failure_message("Caillou ne revient pas").is_false()
	assert_int(e.calm).override_failure_message("le calme s'est perdu").is_equal(calm)
	assert_bool(ev.any(func(x: Dictionary) -> bool: return String(x.get("text", "")).contains("Encore."))).is_true()


# ------------------------------------------------------------------ Isaure : Carène hésite

func test_carene_hesite_un_tour_les_autres_non() -> void:
	var team := _team(&"velociraptor", 47)
	var carene := Dino.create(&"archelon", 49, "Carène")
	var rules := ApexBattles.isaure_rules()
	rules["trainer"] = ApexBattles.ISAURE
	var e := ApexEngine.new(team, carene, rules)
	var hp := e.player().hp
	var ev := e.turn({"type": "move", "index": 0})
	assert_bool(ev.any(func(x: Dictionary) -> bool: return x["type"] == "move" and x["side"] == "foe")).override_failure_message("Carène agit dès le 1er tour").is_false()
	assert_bool(ev.any(func(x: Dictionary) -> bool: return String(x.get("text", "")).begins_with("Carène hésite"))).is_true()
	assert_int(e.player().hp).is_equal(hp)
	ev = e.turn({"type": "move", "index": 0})
	assert_bool(ev.any(func(x: Dictionary) -> bool: return x["type"] == "move" and x["side"] == "foe")).override_failure_message("Carène hésite deux fois").is_true()
	var hauban := ApexEngine.new(_team(&"velociraptor", 47), Dino.create(&"pteranodon", 47, "Hauban"), rules)
	ev = hauban.turn({"type": "move", "index": 0})
	assert_bool(ev.any(func(x: Dictionary) -> bool: return x["type"] == "move" and x["side"] == "foe")).override_failure_message("Hauban hésite aussi").is_true()


# ------------------------------------------------------------------ outils

## L'équipe type (comme tests/volcan/test_combat_volcan.gd) : départ L (Lien 5 : l'histoire l'y a monté), le 3e petit
## L-1, Nessie L-1, Bouée L-2, Ptéro L-2.
func _team(starter: StringName, lvl: int) -> Array[Dino]:
	const STOLEN := {&"velociraptor": &"parasaurolophus", &"ankylosaurus": &"velociraptor", &"parasaurolophus": &"ankylosaurus"}
	var team: Array[Dino] = []
	var s := Dino.create(starter, lvl, STARTERS[starter])
	s.bond = Dino.MAX_BOND
	team.append(s)
	team.append(Dino.create(STOLEN[starter], lvl - 1))
	team.append(Dino.create(&"plesiosaurus", lvl - 1, "Nessie"))
	team.append(Dino.create(&"baryonyx", lvl - 2, "Bouée"))
	team.append(Dino.create(&"pteranodon", lvl - 2, "Ptéro"))
	return team


func _souverain_battle(starter: StringName, lvl := 48) -> ApexEngine:
	var rules := ApexBattles.souverain_rules()
	rules["starter"] = starter
	return ApexEngine.new(_team(starter, lvl), ApexBattles.souverain(), rules)


func _index_of(d: Dino, move: StringName) -> int:
	for i in d.moves.size():
		if d.moves[i]["id"] == move:
			return i
	return 0
